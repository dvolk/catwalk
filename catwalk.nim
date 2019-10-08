import os
import tables
import logging
import times
import sets

import cligen

import symdiff
import fasta

type
  Sequence = string

  CompressedSequence = seq[seq[int]]

  SampleStatus = enum
    Unknown
    InvalidLength
    InvalidQuality
    Ok

  Sample = tuple
    name: string
    filepath: string
    sequence: Sequence
    status: SampleStatus
    diffsets: CompressedSequence
    quality: int
    ref_distance: int

  CatWalk = tuple
    name: string
    reference: Sample
    samples: Table[string, Sample]
    neighbours: Table[string, seq[(string, int)]]

var
  logger = newConsoleLogger(fmtStr = "[$datetime] - $levelname: ")

#
# CompressedSequence
#

proc empty_compressed_sequence(cs: var CompressedSequence) =
  for i in 0..5: cs.add(@[])

proc compressed_sequence_counts(cs: CompressedSequence) : seq[int] =
  result = @[]
  for i in 0..cs.high: result.add(len(cs[i]))

proc count_diff(cs1: CompressedSequence, cs2: CompressedSequence) : int =
  var
    diff = 0
  for i in 0..cs1.high:
    diff = diff + count_sym_diff(cs1[i], cs2[i])
  return diff

proc ref_snp_distance(cs: CompressedSequence) : int =
  result = 0
  for i in 0..cs.high:
    result += len(cs[i])

proc add_position(cs: var CompressedSequence, base: char, position: int) {.inline.} =
  let index = case base:
    of 'A': 0
    of 'C': 1
    of 'G': 2
    of 'T': 3
    of 'N': 4
    else: 5
  cs[index].add(position)

#
# Sample
#

proc new_Sample(fasta_filepath: string, header: string, sequence: string) : Sample =
  var s: Sample
  s.name = header
  s.sequence = sequence
  s.filepath = fasta_filepath
  s.status = Unknown
  return s

proc reference_compress(sample: var Sample, reference: Sample) =
  if sample.sequence.len != reference.sequence.len:
    sample.status = InvalidLength
    return

  empty_compressed_sequence(sample.diffsets)

  for i in 0..reference.sequence.high:
    if sample.sequence[i] != reference.sequence[i]:
      if sample.sequence[i] != 'N' and sample.sequence[i] != '-' and
         reference.sequence[i] != 'N' and reference.sequence[i] != '-':
        sample.diffsets.add_position(sample.sequence[i], i)

  sample.sequence = ""
  sample.ref_distance = ref_snp_distance(sample.diffsets)
  sample.quality = (100 * ((reference.sequence.high - sample.ref_distance) / reference.sequence.high)).int

  if sample.quality < 80:
    sample.status = InvalidQuality
    empty_compressed_sequence(sample.diffsets)
  else:
    sample.status = Ok

#
# CatWalk
#

proc new_CatWalk(name: string, reference: Sample) : CatWalk =
  var c: CatWalk
  c.name = name
  c.reference = reference
  return c

proc snp_distance(c: CatWalk, sample1_name: string, sample2_name: string) : int =
  let
    sample1 = c.samples[sample1_name]
    sample2 = c.samples[sample2_name]
  return count_diff(sample1.diffsets, sample2.diffsets)

proc process_neighbours(c: var CatWalk, sample1: Sample) =
  for k in c.samples.keys:
    let
      sample2 = c.samples[k]
      d = count_diff(sample1.diffsets, sample2.diffsets)
    if d <= 50:
      if not c.neighbours.contains(sample1.name):
        c.neighbours[sample1.name] = @[]
      if not c.neighbours.contains(sample2.name):
        c.neighbours[sample2.name] = @[]
      c.neighbours[sample1.name].add((sample2.name, d))
      c.neighbours[sample2.name].add((sample1.name, d))

proc get_neighbours(c: CatWalk, sample_name: string, distance: int = 50) : seq[(string, int)] =
  result = @[]
  if not c.neighbours.contains(sample_name):
    return result
  for (neighbour_name, neighbour_distance) in c.neighbours[sample_name]:
    if distance > neighbour_distance:
      result.add((neighbour_name, neighbour_distance))

proc add_sample(c: var CatWalk, sample: var Sample) =
  sample.reference_compress(c.reference)
  c.process_neighbours(sample)
  c.samples[sample.name] = sample

proc add_samples(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    c.add_sample(sample)

#
# Main
#

proc main(reference_filepath = "references/R00000039.fa", samples_dir = "fastas1") =
  proc log_mem_used =
    logger.log(lvlDebug, "Memory used: " & $(getOccupiedMem() / 1_000_000))

  # create catwalk
  var
    (ref_header, ref_seq) = parse_fasta_file(reference_filepath)
    catwalk = new_CatWalk("test", new_Sample(reference_filepath, ref_header, ref_seq))

  # load samples
  let time1 = cpuTime()
  var
    samples: seq[Sample]
  for kind, path in walkDir(samples_dir):
    log_mem_used()
    logger.log(lvlInfo, "adding " & path)
    let
      (sample_header, sample_seq) = parse_fasta_file(path)
    samples.add(new_Sample(path, sample_header, sample_seq))
  echo "Parsed fasta files in: " & $(cpuTime() - time1)

  # add samples to catwalk
  let time2 = cpuTime()
  catwalk.add_samples(samples)
  samples = @[]
  log_mem_used()
  echo "Added samples to catwalk in: " & $(cpuTime() - time2)

  # show stats
  echo "file,status,quality,refdistance"
  for samA in catwalk.samples.keys:
    echo catwalk.samples[samA].filepath &
      "," & $catwalk.samples[samA].status &
      "," & $catwalk.samples[samA].quality &
      "," & $catwalk.samples[samA].refdistance &
      "," & $compressed_sequence_counts(catwalk.samples[samA].diffsets)

  let time3 = cpuTime()
  # construct snp difference matrix
  var durations: seq[float]
  var x = 0
  var y = 0
  for samA in catwalk.samples.keys:
    var row: seq[int]
    let time4 = cpuTime()
    for samB in catwalk.samples.keys:
      if y > x:
        if catwalk.samples[samA].status == Ok and catwalk.samples[samB].status == Ok:
          let d = snp_distance(catwalk, samB, samA)
          row.add(d)
      inc x
    durations.add(1000 * (cpuTime() - time4))
    #echo row
    inc y
    x = 0
  echo "Completed comparisons in: " & $(cpuTime() - time3)
  echo durations

  for k in catwalk.samples.keys:
    echo k & ": " & $catwalk.get_neighbours(k)

when isMainModule:
  dispatch(main)
