import json
import tables
import jester
import intsets

import catwalk
import fasta

let
  instance_name = "test"
  (_, refseq) = parse_fasta_file("references/R00000039.fa")
  reference = new_Sample("R00000039.fa", "R00000039.fa", refseq)
  mask = new_Mask("TB-exclude-adaptive", readFile("references/TB-exclude-adaptive.txt"))
var
  c = new_CatWalk(instance_name, reference, mask)

template check_param(p: string) =
  if not js.contains(p):
    resp "Missing parameter: " & p
  
routes:
  get "/info":
    resp %*{ "name": c.name,
             "reference_name": c.reference.name,
             "reference_sequence_length": c.reference.sequence.len,
             "total_mem": $getTotalMem(),
             "occupied_mem": $getOccupiedMem()
           }
       
  get "/debug":
    resp $c

  get "/list_samples":
    var
      ret: string
    for s in c.samples.values:
      ret = ret & $[s.name, $s.status, $s.n_positions.len] & "\n"
    resp $ret

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

  get "/neighbours/@name/@distance":
    let
      ns = c.get_neighbours(@"name")
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*(@[n[0], $n[1]]))
    resp ret

  get "/process_times":
    resp %*(c.process_times)
    
