import os
import system
import intsets
import json

import cligen

import catwalk
import fasta

var n_pos_buf: seq[int]
proc save_sample_refcomp(instance_name: string, sample_name: string, s: Sample) =
  if not existsDir(instance_name):
    createDir(instance_name)
  n_pos_buf.setLen(0)
  for x in s.n_positions:
    n_pos_buf.insert(x)
  writeFile(instance_name & "/" & sample_name, $(%*{ "N": n_pos_buf,
                                                     "A": s.diffsets[0],
                                                     "C": s.diffsets[1],
                                                     "G": s.diffsets[2],
                                                     "T": s.diffsets[3] }))

proc main(instance_name, reference_file, mask_file, sample_file: string) =
  let (_, ref_str) = parse_fasta_file(reference_file)
  let mask = new_Mask(mask_file, readFile(mask_file))
  let (_, sam_str) = parse_fasta_file(sample_file)

  let s = reference_compress(sam_str, ref_str, mask, 300000)
  save_sample_refcomp(instance_name, extractFilename(sample_file), s)

when isMainModule:
  dispatch(main)

  
