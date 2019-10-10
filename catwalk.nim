import tables
import sequtils
import intsets
import sets
import algorithm
import times

import symdiff

type
  Sequence = string

  CompressedSequence = seq[seq[int]]

  SampleStatus* = enum
    Unknown
    InvalidLength
    InvalidQuality
    Ok

  Sample* = tuple
    name: string
    filepath: string
    sequence: Sequence
    status: SampleStatus
    diffsets: CompressedSequence
    quality: int
    ref_distance: int

  CatWalk* = tuple
    name: string
    reference: Sample
    samples: Table[string, Sample]
    neighbours: Table[(string, string), int]
    process_times: seq[float]
    max_distance: int

#
# CompressedSequence
#

proc empty_compressed_sequence(cs: var CompressedSequence) =
  cs.setLen(6)
  for i in 0..5: cs[i] = @[]

proc compressed_sequence_counts*(cs: CompressedSequence) : seq[int] =
  result = @[]
  for i in 0..5: result.add(len(cs[i]))

proc count_diff2(cs1: CompressedSequence, cs2: CompressedSequence, max_distance: int) : int =
  return sum_sym_diff1(cs1[0], cs2[0],
                       cs1[1], cs2[1],
                       cs1[2], cs2[2],
                       cs1[3], cs2[3],
                       cs1[4], cs2[4],
                       cs1[5], cs2[5],
                       max_distance)

proc ref_snp_distance(cs: CompressedSequence) : int =
  result = 0
  for i in 0..5:
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

proc new_Sample*(fasta_filepath: string, header: string, sequence: string) : Sample =
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

proc new_CatWalk*(name: string, reference: Sample) : CatWalk =
  var c: CatWalk
  c.name = name
  c.reference = reference
  c.max_distance = 20
  return c

proc snp_distance(c: CatWalk, sample1_name: string, sample2_name: string) : int =
  let
    sample1 = c.samples[sample1_name]
    sample2 = c.samples[sample2_name]
  return count_diff2(sample1.diffsets, sample2.diffsets, 10_000_000)

proc process_neighbours(c: var CatWalk, sample1: Sample) =
  if sample1.status != Ok:
    return
  for k in c.samples.keys:
    if k == sample1.name:
      continue
    if c.neighbours.contains((sample1.name, k)) or c.neighbours.contains((k, sample1.name)):
      continue
    if c.samples[k].status != Ok:
      continue
    let
      sample2 = c.samples[k]
      d = count_diff2(sample1.diffsets, sample2.diffsets, c.max_distance)
    if d <= c.max_distance:
      c.neighbours[(k, sample1.name)] = d
      c.neighbours[(sample1.name, k)] = d

proc add_samples*(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    sample.reference_compress(c.reference)
    c.samples[sample.name] = sample
  for sample in samples.mitems():
    let time1 = cpuTime()
    c.process_neighbours(sample)
    c.process_times.add(cpuTime() - time1)

proc get_neighbours*(c: CatWalk, sample_name: string, distance: int = 50) : seq[(string, int)] =
  result = @[]
  for (s1, s2) in c.neighbours.keys:
    if s1 == sample_name:
      result.add((s2, c.neighbours[(s1, s2)]))

#
# test
#
when isMainModule:
  let
    re = new_Sample("re", "re", "AAACGT")
    s1 = new_Sample("s1", "s1", "AAACGG")
    s2 = new_Sample("s2", "s2", "AATTTT")
    s3 = new_Sample("s3", "s3", "AATTCC")
    s4 = new_Sample("s4", "s4", "AAACGC")
  var
    c = new_CatWalk("test", re)
    s: seq[Sample]

  s = @[s1]
  c.add_samples(s)
  s = @[s2]
  c.add_samples(s)
  s = @[s3]
  c.add_samples(s)
  s = @[s4]
  c.add_samples(s)

  assert $c.neighbours == "{(\"s4\", \"s1\"): 1, (\"s1\", \"s4\"): 1}"

  echo c.samples
  echo c.neighbours
  
