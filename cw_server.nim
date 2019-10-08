import json
import jester
import catwalk

var
  instance_name = "test"
  reference = new_Sample("ref", "ref", "AAAA")
  c = new_CatWalk(instance_name, reference)

routes:
  get "/":
    resp c.name

  post "/add_sample":
    let
      js = parseJson(request.body)

    if not js.contains("name"):
      resp "Missing parameters: name"
    if not js.contains("sequence"):
      resp "Missing parameter: sequence"

    if c.samples.contains($js["name"]):
      resp "Sample " & js["name"].getStr() & " already exists"

    var
      s = new_Sample(js["name"].getStr(), js["name"].getStr(), js["sequence"].getStr())
    c.add_sample(s)

    resp "Added " & js["name"].getStr()

  get "/neighbours/@name/@distance":
    resp $c.neighbours
    if not c.samples.contains(@"name"):
      resp "Sample not found"

    if not c.neighbours.contains(@"name"):
      resp %*(@[])

    let
      ns = c.get_neighbours(@"name")
    var
      ret = newJArray()
    for n in ns:
      ret.add(%*(@[n[0], $n[1]]))

    resp ret
    
