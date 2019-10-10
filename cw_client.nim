import httpClient
import json
import oids

import cligen

import fasta

var client = newHttpClient()

proc add_sample(fasta_filepath: string) =
  let (filepath, sequence) = parse_fasta_file(fasta_filepath)
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let body = %*{
    "name": $genOid(),
    "sequence": sequence
  }
  let response = client.request("http://127.0.0.1:5000/add_sample", httpMethod = HttpPost, body = $body)
  echo response.body

proc list_samples() =
  let response = client.request("http://127.0.0.1:5000/list_samples")
  echo response.body

proc neighbours(name: string) =
  let response = client.request("http://127.0.0.1:5000/get_neighbours/" & name & "/50")
  echo response.body

when isMainModule:
  dispatchMulti([add_sample], [neighbours], [list_samples])
