import os
import memfiles
import tables
import intsets
import logging
import cligen

type
  Sequence = string

  CompressedSequence = Table[char, IntSet]

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

var
  logger = newConsoleLogger(fmtStr = "[$datetime] - $levelname: ")
  pf_buf: TaintedString = newStringOfCap(1000)

proc parse_fasta(mm: var MemFile): (string, string) =
  var
    sequence = newStringOfCap(4_500_000)
    is_first = true # surely there's a better way of doing this
    header = ""
    i = 0
  for line in lines(mm, pf_buf):
    if is_first:
      is_first = false
      header = line
    else:
      i = 0
      for c in line:
        sequence.add(c)
        inc i
  return (header, sequence)

proc ref_snp_distance(s: Sample) : int =
  result = 0
  for k in s.diffsets.keys:
    result += len(s.diffsets[k])

proc empty_compressed_sequence(cs: var CompressedSequence) =
  cs['A'] = initIntSet()
  cs['C'] = initIntSet()
  cs['G'] = initIntSet()
  cs['T'] = initIntSet()
  cs['N'] = initIntSet()
  cs['-'] = initIntSet()

proc compressed_sequence_counts(cs: CompressedSequence) : seq[int] =
  result = @[]
  for k in @['A', 'C', 'G', 'T', 'N', '-']:
    result.add(len(cs[k]))
  
proc reference_compress(sample: var Sample, reference: Sample) =
  if sample.sequence.len != reference.sequence.len:
    sample.status = InvalidLength
    return

  empty_compressed_sequence(sample.diffsets)

  for i in 0..reference.sequence.high:
    if sample.sequence[i] != reference.sequence[i]:
      if sample.sequence[i] != 'N' and sample.sequence[i] != '-' and
         reference.sequence[i] != 'N' and reference.sequence[i] != '-':
        sample.diff_sets[sample.sequence[i]].incl(i)

  sample.sequence = ""
  sample.ref_distance = ref_snp_distance(sample)
  sample.quality = (100 * ((reference.sequence.high - sample.ref_distance) / reference.sequence.high)).int

  if sample.quality < 80:
    sample.status = InvalidQuality
    empty_compressed_sequence(sample.diffsets)
  else:
    sample.status = Ok

proc sym_diff(a: IntSet, b: IntSet): IntSet =
  var
    u: IntSet 
    i: Intset 
  u.assign(a.union(b))
  i.assign(a.intersection(b))
  result.assign(u.difference(i))
    
proc diff(sample1: Sample, sample2: Sample) : IntSet =
  var
    diff = initIntSet()
  for k in sample1.diffsets.keys:
    diff.assign(diff.union(sample1.diffsets[k].sym_diff(sample2.diffsets[k])))
  return diff

proc new_Sample(fasta_filepath: string, header: string, sequence: string) : Sample =
  var s: Sample
  s.name = header
  s.sequence = sequence
  s.filepath = fasta_filepath
  s.status = Unknown
  return s

proc new_CatWalk(name: string, reference: Sample) : CatWalk =
  var c: CatWalk
  c.name = name
  c.reference = reference
  return c

proc add_sample(c: var CatWalk, sample: var Sample) =
  #logger.log(lvlInfo, "compressing " & sample.name)
  sample.reference_compress(c.reference)
  #logger.log(lvlInfo, "done compressing " & sample.name)
  c.samples[sample.name] = sample

proc add_samples(c: var CatWalk, samples: var seq[Sample]) =
  for sample in samples.mitems():
    c.add_sample(sample)

proc diff_sample(c: CatWalk, sample1_name: string, sample2_name: string) : IntSet =
  let
    sample1 = c.samples[sample1_name]
    sample2 = c.samples[sample2_name]
  return sample1.diff(sample2)

proc snp_distance(c: CatWalk, sample1_name: string, sample2_name: string) : int =
  return len(diff_sample(c, sample1_name, sample2_name))

proc log_mem_used =
  logger.log(lvlDebug, "Memory used: " & $(getOccupiedMem() / 1_000_000))

proc main(reference_filepath = "references/R00000039.fa", samples_dir = "fastas1") =
  # create catwalk
  var
    ref_file = memfiles.open(reference_filepath)
    (ref_header, ref_seq) = parse_fasta(ref_file)
    catwalk = new_CatWalk("test", new_Sample(reference_filepath, ref_header, ref_seq))

  # load samples
  var
    samples: seq[Sample]
  for kind, path in walkDir(samples_dir):
    log_mem_used()
    logger.log(lvlInfo, "adding " & path)
    var
      mm = memfiles.open(path)
    let
      (sample_header, sample_seq) = parse_fasta(mm)
    mm.close()
    samples.add(new_Sample(path, sample_header, sample_seq))

  # insert samples to catwalk
  catwalk.add_samples(samples)
  samples = @[]
  log_mem_used()

  # show stats
  echo "file,status,quality,refdistance"
  for samA in catwalk.samples.keys:
    echo catwalk.samples[samA].filepath &
      "," & $catwalk.samples[samA].status &
      "," & $catwalk.samples[samA].quality &
      "," & $catwalk.samples[samA].refdistance &
      "," & $compressed_sequence_counts(catwalk.samples[samA].diffsets)

  #for samA in catwalk.samples.keys:
  #  for samB in catwalk.samples.keys:
  #    if catwalk.samples[samA].status == Ok and catwalk.samples[samB].status == Ok:
  #      let d = snp_distance(catwalk, samB, samA)
  #      echo d
  #  echo '\n'

when isMainModule:
  dispatch(main)
