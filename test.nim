import logging
import os
import times
import tables

import cligen

import fasta
import catwalk

var
  logger = newConsoleLogger(fmtStr = "[$datetime] - $levelname: ")

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

#  # show stats
#  echo "file,status,quality,refdistance"
#  for samA in catwalk.samples.keys:
#    echo catwalk.samples[samA].filepath &
#      "," & $catwalk.samples[samA].status &
#      "," & $catwalk.samples[samA].quality &
#      "," & $catwalk.samples[samA].refdistance &
#      "," & $compressed_sequence_counts(catwalk.samples[samA].diffsets)
#
#  let time3 = cpuTime()
#  # construct snp difference matrix
#  var durations: seq[float]
#  var x = 0
#  var y = 0
#  for samA in catwalk.samples.keys:
#    var row: seq[int]
#    let time4 = cpuTime()
#    for samB in catwalk.samples.keys:
#      if y > x:
#        if catwalk.samples[samA].status == Ok and catwalk.samples[samB].status == Ok:
#          let d = snp_distance(catwalk, samB, samA)
#          row.add(d)
#      inc x
#    durations.add(1000 * (cpuTime() - time4))
#    #echo row
#    inc y
#    x = 0
#  echo "Completed comparisons in: " & $(cpuTime() - time3)
#  echo durations
#
#  for k in catwalk.samples.keys:
#    echo k & ": " & $catwalk.get_neighbours(k)

when isMainModule:
  dispatch(main)
