import httpClient
import json
import tables
import strutils

import jester
import cligen

include "front.nimf"
include "sample.nimf"

var
  client = newHttpClient()
  server_host: string
  server_port: int

proc cw_server_url() : string =
  "http://" & server_host & ":" & $server_port

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
      r1 = client.request(cw_server_url() & "/info")
      info = parseJson(r1.body)
    if i < 0:
      i = 0
    if j < 15:
      j = 15
    let
      r2 = client.request(cw_server_url() & "/get_samples/" & $i & "/" & $j)
      samples = parseJson(r2.body)
    resp generateFrontPage(info, samples, i, j)

  get "/sample/@sample_name":
    let
      r1 = client.request(cw_server_url() & "/get_sample/" & @"sample_name")
      sample = parseJson(r1.body)
      r2 = client.request(cw_server_url() & "/neighbours/" & @"sample_name" & "/50")
      neighbours = parseJson(r2.body)
    resp generateSamplePage(sample, neighbours)

proc main(bind_host: string = "0.0.0.0", bind_port: int = 5001, cw_server_host = "127.0.0.1", cw_server_port = 5000) =
  var
    port = bind_port.Port
    settings = newSettings(bindAddr=bind_host, port=port)
    jester = initJester(app, settings=settings)

  server_port = cw_server_port
  server_host = cw_server_host

  jester.serve()

when isMainModule:
  dispatch(main)
