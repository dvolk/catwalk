import json
import os
import times
import options
import tables
import marshal
import db_sqlite
import intsets

import cligen

import fasta
import catwalk
import cw_db

proc load_samples(): seq[Sample] =
  for x in cw_db.all_samples():
    var
      s: Sample
    s.name = x[0]
    s.status = to[SampleStatus](x[1])
    s.diffsets = to[CompressedSequence](x[2])
    s.n_positions = to[IntSet](x[3])
    result.add(s)

proc load_neighbours(): Table[int, seq[(int, int)]] =
  var i = 0
  for x in cw_db.all_neighbours():
    let
      neighbours = to[seq[(int, int)]](x[1])
    result[i] = @[]
    for neighbour in neighbours:
      result[i].add(neighbour)
    inc i

proc main(bind_host: string = "0.0.0.0",
          bind_port: int = 5000,
          create_database = false,
          instance_name: string,
          reference_name: string,
          reference_filepath: string,
          mask_name: string,
          mask_filepath: string) =
  let
    (refheader, refseq) = parse_fasta_file(reference_filepath)
    reference = new_Sample(reference_filepath, refseq)
    mask = new_Mask(mask_name, readFile(mask_filepath))
    max_distance = 20
    max_n_positions = 130000
  var
    c = new_CatWalk(instance_name, reference, mask)

  if create_database:
    create_db()

  c.samples = load_samples()
  c.neighbours = load_neighbours()

  var
    queue: seq[QueueElem]
  while true:
    queue = cw_db.get_queue()
    if queue.len > 0:
      var
        samples = newSeqOfCap[Sample](queue.len)
      for q in queue:
        # parse the fasta files
        let
          sample_name = q.name
          (header, sequence) = parse_fasta_file(q.filepath)
        samples.add(new_Sample(sample_name, sequence))

      # add samples to catwalk
      c.add_samples(samples)

      for q in queue:
        # remove from queue
        cw_db.remove_from_queue(q.name)
        let
          new_sample = c.samples[c.sample_indexes[q.name]]
        # add processed sample data to database
        cw_db.add_sample(new_sample.name,
                         $$new_sample.status,
                         $$new_sample.diffsets,
                         $$new_sample.n_positions)
        cw_db.update_neighbours(new_sample.name,
                                $$c.get_neighbours(new_sample.name))
        echo "added " & new_sample.name
    sleep(2)

when isMainModule:
  dispatch(main)
