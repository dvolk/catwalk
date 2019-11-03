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
  # load active samples
  for x in cw_db.db.instantRows(sql"select status, diffsets, n_positions from active_samples"):
    let
      status = to[SampleStatus](x[0])
      diffsets = to[CompressedSequence](x[1])
      n_positions = to[seq[int]](x[2])
    var
      s: Sample
    s.status = status
    s.diffsets = diffsets
    s.n_positions = initIntSet()
    for n in n_positions:
      s.n_positions.incl(n)
    c.active_samples.add(s)

  # load neighbours
  var i = 0
  for x in cw_db.db.instantRows(sql"select id, neighbours from neighbours"):
    c.neighbours[i] = to[seq[(int, int)]](x[1])
    inc i

  # load all_sample_names
  i = 0
  for x in cw_db.db.instantRows(sql"select name, id from all_sample_names"):
    let name = x[0]
    c.all_sample_names[i] = name
    c.all_sample_indexes[name] = i
    inc i

proc loop(c: var CatWalk) =
  while true:
    var queue = cw_db.get_queue()
    for q_filepath in queue:
      echo "adding " & q_filepath
      let
        (header, sequence) = parse_fasta_file(q_filepath)

      c.add_sample(q_filepath, sequence, true) # no need to add to tables
      let
        new_index = c.active_samples.len - 1
        new_sample = c.active_samples[new_index]
      cw_db.persist_sample($new_index, q_filepath,
                           $$new_sample.status, $$new_sample.diffsets, new_sample.n_positions)
      if new_index in c.neighbours:
        cw_db.update_neighbours($new_index, $$c.neighbours[new_index])
        for old_index, distance in c.neighbours[new_index]:
          cw.add_neighbour_to_existing_neighbours_entry($new_index, $old_index, $distance)
      else:
        cw_db.update_neighbours($new_index, "[]")
      cw_db.remove_from_queue(q_filepath)
      echo c.neighbours

      echo "added " & q_filepath

proc main(instance_name: string, reference_filepath: string, mask_filepath: string) =
  let
    (_, reference_sequence) = parse_fasta_file(reference_filepath)
    mask = new_Mask(mask_filepath, readFile(mask_filepath))
  var
    c = new_CatWalk(instance_name, reference_filepath, reference_sequence, mask)
  c.settings.max_distance = 1000

  cw_db.create_db()
  c.load()
  c.loop()

when isMainModule:
  dispatch(main)
