import db_sqlite
import options

type
  QueueElem* = tuple
    name: string
    filepath: string
    sequence: string
    status: string

# table config(key, value)
# table queue (name, filepath, sequence, status)
# table samples (name, status, diffsets, n_positions, ref_distance)
# table neighbours (sample_name, neighbours_json)

let db* = open("cw.sql", "", "", "")

proc create_db*() =
  db.exec(sql"""create table if not exists config (key, value)""")
  db.exec(sql"""create table if not exists queue (name, filepath, sequence, status)""")
  db.exec(sql"""create table if not exists samples (name, status, diffsets, n_positions)""")
  db.exec(sql"""create table if not exists neighbours (sample_name, neighbours)""")

proc set_config_key*(key, val: string) =
  db.exec(sql"""insert or replace into config (key, value) values (?, ?)""", key, val)

proc add_to_queue*(name, filepath, sequence: string) =
  db.exec(sql"""insert into queue (name, filepath, sequence, status) values (?, ?, ?, "queued")""")

proc remove_from_queue*(name: string) =
  db.exec(sql"""delete from queue where name = ?""", name)

proc get_queue*(): seq[QueueElem] =
  result = @[]
  for x in db.fastRows(sql"select name, filepath, sequence, status from queue"):
    var q: QueueElem
    q.name = x[0]
    q.filepath = x[1]
    q.sequence = x[2]
    q.status = x[3]
    result.add(q)

proc get_queue_top*(): Option[QueueElem] =
  let row = db.getRow(sql"select name, filepath, sequence, status from queue limit 1")
  if row[0] != "":
    return some((row[0], row[1], row[2], row[3]))

proc update_neighbours*(sample_name, neighbours: string) =
  db.exec(sql"""insert or replace into neighbours values (?, ?)""", sample_name, neighbours)

proc get_sample*(name: string) =
  db.exec(sql"""select name, status, diffsets, n_positions from samples where name = ?""", name)

proc get_samples*() =
  db.exec(sql"""select name, status, diffsets, n_positions from samples""")

proc add_sample*(name, status, diffsets, n_positions: string) =
  db.exec(sql"""insert into samples (name, status, diffsets, n_positions) values (?, ?, ?, ?)""", name, status, diffsets, n_positions)
