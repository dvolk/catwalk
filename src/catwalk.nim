import tables
import intsets
import strutils
import times

import symdiff

type
  Sequence = string

  CompressedSequence = array[4, seq[int]]

  SampleStatus* = enum
    Unknown
    InvalidLength
    InvalidQuality
    TooManyNs
    Ok

  Sample* = tuple
    name: string
    sequence: Sequence
    status: SampleStatus
    diffsets: CompressedSequence
    n_positions: IntSet
    ref_distance: int
    quality: int

  Mask* = tuple
    name: string
    positions: IntSet

  Settings* = tuple
    max_distance: int
    max_n_positions: int
    min_quality: int

  CatWalk* = tuple
    settings: Settings
    name: string
    reference: Sample
    mask: Mask
    samples: seq[Sample]
    sample_indexes: Table[string, int]
    neighbours: Table[int, seq[(int, int)]]
    process_times: seq[float]

#
# CompressedSequence
#

proc empty_compressed_sequence(cs: var CompressedSequence) =
  for i in 0..3: cs[i] = @[]

proc compressed_sequence_counts*(cs: CompressedSequence) : seq[int] =
  result = @[]
  for i in 0..3: result.add(len(cs[i]))

proc count_diff2(cs1: CompressedSequence, cs2: CompressedSequence, sample1_n_positions: IntSet, sample2_n_positions: IntSet, max_distance: int) : int =
  return sum_sym_diff1(cs1[0], cs2[0],
                       cs1[1], cs2[1],
                       cs1[2], cs2[2],
                       cs1[3], cs2[3],
                       sample1_n_positions, sample2_n_positions,
                       max_distance)

proc ref_snp_distance(cs: CompressedSequence) : int =
  result = 0
  for i in 0..3:
    result += len(cs[i])

proc add_position(cs: var CompressedSequence, base: char, position: int) {.inline.} =
  let index = case base:
    of 'A': 0
    of 'C': 1
    of 'G': 2
    of 'T': 3
    else: 4
  cs[index].add(position)

#
# Sample
#

proc new_Sample*(fasta_filepath: string, sequence: string) : Sample =
  var s: Sample
  s.name = fasta_filepath
  s.sequence = sequence
  s.n_positions = initIntSet()
  s.status = Unknown
  return s

proc is_n_position(c: char): bool {.inline.} =
  c != 'A' and c != 'C' and c != 'G' and c != 'T'

proc reference_compress(sample: var Sample, reference: Sample, mask: Mask, max_n_positions: int, min_quality: int) =
  if sample.sequence.len != reference.sequence.len:
    sample.status = InvalidLength
    return

  empty_compressed_sequence(sample.diffsets)

  for i in 0..reference.sequence.high:
    if sample.sequence[i] != reference.sequence[i] and not mask.positions.contains(i):
      if is_n_position(sample.sequence[i]):
        sample.n_positions.incl(i)
      else:
        sample.diffsets.add_position(sample.sequence[i], i)

  sample.sequence = ""
  sample.ref_distance = ref_snp_distance(sample.diffsets)

  if sample.n_positions.len > 0:
    let
      n = sample.n_positions.len.float
      r = reference.sequence.high.float
    sample.quality = (100 * ((r - n) / r)).int
  else:
    sample.quality = 100

  if sample.n_positions.len > max_n_positions:
    sample.status = TooManyNs
    empty_compressed_sequence(sample.diffsets)
    sample.n_positions = initIntSet()
  else:
    sample.status = Ok

#
# Mask
#

proc new_Mask*(mask_name: string, mask_str: string): Mask =
  result.name = mask_name
  for line in mask_str.splitLines():
    try:
      result.positions.incl(parseInt(line))
    except ValueError:
      echo "Not an integer: '" & line & "'"

#
# CatWalk
#

proc new_CatWalk*(name: string, reference: Sample, mask: Mask) : CatWalk =
  var c: CatWalk
  c.name = name
  c.reference = reference
  c.mask = mask
  c.settings.max_distance = 20
  c.settings.max_n_positions = 130000
  c.settings.min_quality = 80
  return c

proc process_neighbours(c: var CatWalk, sample1_index: int) =
  let
    sample1 = c.samples[sample1_index]
  if sample1.status != Ok:
    return
  for sample2_index in 0..c.samples.high:
    if sample2_index == sample1_index:
      continue
    let
      sample2 = c.samples[sample2_index]
    if sample2.status != Ok:
      continue
    #if c.neighbours.contains((sample1.name, k)) or c.neighbours.contains((k, sample1.name)):
    #  continue
    let
      d = count_diff2(sample1.diffsets, sample2.diffsets, sample1.n_positions, sample2.n_positions, c.settings.max_distance)
    if d <= c.settings.max_distance:
      if not c.neighbours.contains(sample1_index):
        c.neighbours[sample1_index] = newSeqOfCap[(int, int)](16)
      c.neighbours[sample1_index].add((sample2_index, d))
      if not c.neighbours.contains(sample2_index):
        c.neighbours[sample2_index] = newSeqOfCap[(int, int)](16)
      c.neighbours[sample2_index].add((sample1_index, d))

proc add_samples*(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    sample.reference_compress(c.reference, c.mask, c.settings.max_n_positions, c.settings.min_quality)
    c.samples.add(sample)
    c.sample_indexes[sample.name] = len(c.samples) - 1

  for sample in samples.mitems():
    let time1 = cpuTime()
    c.process_neighbours(c.sample_indexes[sample.name])
    c.process_times.add(cpuTime() - time1)

proc get_neighbours*(c: CatWalk, sample_name: string, distance: int = 20) : seq[(string, int)] =
  result = @[]
  let sample_index = c.sample_indexes[sample_name]
  if sample_index in c.neighbours:
    for (neighbour_index, distance) in c.neighbours[sample_index]:
      result.add((c.samples[neighbour_index].name, distance))

#
# test
#
when isMainModule:
  let
    reference = new_Sample("re", "AAACGT")
    mask =      new_Mask("test", "0")
    s1 =        new_Sample("s1", "AAACGG")
    s2 =        new_Sample("s2", "-ATTTT")
    s3 =        new_Sample("s3", "CATTCC")
    s4 =        new_Sample("s4", "NAACGC")
    s5 =        new_Sample("s5", "NNNNGC")
  var
    c = new_CatWalk("test", reference, mask)
    s: seq[Sample]

  c.settings.max_distance = 20
  c.settings.max_n_positions = 2

  s = @[s1, s2, s5, s3, s4]
  c.add_samples(s)

  assert $c.neighbours == """{1: @[(0, 4), (0, 4), (3, 2), (4, 4), (3, 2), (4, 4)], 3: @[(0, 4), (1, 2), (0, 4), (1, 2), (4, 3), (4, 3)], 4: @[(0, 1), (1, 4), (3, 3), (0, 1), (1, 4), (3, 3)], 0: @[(1, 4), (3, 4), (4, 1), (1, 4), (3, 4), (4, 1)]}"""

  echo "Tests passed."
