import memfiles

proc parse_fasta_file*(filepath: string): (string, string) =
  var
    mm = memfiles.open(filepath)
    pf_buf: TaintedString = newStringOfCap(1000)
    sequence = newStringOfCap(4_500_000)
    is_first = true
    header = ""
    i = 0

  for line in lines(mm, pf_buf):
    if is_first:
      is_first = false
      header = line
    else:
      i = 0
      for c in line:
        sequence.add(c)
        inc i

  mm.close()
  return (header, sequence)
