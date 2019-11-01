import db_sqlite
import options
import intsets
import marshal
import sequtils

let db* = open("cw.sql", "", "", "")

proc create_db*() =
  cw_db.db.exec(sql"create table if not exists active_samples (status, diffsets, n_positions)")
  cw_db.db.exec(sql"create table if not exists all_sample_names (name, id)")
  cw_db.db.exec(sql"create table if not exists neighbours (id, neighbours)")
  cw_db.db.exec(sql"create table if not exists queue (filepath)")

#
# queue
#
proc add_to_queue*(filepath: string) =
  db.exec(sql"insert into queue (filepath, status) values (?)")

proc remove_from_queue*(filepath: string) =
  db.exec(sql"delete from queue where filepath = ?", filepath)

iterator get_queue*(): string =
  for x in db.fastRows(sql"select filepath from queue"):
    yield x[0]

#
# saving
#
proc persist_sample*(index, name, status, diffsets: string, n_positions: IntSet) =
  var
    ns = newSeqOfCap[int](n_positions.len)
  for n in n_positions.items():
    ns.add(n)
  db.exec(sql"""insert into active_samples (status, diffsets, n_positions) values (?, ?, ?)""", status, diffsets, $$ns)
  db.exec(sql"""insert into all_sample_names (name, id) values (?, ?)""", name, index)

proc update_neighbours*(sample_index, neighbours: string) =
  db.exec(sql"""insert or replace into neighbours values (?, ?)""", sample_index, neighbours)
