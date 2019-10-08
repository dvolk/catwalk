import tables
import sequtils
import intsets

import cligen

import symdiff
import fasta

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
    neighbours: Table[string, seq[(string, int)]]

#
# CompressedSequence
#

proc empty_compressed_sequence(cs: var CompressedSequence) =
  for i in 0..5: cs.add(@[])

proc compressed_sequence_counts*(cs: CompressedSequence) : seq[int] =
  result = @[]
  for i in 0..5: result.add(len(cs[i]))

proc count_diff(cs1: CompressedSequence, cs2: CompressedSequence) : int =
  var
    diff = 0
  for i in 0..5:
    diff = diff + count_sym_diff(cs1[i], cs2[i])
  return diff

  
proc count_diff2(cs1: CompressedSequence, cs2: CompressedSequence) : int =
  var buf = initIntSet()
  sym_diff(cs1[0], cs2[0], buf)
  sym_diff(cs1[1], cs2[1], buf)
  sym_diff(cs1[2], cs2[2], buf)
  sym_diff(cs1[3], cs2[3], buf)
  sym_diff(cs1[4], cs2[4], buf)
  sym_diff(cs1[5], cs2[5], buf)
  return len(buf)

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
  return c

proc snp_distance*(c: CatWalk, sample1_name: string, sample2_name: string) : int =
  let
    sample1 = c.samples[sample1_name]
    sample2 = c.samples[sample2_name]
  return count_diff2(sample1.diffsets, sample2.diffsets)

proc process_neighbours(c: var CatWalk, sample1: Sample) =
  for k in c.samples.keys:
    let
      sample2 = c.samples[k]
      d = count_diff2(sample1.diffsets, sample2.diffsets)
    if d <= 50:
      if not c.neighbours.contains(sample1.name):
        c.neighbours[sample1.name] = @[]
      if not c.neighbours.contains(sample2.name):
        c.neighbours[sample2.name] = @[]
      c.neighbours[sample1.name].add((sample2.name, d))
      c.neighbours[sample2.name].add((sample1.name, d))

proc add_sample*(c: var CatWalk, sample: var Sample) =
  sample.reference_compress(c.reference)
  c.process_neighbours(sample)
  c.samples[sample.name] = sample

proc add_samples*(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    c.add_sample(sample)

proc get_neighbours*(c: CatWalk, sample_name: string, distance: int = 50) : seq[(string, int)] =
  result = @[]
  if not c.neighbours.contains(sample_name):
    return result
  for (neighbour_name, neighbour_distance) in c.neighbours[sample_name]:
    if distance > neighbour_distance:
      result.add((neighbour_name, neighbour_distance))


