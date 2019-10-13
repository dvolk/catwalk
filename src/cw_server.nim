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

proc `%`(s: Sample): JsonNode =
  %[("name", %s.name), ("status", %s.status), ("n_positions_len", %s.n_positions.len), ("quality", %s.quality), ("compressed_sequence_counts", %compressed_sequence_counts(s.diffsets)), ("ref_distance", %s.ref_distance), ("n_positions_len", %s.n_positions.len)]

proc add_samples_from_dir*(c: var CatWalk, samples_dir: string) =
  var
    samples: seq[Sample]
  for kind, path in walkDir(samples_dir):
    let
      (sample_header, sample_seq) = parse_fasta_file(path)
    var
      xs = path.split('/')
      xs_last = xs[xs.len - 1]
      name = xs_last.replace(".fasta", "").replace(".fa", "")

    samples.add(new_Sample(name, name, sample_seq))
  # add samples to catwalk
  c.add_samples(samples)

router app:
  get "/info":
    var
      n_ok_samples = 0

    #for k in c.samples.keys:
    #  if c.samples[k].status == Ok:
    #    n_ok_samples = n_ok_samples = 1

    resp %*{ "name": c.name,
             "reference_name": c.reference.name,
             "reference_sequence_length": c.reference.sequence.len,
             "mask_name": c.mask.name,
             "mask_positions": c.mask.positions.len,
             "max_distance": c.settings.max_distance,
             "max_n_positions": c.settings.max_n_positions,
             "total_mem": getTotalMem(),
             "occupied_mem": getOccupiedMem(),
             "n_samples": c.samples.len,
             "n_ok_samples": n_ok_samples,
             "n_neighbour_entries": c.neighbours.len
           }

  get "/debug":
    resp %*($c)

  get "/list_samples":
    var
      ret: string
    for s in c.samples.values:
      ret = ret & $[s.name, $s.status, $s.n_positions.len] & "\n"
    resp %*c.samples

  get "/get_sample/@name":
    resp %*(c.samples[@"name"])

  get "/get_samples/@from/@to":
    var
      i = parseInt(@"from")
      j = parseInt(@"to")
    if i < 0:
      i = 0
    if j >= len(c.samples):
      j = len(c.samples) - 1
    var
      r: seq[JsonNode]
      n = 0
    for k in c.samples.keys:
      if n > i and n <= j:
        r.add(%*c.samples[k])
      inc n
    resp %*(r)

  post "/add_sample":
    let
      js = parseJson(request.body)

    check_param "name"
    check_param "sequence"

    if c.samples.contains($js["name"]):
      resp "Sample " & js["name"].getStr() & " already exists"

    var
      s = new_Sample(js["name"].getStr(), js["name"].getStr(), js["sequence"].getStr())
      xs = @[s]
    c.add_samples(xs)

    resp "Added " & js["name"].getStr()

  post "/add_dir":
    let
      js = parseJson(request.body)
    check_param "samples_dir"

    c.add_samples_from_dir(js["samples_dir"].getStr())
    resp "ok"

  get "/neighbours/@name/@distance":
    let
      ns = c.get_neighbours(@"name")
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*[n[0], $n[1]])
    resp ret

  get "/process_times":
    resp %*(c.process_times)

  get "/save":
    writeFile("samples.dat", $$c.samples)
    writeFile("neighbours.dat", $$c.neighbours)

  get "/load":
    c.samples = to[Table[string, Sample]](readFile("samples.dat"))
    c.neighbours = to[Table[(string, string), int]](readFile("neighbours.dat"))

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          instance_name: string,
          reference_name: string,
          reference_filepath: string,
          mask_name: string,
          mask_filepath: string) =
  let
    (_, refseq) = parse_fasta_file(reference_filepath)
    reference = new_Sample(reference_name, reference_filepath, refseq)
    mask = new_Mask(mask_name, readFile(mask_filepath))

  c = new_CatWalk(instance_name, reference, mask)

  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)
  jester.serve()

when isMainModule:
  dispatch(main)
