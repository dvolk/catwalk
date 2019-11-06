import db_sqlite
import options
import intsets
import marshal
import sequtils
import strutils

let db* = open("cw.sql", "", "", "")

proc create_db*() =
  cw_db.db.exec(sql"create table if not exists active_samples (id primary key, status, diffsets, n_positions)")
  cw_db.db.exec(sql"create table if not exists all_sample_names (id primary key, name)")
  cw_db.db.exec(sql"create table if not exists neighbours (id primary key, neighbours)")
  cw_db.db.exec(sql"create table if not exists queue (filepath, keep)")

#
# queue
#
proc get_queue*(): seq[(string, bool)] =
  result = @[]
  try:
    for row in db.fastRows(sql"select filepath, keep from queue limit 100"):
      result.add((row[0], parseBool(row[1])))
  except:
    return result

proc remove_from_queue*(filepath: string) =
  db.exec(sql"delete from queue where filepath = ?", filepath)

#
# saving
#
proc persist_sample*(index, name, status, diffsets: string, n_positions: IntSet, keep: bool) =
  var
    ns = newSeqOfCap[int](n_positions.len)
  for n in n_positions.items():
    ns.add(n)
  db.exec(sql"""insert into active_samples (id, status, diffsets, n_positions) values (?, ?, ?, ?)""", index, status, diffsets, $$ns)

proc update_neighbours*(sample_index, neighbours: string) =
  #echo "update_neighbours " & sample_index & " " & neighbours
  db.exec(sql"""insert or replace into neighbours values (?, ?)""", sample_index, neighbours)
  
