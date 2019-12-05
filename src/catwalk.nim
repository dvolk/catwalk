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

  Sample* = tuple
    diffsets: CompressedSequence
    n_positions: IntSet

  CatWalk* = tuple
    # user parameters -
    name: string
    reference_name: string
    reference_sequence: string
    mask_name: string
    mask_positions: IntSet
    # sample storage -
    active_samples: Table[int, Sample]
    all_sample_indexes: Table[string, int]
    all_sample_names: Table[int, string]

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

proc is_n_position(c: char): bool {.inline.} =
  c != 'A' and c != 'C' and c != 'G' and c != 'T'

proc reference_compress(sample_sequence: string, ref_sequence: string, mask_positions: IntSet): Sample =
  for i in 0..ref_sequence.high:
    if sample_sequence[i] != ref_sequence[i] and not mask_positions.contains(i):
      if is_n_position(sample_sequence[i]):
        result.n_positions.incl(i)
      else:
        result.diffsets.add_position(sample_sequence[i], i)

#
# Mask
#

proc load_mask*(mask_str: string): IntSet =
  for line in mask_str.splitLines():
    try:
      result.incl(parseInt(line))
    except ValueError:
      echo "Not an integer: '" & line & "'"

#
# CatWalk
#

proc new_CatWalk*(name: string, reference_name: string, reference_sequence: string, mask_name: string, mask_positions: IntSet) : CatWalk =
  result.name = name
  result.reference_name = reference_name
  result.reference_sequence = reference_sequence
  result.mask_name = mask_name
  result.mask_positions = mask_positions

proc process_neighbours(c: CatWalk, sample1: Sample, sample1_index: int, max_distance: int): seq[array[2, int]] =
  for sample2_index in c.active_samples.keys:
    if sample2_index == sample1_index:
      continue
    let
      sample2 = c.active_samples[sample2_index]
    let
      d = count_diff2(sample1.diffsets, sample2.diffsets, sample1.n_positions, sample2.n_positions, max_distance)
    if d <= max_distance:
      result.add([sample2_index, d])

proc add_sample*(c: var CatWalk, name: string, sequence: string) =
  var
    sample = reference_compress(sequence, c.reference_sequence, c.mask_positions)

  let sample_index = len(c.all_sample_indexes)
  c.all_sample_indexes[name] = sample_index
  c.all_sample_names[sample_index] = name
  c.active_samples[sample_index] = sample

proc add_sample_from_refcomp*(c: var CatWalk, name: string, refcomp_json: string) =
  let
    tbl = parseJson(refcomp_json)
  var
    sample = new_Sample()

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
  c.active_samples[sample_index] = sample

proc get_neighbours*(c: CatWalk, sample_name: string, max_distance: int) : seq[(string, int)] =
  let
    sample_index = c.all_sample_indexes[sample_name]
    sample = c.active_samples[sample_index]
    neighbours = c.process_neighbours(sample, sample_index, max_distance)

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

  c.add_sample("s0", "AAACGT", true)
  c.add_sample("s1", "AAACGT", true)
  c.add_sample("s2", "AAACGC", true)

  echo c.active_samples
  echo c.all_sample_indexes
  echo c.all_sample_names
  echo c.neighbours
  # assert $c.neighbours == """{1: @[(0, 4), (0, 4), (3, 2), (4, 4), (3, 2), (4, 4)], 3: @[(0, 4), (1, 2), (0, 4), (1, 2), (4, 3), (4, 3)], 4: @[(0, 1), (1, 4), (3, 3), (0, 1), (1, 4), (3, 3)], 0: @[(1, 4), (3, 4), (4, 1), (1, 4), (3, 4), (4, 1)]}"""

  echo "Tests passed."
