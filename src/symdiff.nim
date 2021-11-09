## This module contains a function to compute the symmetric
## difference of two int arrays.

import intsets

proc sym_diff1*(xs: seq[int], ys: seq[int], buf: var seq[int], s1_n_positions: IntSet, s2_n_positions: IntSet, max_distance: int) =
  let
    last1 = len(xs)
    last2 = len(ys)
  var
    first1 = 0
    first2 = 0

  while first1 != last1:
    if first2 == last2:
      for j in first1..last1-1:
        if not s2_n_positions.contains(xs[j]):
          if not buf.contains(xs[j]):
            buf.add(xs[j])
            if buf.len > max_distance:
              return
      return
    if xs[first1] < ys[first2]:
      if not s2_n_positions.contains(xs[first1]):
        if not buf.contains(xs[first1]):
          buf.add(xs[first1])
          if buf.len > max_distance:
            return
      inc first1
    else:
      if ys[first2] < xs[first1]:
        if not s1_n_positions.contains(ys[first2]):
          if not buf.contains(ys[first2]):
            buf.add(ys[first2])
            if buf.len > max_distance:
              return
      else:
        inc first1
      inc first2
  for j in first2..last2-1:
    if not s1_n_positions.contains(ys[j]):
      if not buf.contains(ys[j]):
        buf.add(ys[j])
        if buf.len > max_distance:
          return

var
  buf2 = newSeqOfCap[int](64)
proc sum_sym_diff1*(xs0, xs1, xs2, xs3, xs4, xs5, xs6, xs7: seq[int], s1_n_positions: IntSet, s2_n_positions: IntSet, max_dist: int) : int =
  buf2.setlen(0)
  symdiff1(xs0, xs1, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs2, xs3, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs4, xs5, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs6, xs7, buf2, s1_n_positions, s2_n_positions, max_dist)
  result = buf2.len

when isMainModule:
  var
    is1: IntSet
    is2: IntSet
    buf: seq[int]
    xs1: seq[int]
    xs2: seq[int]

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[0, 1, 2, 3, 4, 5]
  xs2 = @[0, 1, 2, 3, 4, 5]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[]"

  # bug1
  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[]
  xs2 = @[1, 2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[1, 2, 3]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[1, 2, 3]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[1, 2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2]
  xs2 = @[1, 2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[3]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[1]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3, 4]
  xs2 = @[2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[1, 4]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[2, 3]
  xs2 = @[1, 2, 3, 4]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[1, 4]"

  is1 = initIntSet()
  is2 = initIntSet()
  buf = newSeqOfCap[int](64)
  xs1 = @[]
  xs2 = @[]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[]"

  is1 = initIntSet()
  is2 = initIntSet()
  is2.incl(1)
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[2, 3]"

  is1 = initIntSet()
  is2 = initIntSet()
  is1.incl(1)
  buf = newSeqOfCap[int](64)
  xs1 = @[]
  xs2 = @[1, 2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[2, 3]"

  is1 = initIntSet()
  is2 = initIntSet()
  is1.incl(1)
  buf = newSeqOfCap[int](64)
  xs1 = @[3, 4]
  xs2 = @[1, 2, 3]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[2, 4]"

  is1 = initIntSet()
  is2 = initIntSet()
  is2.incl(1)
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[3, 4]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[2, 4]"

  is1 = initIntSet()
  is2 = initIntSet()
  is2.incl(1)
  is2.incl(2)
  is2.incl(3)
  is1.incl(4)
  is1.incl(5)
  is1.incl(6)
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[4, 5, 6]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[]"

  is1 = initIntSet()
  is2 = initIntSet()
  is2.incl(1)
  is2.incl(2)
  is1.incl(5)
  is1.incl(6)
  buf = newSeqOfCap[int](64)
  xs1 = @[1, 2, 3]
  xs2 = @[4, 5, 6]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[3, 4]"

  is1 = initIntSet()
  is2 = initIntSet()
  is2.incl(1)
  is2.incl(2)
  is1.incl(5)
  is1.incl(6)
  buf = newSeqOfCap[int](64)
  buf.add(0)
  buf.add(10)
  xs1 = @[1, 2, 3]
  xs2 = @[4, 5, 6]
  sym_diff1(xs1, xs2, buf, is1, is2, 20)
  assert $buf == "@[0, 10, 3, 4]"

  echo "Tests passed."
