import httpClient
import json
import tables
import strutils

import jester
import cligen

include "front.nimf"
include "sample.nimf"

var client = newHttpClient()

router app:
  get "/":
    var
      i = 0
      j = 15
    if request.params.contains("i"):
      i = request.params["i"].parseInt()
    if request.params.contains("j"):
      j = request.params["j"].parseInt()
    let
      r1 = client.request("http://127.0.0.1:5000/info")
      info = parseJson(r1.body)
    if i < 0:
      i = 0
    if j < 15:
      j = 15
    let
      r2 = client.request("http://127.0.0.1:5000/get_samples/" & $i & "/" & $j)
      samples = parseJson(r2.body)
    resp generateFrontPage(info, samples, i, j)

  get "/sample/@sample_name":
    let
      r1 = client.request("http://127.0.0.1:5000/get_sample/" & @"sample_name")
      sample = parseJson(r1.body)
      r2 = client.request("http://127.0.0.1:5000/neighbours/" & @"sample_name" & "/50")
      neighbours = parseJson(r2.body)
    resp generateSamplePage(sample, neighbours)

proc main(bind_host: string = "0.0.0.0", bind_port: int = 5001) =
  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)
  jester.serve()

when isMainModule:
  dispatch(main)
