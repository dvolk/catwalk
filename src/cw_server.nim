import json
import tables
import intsets
import strutils
import marshal
import os

import catwalk
import fasta

import jester
import cligen

var c: CatWalk

template check_param(p: string) =
  if not js.contains(p):
    resp "Missing parameter: " & p

router app:
  get "/info":
    resp %*{ "name": c.name,
             "reference_name": c.reference_name,
             "reference_sequence_length": c.reference_sequence.len,
             "mask_name": c.mask.name,
             "mask_positions": c.mask.positions.len,
             "max_distance": c.settings.max_distance,
             "max_n_positions": c.settings.max_n_positions,
             "total_mem": getTotalMem(),
             "occupied_mem": getOccupiedMem(),
             "n_samples": c.active_samples.len,
             "n_neighbour_entries": c.neighbours.len
           }

  get "/debug":
    resp %*($c)

  get "/list_samples":
    var
      ret = newJArray()
    for i, x in c.active_samples:
      ret.add(%*c.all_sample_names[i])
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
    for k, _ in c.active_samples[i..<j]:
      r.add(%*c.all_sample_names[i + k])
    resp %*(r)

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
      resp "Sample " & name & " already exists"

    c.add_sample(name, sequence, true)

    resp "Added " & name

  get "/neighbours/@name":
    let
      ns = c.get_neighbours(@"name")
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*[n[0], $n[1]])
    resp ret

  get "/process_times":
    resp %*(c.process_times)

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          instance_name: string,
          reference_name: string,
          reference_filepath: string,
          mask_name: string,
          mask_filepath: string) =
  let
    (_, refseq) = parse_fasta_file(reference_filepath)
    mask = new_Mask(mask_name, readFile(mask_filepath))

  echo mask.positions.len
  c = new_CatWalk(instance_name, reference_name, refseq, mask)

  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)
  jester.serve()

when isMainModule:
  dispatch(main)
