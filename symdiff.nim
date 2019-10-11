## This module contains a function to compute the symmetric
## difference of two int arrays.

import intsets
import times
import sequtils

proc count_sym_diff*(xs: seq[int], ys: seq[int]) : int =
  let
    last1 = len(xs) - 1
    last2 = len(ys) - 1
  var
    first1 = 0
    first2 = 0
    count = 0

  if last1 < 0:
    return last2 + 1
  if last2 < 0:
    return last1 + 1

  if xs[last1] < ys[first2]:
    return 2 + last1 + last2

  while first1 != last1:
    if first2 == last2:
      return count + (last1 - first1)

    if xs[first1] < ys[first2]:
      inc first1
      inc count
    else:
      if ys[first2] < xs[first1]:
        inc count
      else:
        inc first1
      inc first2

  return count + (last2 - first2)

proc sym_diff1*(xs: seq[int], ys: seq[int], buf: var IntSet, s1_n_positions: IntSet, s2_n_positions: IntSet, max_distance: int) =
  let
    last1 = len(xs) - 1
    last2 = len(ys) - 1
  var
    first1 = 0
    first2 = 0

  if last1 < 0:
    for y in ys:
      if not s1_n_positions.contains(y):
        buf.incl(y)
        if buf.len > max_distance:
          return
    return
  if last2 < 0:
    for x in xs:
      if not s2_n_positions.contains(x):
        buf.incl(x)
        if buf.len > max_distance:
          return
    return

  if xs[last1] < ys[first2]:
    for x in xs:
      if not s2_n_positions.contains(x):
        buf.incl(x)
        if buf.len > max_distance:
          return
    for y in ys:
      if not s1_n_positions.contains(y):
        buf.incl(y)
        if buf.len > max_distance:
          return
    return

  while first1 != last1:
    if first2 == last2:
      for j in first1..last1-1:
        if not s2_n_positions.contains(xs[j]):
          buf.incl(xs[j])
          if buf.len > max_distance:
            return
      return
    if xs[first1] < ys[first2]:
      if not s2_n_positions.contains(xs[first1]):
        buf.incl(xs[first1])
        if buf.len > max_distance:
          return
      inc first1
    else:
      if ys[first2] < xs[first1]:
        if not s1_n_positions.contains(ys[first2]):
          buf.incl(ys[first2])
          if buf.len > max_distance:
            return
      else:
        inc first1
      inc first2

  for j in first2..last2-1:
    if buf.len > max_distance:
      return
    if not s1_n_positions.contains(ys[j]):
      buf.incl(ys[j])

proc sum_sym_diff1*(xs0, xs1, xs2, xs3, xs4, xs5, xs6, xs7: seq[int], s1_n_positions: IntSet, s2_n_positions: IntSet, max_dist: int) : int =
  var
    buf2 = initIntSet()
  symdiff1(xs0, xs1, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs2, xs3, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs4, xs5, buf2, s1_n_positions, s2_n_positions, max_dist)
  if buf2.len > max_dist: return max_dist + 1
  symdiff1(xs6, xs7, buf2, s1_n_positions, s2_n_positions, max_dist)
  result = buf2.len

proc sym_diff2*(xs: seq[int], ys: seq[int], buf: var seq[int]) =
  let
    last1 = len(xs) - 1
    last2 = len(ys) - 1
  var
    first1 = 0
    first2 = 0

  if last1 < 0:
    for y in ys:
      buf.add(y)
    return
  if last2 < 0:
    for x in xs:
      buf.add(x)
    return

  if xs[last1] < ys[first2]:
    for x in xs:
      buf.add(x)
    for y in ys:
      buf.add(y)
    return

  while first1 != last1:
    if first2 == last2:
      for j in first1..last1-1:
        buf.add(xs[j])
      return
    if xs[first1] < ys[first2]:
      buf.add(xs[first1])
      inc first1
    else:
      if ys[first2] < xs[first1]:
        buf.add(ys[first2])
      else:
        inc first1
      inc first2

  for j in first2..last2-1:
    buf.add(ys[j])
    
proc sum_sym_diff2*(xs0, xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, xs9, xs10, xs11: seq[int]) : int =
  var
    buf2 = newSeqOfCap[int](8000000)
  symdiff2(xs0, xs1, buf2)
  symdiff2(xs2, xs3, buf2)
  symdiff2(xs4, xs5, buf2)
  symdiff2(xs6, xs7, buf2)
  symdiff2(xs8, xs9, buf2)
  symdiff2(xs10, xs11, buf2)
  result = buf2.deduplicate.len
  
#when isMainModule:
#  var
#    xs1: seq[int]
#    xs2: seq[int]
#    xs3: seq[int]
#    xs4: seq[int]
#    xs5: seq[int]
#    xs6: seq[int]
#    xs7: seq[int]
#    xs8: seq[int]
#    xs9: seq[int]
#    xs10: seq[int]
#    xs11: seq[int]
#    xs12: seq[int]
#
#  for x in 0..100_000:
#    xs1.add(x)
#    xs2.add(x + 10)
#    xs3.add(x + 100000)
#    xs4.add(x - 100000)
#    xs5.add(x)
#    xs6.add(x * 2)
#    xs7.add(x * 3)
#    xs8.add(x * 4)
#    xs9.add(x)
#    xs10.add(x + 1000)
#    xs11.add(x - 1000)
#    xs12.add(x)
#
#  var time1: float
#  var l: int
#
#  echo "with intset"
#  time1 = cpuTime()
#  for _ in 0..1:
#    l = sum_sym_diff1(xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, xs9, xs10, xs11, xs12)
#  echo cpuTime() - time1
#  echo l
#  assert l == 342168
#
#  echo "with seq[int]"
#  time1 = cpuTime()
#  for _ in 0..1:
#    l = sum_sym_diff2(xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, xs9, xs10, xs11, xs12)
#  echo cpuTime() - time1
#  echo l
#  assert l == 342168
#  
#
