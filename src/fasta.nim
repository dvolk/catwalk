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


iterator parse_multifasta_singleline_file*(filepath: string): tuple[header: string, sequence: string] =
  var
    mm = memfiles.open(filepath)
    pf_buf: TaintedString = newStringOfCap(4_500_000)
    header = newStringOfCap(4_000)
    is_header = true

  for line in lines(mm, pf_buf):
    if is_header:
      header = line
    else:
      yield (header, line)
    is_header = not is_header

  mm.close()
