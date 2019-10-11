import tables
import sequtils
import intsets
import sets
import algorithm
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
    filepath: string
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
    samples: Table[string, Sample]
    neighbours: Table[(string, string), int]
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
    else:   3
  cs[index].add(position)

#
# Sample
#

proc new_Sample*(fasta_filepath: string, header: string, sequence: string) : Sample =
  var s: Sample
  s.name = header
  s.sequence = sequence
  s.filepath = fasta_filepath
  s.n_positions = initIntSet()
  s.status = Unknown
  return s

proc is_n_position(c: char): bool {.inline.} =
  c == 'N' or c == '-'

proc reference_compress(sample: var Sample, reference: Sample, mask: Mask, max_n_positions: int, min_quality: int) =
  if sample.sequence.len != reference.sequence.len:
    sample.status = InvalidLength
    return

  empty_compressed_sequence(sample.diffsets)

  for i in 0..reference.sequence.high:
    if sample.sequence[i] != reference.sequence[i]:
      if not is_n_position(sample.sequence[i]) and not is_n_position(reference.sequence[i]):
        if not mask.positions.contains(i):
          sample.diffsets.add_position(sample.sequence[i], i)
    if is_n_position(sample.sequence[i]):
      sample.n_positions.incl(i)

  sample.n_positions.assign(sample.n_positions.difference(mask.positions))
  sample.sequence = ""
  sample.ref_distance = ref_snp_distance(sample.diffsets)

  if sample.n_positions.len > 0:
    let
      n = sample.n_positions.len.float
      r = reference.sequence.high.float
    sample.quality = (100 * (r - n) / r).int
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
  for line in mask_str.split('\n'):
    if line != "" and line != " ":
      try:
        result.positions.incl(parseInt(line))
      except:
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
  c.settings.max_n_positions = 1000000
  c.settings.min_quality = 80
  return c

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
      d = count_diff2(sample1.diffsets, sample2.diffsets, sample1.n_positions, sample2.n_positions, c.settings.max_distance)
    if d <= c.settings.max_distance:
      c.neighbours[(k, sample1.name)] = d
      c.neighbours[(sample1.name, k)] = d

proc add_samples*(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    sample.reference_compress(c.reference, c.mask, c.settings.max_n_positions, c.settings.min_quality)
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
    reference = new_Sample("re", "re", "AAACGT")
    mask =      new_Mask("test", "0")
    s1 =        new_Sample("s1", "s1", "AAACGG")
    s2 =        new_Sample("s2", "s2", "-ATTTT")
    s3 =        new_Sample("s3", "s3", "CATTCC")
    s4 =        new_Sample("s4", "s4", "NAACGC")
    s5 =        new_Sample("s5", "s5", "NNNNGC")
  var
    c = new_CatWalk("test", reference, mask)
    s: seq[Sample]

  c.settings.max_distance = 20
  c.settings.max_n_positions = 2

  s = @[s1, s2, s5]
  c.add_samples(s)
  s = @[s3]
  c.add_samples(s)
  s = @[s4]
  c.add_samples(s)

  echo reference
  for s in c.samples.values:
    echo s
  echo c.neighbours

  assert $c.neighbours == "{(\"s4\", \"s3\"): 3, (\"s4\", \"s1\"): 1, (\"s3\", \"s2\"): 3, (\"s3\", \"s4\"): 3, (\"s3\", \"s1\"): 4, (\"s1\", \"s4\"): 1, (\"s4\", \"s2\"): 4, (\"s2\", \"s1\"): 4, (\"s1\", \"s3\"): 4, (\"s1\", \"s2\"): 4, (\"s2\", \"s3\"): 3, (\"s2\", \"s4\"): 4}"
