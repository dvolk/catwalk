import strutils
import httpClient
import json
import os

import cligen

import fasta

var client = newHttpClient()

proc info() =
  let response = client.request("http://127.0.0.1:5000/info")
  echo response.body

proc add_sample(fasta_filepath: string, remove_extension=".fasta") =
  let (_, sequence) = parse_fasta_file(fasta_filepath)
  var
    xs = fasta_filepath.split('/')
    xs_last = xs[xs.len - 1]
    name = xs_last.replace(remove_extension, "")
  let body = %*{
    "name": name,
    "sequence": sequence,
    "keep": %*true
  }
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let response = client.request("http://127.0.0.1:5000/add_sample", httpMethod = HttpPost, body = $body)
  echo $response.status & " " & $response.body

proc add_samples_from_dir(fasta_dir: string, remove_extension=".fasta") =
  for fasta_filepath in fasta_dir.walkDir():
    add_sample(fasta_filepath)

proc list_samples() =
  let response = client.request("http://127.0.0.1:5000/list_samples")
  echo response.body

proc neighbours(name: string) =
  let response = client.request("http://127.0.0.1:5000/neighbours/" & name & "/20")
  echo response.body

proc process_times() =
  let response = client.request("http://127.0.0.1:5000/process_times")
  echo response.body

when isMainModule:
  dispatchMulti([info], [add_sample], [add_samples_from_dir], [neighbours], [list_samples], [process_times])
