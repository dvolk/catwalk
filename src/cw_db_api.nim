import db_sqlite
import optional
import marshal

import cligen

let db = open("cw.sql", "", "", "")

proc insert_sample(filepath: string) =
  var done = false
  while not done:
    try:
      db.exec(sql"begin immediate;")
      db.exec(sql"insert into queue values(?);", filepath)
      db.exec(sql"commit;")
      done = true
    except:
      echo "locked"

proc get_neighbours(sample_name: string): seq[(int, int)] =
  var done = false
  while not done:
    try:
      db.exec(sql"begin immediate")
      var rows = db.fastRows(sql"select id from all_sample_names where name = ?", sample_name)
      let sample_id = rows[0][0]
      var neighbours =
      done = true
    except:
      echo "locked"

when isMainModule:
  dispatchMulti([insert_sample], [get_neighbours])
