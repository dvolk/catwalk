import json
import jsony
import tables
import intsets
import strutils
import system
import os
import times
import strformat

import catwalk
import fasta

import jester
import cligen

var c: CatWalk

const compile_version = gorge "git describe --tags --always --dirty"
const compile_time = gorge "date --rfc-3339=seconds"


template check_param(p: string) =
  if not js.contains(p):
    resp "Missing parameter: " & p

proc add_sample_from_refcomp(name: string, refcomp_json: string, keep: bool = true) =
  c.add_sample_from_refcomp(name, refcomp_json, true)


proc add_samples_from_multifasta_singleline(filepath: string) =
  var
    i = 0
    time_now = cpuTime()
  for (header, sequence) in parse_multifasta_singleline_file(filepath):
    let my_header = header.replace("/", "_")[1.. header.high]
    c.add_sample(my_header, sequence, true)
    if i mod 1000 == 0:
      echo fmt"added {i} samples"
    i = i + 1
  echo fmt"added {i} samples in {cpuTime() - time_now} seconds."


var n_pos_buf: seq[int]
#
# write sample reference compressed sequence to a file instance_name/sample_name
#
proc save_sample_refcomp(name: string) =
  if not existsDir(c.name):
    createDir(c.name)
  let s = c.active_samples[c.all_sample_indexes[name]]
  n_pos_buf.setLen(0)
  for x in s.n_positions:
    n_pos_buf.insert(x)
  writeFile(c.name & "/" & name, $(%*{ "N": n_pos_buf,
                                       "A": s.diffsets[0],
                                       "C": s.diffsets[1],
                                       "G": s.diffsets[2],
                                       "T": s.diffsets[3] }))

proc route_info(): JsonNode =
  %*{ "name": c.name,
      "reference_name": c.reference_name,
      "reference_sequence_length": c.reference_sequence.len,
      "mask_name": c.mask.name,
      "mask_positions": c.mask.positions.len,
      "max_n_positions": c.max_n_positions,
      "total_mem": getTotalMem(),
      "occupied_mem": getOccupiedMem(),
      "n_samples": c.active_samples.len,
      "compile_version": compile_version,
      "compile_time": compile_time
    }

router app:
  get "/info":
    resp route_info()

  get "/debug":
    resp %*($c)

  get "/neighbours_times":
    resp %*(c.neighbours_times)

  get "/sample_counts/@name":
    resp %*(c.get_sample_counts(@"name"))

  get "/dump_sample/@name":
    resp %*(c.dump_sample(@"name"))

  post "/clear_neighbours_times":
    c.neighbours_times = initTable[string, float]()
    resp Http200, "ok"

  get "/list_samples":
    var
      ret = newJArray()
    for k in c.active_samples.keys:
      if c.active_samples[k].status != Removed:
        ret.add(%*c.all_sample_names[k])
    resp ret

  get "/list_ok_samples":
    var
      ret = newJArray()
    for k in c.active_samples.keys:
      if c.active_samples[k].status == Ok:
        ret.add(%*c.all_sample_names[k])
    resp ret

  get "/get_sample/@name":
    resp %*({ "name": @"name" })

  get "/get_samples/@from/@to":
    var
      i = parseInt(@"from")
      j = parseInt(@"to")
    if i < 0:
      i = 0
    if j >= len(c.active_samples):
      j = len(c.active_samples)
    var
      r = newJArray()
    for k in i..<j:
      r.add(%*c.all_sample_names[k])
    resp %*(r)

  get "/remove_sample/@name":
    c.remove_sample(@"name")
    resp Http200, "removed " & @"name"

  post "/add_sample":
    let
      js = parseJson(request.body)

    check_param "name"
    check_param "sequence"
    check_param "keep"

    let
      name = js["name"].getStr()
      sequence = js["sequence"].getStr()

    if c.all_sample_indexes.contains(name):
      let index = c.all_sample_indexes[name]
      let sample = c.active_samples[index]
      if sample.status == Ok:
        resp Http200, fmt"Sample {name} already exists (status: {sample.status})"

    c.add_sample(name, sequence, true)

    when defined(no_serialisation):
      echo "skipping saving instance file because this catwalk was built with -d:no_serialisation"
    when not defined(no_serialisation):
      save_sample_refcomp(name)

    #for i in 1..9:
    #  var sq: string
    #  deepCopy sq, sequence
    #  c.add_sample(name & "-" & $i, sq, true)

    resp Http201, fmt"Added {name}"

  post "/add_sample_from_refcomp":
    let
      js = parseJson(request.body)
      name = js["name"].getStr()
      refcomp = js["refcomp"].getStr()

    if c.all_sample_indexes.contains(name):
      let index = c.all_sample_indexes[name]
      let sample = c.active_samples[index]
      if sample.status == Ok:
        resp Http200, fmt"Sample {name} already exists (status: {sample.status})"

    add_sample_from_refcomp(name, refcomp, true)
    resp Http201, "Added " & name

  # mfsl - multifasta singleline
  # (sequence data on a single line, no line breaks)
  post "/add_samples_from_mfsl":
    let js = request.body.fromJson(Table[string, string])
    let filepath = js["filepath"]
    add_samples_from_multifasta_singleline(filepath)
    resp Http201, "OK"

  get "/neighbours/@name/@distance":
    if not c.all_sample_indexes.contains(@"name"):
      resp Http404, "Sample " & @"name" & " doesn't exist"

    let
      distance = @"distance".parseInt
      ns = c.get_neighbours(@"name", distance)
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*[n[0], $n[1]])
    resp ret

#
# load all compressed sequences saved by save_sample_refcomp
#
proc load_instance_samples() =
  if existsDir(c.name):
    var i = 0
    for kind, path in walkDir(c.name):
      if i %% 1000 == 0:
        echo "loaded " & $i & " cached files"
      i = i + 1
      c.add_sample_from_refcomp(extractFilename(path), readFile(path), true)
    echo "loaded " & $i & " cached files"

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          instance_name: string,
          reference_filepath: string,
          mask_filepath: string,
          max_n_positions: int = 130000) =
  echo "starting cw_server " & compile_version &
    " (build time: " & compile_time & ")"

  let
    (_, refseq) = parse_fasta_file(reference_filepath)
    mask = new_Mask(mask_filepath, readFile(mask_filepath))

  c = new_CatWalk(instance_name, reference_filepath, refseq, mask, max_n_positions)
  echo fmt"mask positions: {mask.positions.len}"
  echo fmt"max unknown non-masked positions: {max_n_positions}"

  when defined(no_serialisation):
    echo "skipping loading instance files because this catwalk was built with -d:no_serialisation"
  when not defined(no_serialisation):
    echo "loading instance files. To skip this build with -d:no_serialisation"
    load_instance_samples()

  when not defined(release):
    echo "this catwalk was not built with -d:release. We recommend using -d:release for better performance"
  when not defined(danger):
    echo "this catwalk was not built with -d:danger. We recommend using -d:danger for better performance"

  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)
  jester.serve()

when isMainModule:
  dispatch(main)
