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

proc load(c: var CatWalk) =
  let start = cpuTime()
  # load active samples
  for x in cw_db.db.instantRows(sql"select id, status, diffsets, n_positions from active_samples"):
    let
      id = to[int](x[0])
      status = to[SampleStatus](x[1])
      diffsets = to[CompressedSequence](x[2])
      n_positions = to[seq[int]](x[3])
    var
      s: Sample
    s.status = status
    s.diffsets = diffsets
    s.n_positions = initIntSet()
    for n in n_positions:
      s.n_positions.incl(n)
    c.active_samples[id] = s

  # load neighbours
  var i = 0
  for x in cw_db.db.instantRows(sql"select id, neighbours from neighbours"):
    c.neighbours[i] = to[seq[array[2, int]]](x[1])
    inc i

  # load all_sample_names
  i = 0
  for x in cw_db.db.instantRows(sql"select id, name from all_sample_names"):
    let name = x[1]
    c.all_sample_names[i] = name
    c.all_sample_indexes[name] = i
    inc i

  let dt = cpuTime() - start
  echo "Loaded " & $c.active_samples.len & " active samples and " &
    $c.all_sample_names.len & " total samples in " & $dt & " seconds"
        
  #echo c.neighbours

proc loop(c: var CatWalk) =
  while true:
    var queue = cw_db.get_queue()
    for (q_filepath, keep) in queue:
      echo "adding " & q_filepath & " keep: " & $keep
      let
        (header, sequence) = parse_fasta_file(q_filepath)

      c.add_sample(q_filepath, sequence, keep) # no need to add to tables

      let
        new_index = c.all_sample_names.len - 1

      #echo $new_index

      if keep:
        let new_sample = c.active_samples[new_index]
        cw_db.persist_sample($new_index, q_filepath, $$new_sample.status,
                             $$new_sample.diffsets, new_sample.n_positions,
                             keep)

      cw_db.db.exec(sql"""insert into all_sample_names (id, name) values (?, ?)""",
                    new_index,
                    q_filepath)
      
      if new_index in c.neighbours:
        cw_db.update_neighbours($new_index, $$c.neighbours[new_index])
        for (sample2_index, distance) in c.neighbours[new_index]:
          #echo $sample2_index & " " & $distance
          if sample2_index < new_index:
            cw_db.update_neighbours($sample2_index, $$c.neighbours[sample2_index])
      cw_db.remove_from_queue(q_filepath)
      #echo c.neighbours

      echo "added " & q_filepath
    sleep(1000)
    echo "have " & $c.active_samples.len & " active samples and " &
      $c.all_sample_names.len & " total"

proc main(instance_name: string, reference_filepath: string, mask_filepath: string) =
  let
    (_, reference_sequence) = parse_fasta_file(reference_filepath)
    mask = new_Mask(mask_filepath, readFile(mask_filepath))
  var
    c = new_CatWalk(instance_name, reference_filepath, reference_sequence, mask)
  c.settings.max_distance = 20

  cw_db.create_db()
  c.load()
  c.loop()

when isMainModule:
  dispatch(main)
