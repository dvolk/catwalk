import json
import tables
import intsets
import strutils
import marshal
import system

import catwalk
import fasta

import jester
import cligen

var
  c: CatWalk
  default_max_distance: int

const compile_version = gorge "git describe --tags --always --dirty"
const compile_time = gorge "date --rfc-3339=seconds"

template check_param(p: string) =
  if not js.contains(p):
    resp "Missing parameter: " & p

router app:
  get "/info":
    resp %*{ "name": c.name,
             "reference_name": c.reference_name,
             "reference_sequence_length": c.reference_sequence.len,
             "mask_name": c.mask_name,
             "mask_positions": c.mask_positions.len,
             "total_mem": getTotalMem(),
             "occupied_mem": getOccupiedMem(),
             "n_samples": c.active_samples.len,
             "compile_version": compile_version,
             "compile_time": compile_time
           }

  get "/debug":
    resp %*($c)

  get "/list_samples":
    var
      ret = newJArray()
    for k in c.active_samples.keys:
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

  post "/add_sample":
    let
      js = parseJson(request.body)

    check_param "name"
    check_param "sequence"

    let
      name = js["name"].getStr()
      sequence = js["sequence"].getStr()

    if c.all_sample_indexes.contains(name):
      resp Http200, "Sample " & name & " already exists"

    c.add_sample(name, sequence)
    resp Http201, "Added " & name

  post "/add_sample_from_refcomp":
    let
      js = parseJson(request.body)

    check_param "name"
    check_param "refcomp"

    let
      name = js["name"].getStr()
      refcomp_json = js["refcomp"].getStr()

    if c.all_sample_indexes.contains(name):
      resp Http200, "Sample " & name & " already exists"

    c.add_sample_from_refcomp(name, refcomp_json)
    resp Http201, "Added " & name

  get "/neighbours/@name/@distance?":
    if not c.all_sample_indexes.contains(@"name"):
      resp Http404, "Sample " & @"name" & " doesn't exist"

    let distance =
      if @"distance" == "":
        default_max_distance
      else:
        parseInt(@"distance")

    let
      ns = c.get_neighbours(@"name", distance)
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*[n[0], $n[1]])
    resp ret

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          instance_name: string,
          reference_name: string,
          reference_filepath: string,
          mask_name: string,
          mask_filepath: string,
          max_distance: int) =
  echo "starting cw_server " & compile_version &
    " (build time: " & compile_time & ")"

  let
    (_, refseq) = parse_fasta_file(reference_filepath)
    mask_positions = load_mask(readFile(mask_filepath))

  c = new_CatWalk(instance_name, reference_name, refseq, mask_name, mask_positions)
  default_max_distance = max_distance

  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)
  jester.serve()

when isMainModule:
  dispatch(main)
