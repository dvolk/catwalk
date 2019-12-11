import tables
import intsets
import strutils
import times
import json
import algorithm

import symdiff

type
  Sequence = string

  CompressedSequence* = array[4, seq[int]]

  SampleStatus* = enum
    Unknown
    InvalidLength
    TooManyNs
    Ok

  Sample* = tuple
    status: SampleStatus
    diffsets: CompressedSequence
    n_positions: IntSet

  Mask* = tuple
    name: string
    positions: IntSet

  Settings* = tuple
    max_distance: int
    max_n_positions: int

  CatWalk* = tuple
    settings: Settings
    name: string
    reference_name: string
    reference_sequence: string
    mask: Mask
    active_samples: Table[int, Sample]
    all_sample_indexes: Table[string, int]
    all_sample_names: Table[int, string]
    neighbours: Table[int, seq[array[2, int]]]
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

proc new_Sample*(): Sample =
  empty_compressed_sequence(result.diffsets)
  result.n_positions = initIntSet()
  result.status = Unknown

proc is_n_position(c: char): bool {.inline.} =
  c != 'A' and c != 'C' and c != 'G' and c != 'T'

proc reference_compress(sample_sequence: string, ref_sequence: string, mask: Mask, max_n_positions: int): Sample =
  var
    sample = new_Sample()

  if sample_sequence.len != ref_sequence.len:
    sample.status = InvalidLength
    return

  for i in 0..ref_sequence.high:
    if sample_sequence[i] != ref_sequence[i] and not mask.positions.contains(i):
      if is_n_position(sample_sequence[i]):
        sample.n_positions.incl(i)
      else:
        sample.diffsets.add_position(sample_sequence[i], i)

  if sample.n_positions.len > max_n_positions:
    sample.status = TooManyNs
    empty_compressed_sequence(sample.diffsets)
    sample.n_positions = initIntSet()
  else:
    sample.status = Ok
  return sample

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

proc new_CatWalk*(name: string, reference_name: string, reference_sequence: string, mask: Mask) : CatWalk =
  result.name = name
  result.reference_name = reference_name
  result.reference_sequence = reference_sequence
  result.mask = mask
  result.settings.max_distance = 20
  result.settings.max_n_positions = 130000

proc process_neighbours(c: var CatWalk, sample1: Sample, sample1_index: int): seq[(int, int)] =
  if sample1.status != Ok:
    return
  for sample2_index in c.active_samples.keys:
    if sample2_index == sample1_index:
      continue
    let
      sample2 = c.active_samples[sample2_index]
    if sample2.status != Ok:
      continue
    let
      d = count_diff2(sample1.diffsets, sample2.diffsets, sample1.n_positions, sample2.n_positions, c.settings.max_distance)
    if d <= c.settings.max_distance:
      result.add((sample2_index, d))

proc add_sample*(c: var CatWalk, name: string, sequence: string, keep: bool) =
  var
    sample = reference_compress(sequence, c.reference_sequence, c.mask, c.settings.max_n_positions)

  let sample_index = len(c.all_sample_indexes)
  c.all_sample_indexes[name] = sample_index
  c.all_sample_names[sample_index] = name

  if keep:
    c.active_samples[sample_index] = sample

proc add_sample_from_refcomp*(c: var CatWalk, name: string, refcomp_json: string, keep: bool) =
  let
    tbl = parseJson(refcomp_json)
  var
    sample = new_Sample()

  sample.status = Ok
  for x in tbl["N"]: sample.n_positions.incl(x.getInt())
  for x in tbl["A"]: sample.diffsets[0].add(x.getInt())
  for x in tbl["C"]: sample.diffsets[1].add(x.getInt())
  for x in tbl["G"]: sample.diffsets[2].add(x.getInt())
  for x in tbl["T"]: sample.diffsets[3].add(x.getInt())
  sample.diffsets[0].sort()
  sample.diffsets[1].sort()
  sample.diffsets[2].sort()
  sample.diffsets[3].sort()

  let sample_index = len(c.all_sample_indexes)
  c.all_sample_indexes[name] = sample_index
  c.all_sample_names[sample_index] = name

  if keep:
    c.active_samples[sample_index] = sample

proc get_neighbours*(c: var CatWalk, sample_name: string) : seq[(string, int)] =
  let
    sample_index = c.all_sample_indexes[sample_name]
    sample = c.active_samples[sample_index]
    neighbours = c.process_neighbours(sample, sample_index)
  result = @[]
  for (neighbour_index, distance) in neighbours:
    result.add((c.all_sample_names[neighbour_index], distance))

#
# test
#
when isMainModule:
  let
    mask = new_Mask("test", "0")
    rs = "AAACGT"
  var
    c = new_CatWalk("testcw", "testref", rs, mask)

  c.settings.max_distance = 50
  c.settings.max_n_positions = 2

  c.add_sample("s0", "AAACGT", true)
  c.add_sample("s1", "AAACGT", true)
  c.add_sample("s2", "AAACGC", true)

  echo c.active_samples
  echo c.all_sample_indexes
  echo c.all_sample_names
  echo c.neighbours
  # assert $c.neighbours == """{1: @[(0, 4), (0, 4), (3, 2), (4, 4), (3, 2), (4, 4)], 3: @[(0, 4), (1, 2), (0, 4), (1, 2), (4, 3), (4, 3)], 4: @[(0, 1), (1, 4), (3, 3), (0, 1), (1, 4), (3, 3)], 0: @[(1, 4), (3, 4), (4, 1), (1, 4), (3, 4), (4, 1)]}"""

  echo "Tests passed."
