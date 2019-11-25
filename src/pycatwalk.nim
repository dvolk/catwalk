import times
import json
import tables
import sequtils
import intsets

import nimpy

import catwalk

var c: CatWalk

let
  log_filepath = "/tmp/catwalk-" & $epochTime().int & "_log.txt"
  log_handle = open(log_filepath, fmWrite)

proc init(name: string,
          reference_name: string,
          reference_sequence: string,
          mask_name: string,
          mask_str: string) {.exportpy.} =
  write(log_handle, $(%*{ "function": "init",
                          "time": $epochTime().int,
                          "name": name,
                          "reference_name": reference_name,
                          "mask_name": mask_name,
                          "mask_str": mask_str}))
  flushFile(log_handle)
  c = new_CatWalk(name,
                  reference_name,
                  reference_sequence,
                  new_Mask(mask_name, mask_str))

proc add_sample(name: string, sequence: string, keep: bool = true) {.exportpy.} =
  write(log_handle, $(%*{ "function": "add_sample",
                              "time": $epochTime().int,
                              "name": name,
                              "sequence": sequence,
                              "keep": keep }))
  flushFile(log_handle)
  c.add_sample(name, sequence, keep)

# to avoid recreating it on every call of add_sample_from_refcomp
var tbl_buf: Table[string, seq[int]]
tbl_buf["A"] = newSeqOfCap[int](1024)
tbl_buf["C"] = newSeqOfCap[int](1024)
tbl_buf["G"] = newSeqOfCap[int](1024)
tbl_buf["T"] = newSeqOfCap[int](1024)
tbl_buf["N"] = newSeqOfCap[int](1024)

proc add_sample_from_refcomp(name: string, refcomp_json: string, keep: bool = true) {.exportpy.} =
  write(log_handle, $(%*{ "function": "add_sample_from_refcomp",
                              "time": $epochTime().int,
                              "sample_name": name,
                              "refcomp_json": refcomp_json,
                              "keep": keep }))
  flushFile(log_handle)
  c.add_sample_from_refcomp(name, refcomp_json, keep)

proc neighbours(sample_name: string): seq[(string, int)] {.exportpy.} =
  write(log_handle, $(%*{ "function": "neighbours",
                          "time": $epochTime().int,
                          "sample_name": sample_name }))
  flushFile(log_handle)
  return c.get_neighbours(sample_name)

proc status(): Table[string, string] {.exportpy.} =
  write(log_handle, $(%*{ "function": "status",
                          "time": $epochTime().int }))
  flushFile(log_handle)
  result["name"] = c.name
  result["reference_name"] = c.reference_name
  result["reference_sequence_length"] = $c.reference_sequence.len
  result["mask_name"] = c.mask.name
  result["mask_positions_length"] = $c.mask.positions.len
  result["max_distance"] = $c.settings.max_distance
  result["max_n_positions"] = $c.settings.max_n_positions
  result["total_mem"] = $getTotalMem()
  result["occupied_mem"] = $getOccupiedMem()
  result["n_samples"] = $c.active_samples.len
  result["n_neighbour_entries"] = $c.neighbours.len
