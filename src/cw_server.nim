import json
import jsony
import tables
import intsets
import strutils
import marshal
import system
import os
import sequtils

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

proc add_samples_from_refcomp_array(names: string, refcomps: string) =
  c.add_samples_from_refcomp_array(names, refcomps)

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
  writeFile(c.name & "/" & name, $(%*{ "name": name,
                                       "N": n_pos_buf,
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
      "max_distance": c.settings.max_distance,
      "max_n_positions": c.settings.max_n_positions,
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

  get "/list_samples":
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
      resp Http200, "Sample " & name & " already exists"

    c.add_sample(name, sequence, true)

    when defined(no_serialisation):
      echo "skipping saving instance file because this catwalk was built with -d:no_serialisation"
    when not defined(no_serialisation):
      save_sample_refcomp(name)

    #for i in 1..9:
    #  var sq: string
    #  deepCopy sq, sequence
    #  c.add_sample(name & "-" & $i, sq, true)

    resp Http201, "Added " & name

  post "/add_sample_from_refcomp":
    let
      js = parseJson(request.body)
      name = js["name"].getStr()
      refcomp = js["refcomp"].getStr()

    if c.all_sample_indexes.contains(name):
      resp Http200, "Sample " & name & " already exists"

    add_sample_from_refcomp(name, refcomp, true)
    resp Http201, "Added " & name

  post "/add_sample_from_refcomp_array":
    let
      js = request.body.fromJson(Table[string, string])
      names = js["names"]
      refcomps = js["refcomps"]

    add_samples_from_refcomp_array(names, refcomps)
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

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          instance_name: string,
          reference_filepath: string,
          mask_filepath: string,
          max_distance: int) =
  echo "starting cw_server " & compile_version &
    " (build time: " & compile_time & ")"

  let
    (_, refseq) = parse_fasta_file(reference_filepath)
    mask = new_Mask(mask_filepath, readFile(mask_filepath))

  echo mask.positions.len
  c = new_CatWalk(instance_name, reference_filepath, refseq, mask)
  c.settings.max_distance = max_distance

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
