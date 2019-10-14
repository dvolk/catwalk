import memfiles

proc parse_fasta_file*(filepath: string): (string, string) =
  var
    mm = memfiles.open(filepath)
    pf_buf: TaintedString = newStringOfCap(1000)
    sequence = newStringOfCap(4_500_000)
    is_first = true
    header = ""

  for line in lines(mm, pf_buf):
    if is_first:
      is_first = false
      header = line
    else:
      for c in line:
        sequence.add(c)

  mm.close()
  return (filepath, sequence)
