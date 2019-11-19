import json
import tables
import sequtils

import nimpy

import catwalk

var c: CatWalk

proc init(name: string,
          reference_name: string,
          reference_sequence: string,
          mask_name: string,
          mask_str: string) {.exportpy.} =
  c = new_CatWalk(name,
                  reference_name,
                  reference_sequence,
                  new_Mask(mask_name, mask_str))

proc add_sample(name: string, sequence: string, keep: bool = true) {.exportpy.} =
  c.add_sample(name, sequence, keep)

# to avoid recreating it on every call of add_sample_from_refcomp
var tbl_buf: Table[string, seq[int]]
tbl_buf["A"] = newSeqOfCap[int](1024)
tbl_buf["C"] = newSeqOfCap[int](1024)
tbl_buf["G"] = newSeqOfCap[int](1024)
tbl_buf["T"] = newSeqOfCap[int](1024)
tbl_buf["N"] = newSeqOfCap[int](1024)

proc add_sample_from_refcomp(name: string, refcomp_json: string, keep: bool = true) {.exportpy.} =
  let
    j = parseJson(refcomp_json)
  for c in ["A", "C", "G", "T", "N"]:
    tbl_buf[c].setLen(0)
    for x in j[c].getElems():
      tbl_buf[c].add(x.getInt())
  c.add_sample_from_refcomp(name, tbl_buf, keep)
  
proc neighbours(sample_name: string): seq[(string, int)] {.exportpy.} =
  return c.get_neighbours(sample_name)
