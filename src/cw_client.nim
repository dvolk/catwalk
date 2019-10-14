import strutils
import httpClient
import json

import cligen

import fasta

var client = newHttpClient()

proc info() =
  let response = client.request("http://127.0.0.1:5000/info")
  echo response.body

proc add_sample(fasta_filepath: string) =
  let (_, sequence) = parse_fasta_file(fasta_filepath)
  var
    xs = fasta_filepath.split('/')
    xs_last = xs[xs.len - 1]
    name = xs_last.replace(".fasta", "").replace(".fa", "")
  let body = %*{
    "name": name,
    "sequence": sequence
  }
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let response = client.request("http://127.0.0.1:5000/add_sample", httpMethod = HttpPost, body = $body)
  echo response.body

proc add_samples_from_dir(samples_dir: string) =
  let body = %*{
    "samples_dir": samples_dir
  }

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let r = client.request("http://127.0.0.1:5000/add_samples_from_dir", httpMethod = HttpPost, body = $body)
  echo r.body


proc list_samples() =
  let response = client.request("http://127.0.0.1:5000/list_samples")
  echo response.body

proc neighbours(name: string) =
  let response = client.request("http://127.0.0.1:5000/neighbours/" & name & "/50")
  echo response.body

proc process_times() =
  let response = client.request("http://127.0.0.1:5000/process_times")
  echo response.body

when isMainModule:
  dispatchMulti([info], [add_sample], [add_samples_from_dir], [neighbours], [list_samples], [process_times])
