## This module contains a function to compute the symmetric
## difference of two int arrays.

import intsets
import times
import sequtils

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

when isMainModule:
  var
    xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8: seq[int]
    l: int
    is1 = initIntSet()
    is2 = initIntSet()

  for x in 0..100_000:
    xs1.add(x)
    xs2.add(x + 10)
    xs3.add(x + 100000)
    xs4.add(x - 100000)
    xs5.add(x)
    xs6.add(x * 2)
    xs7.add(x * 3)
    xs8.add(x * 4)

  for _ in 0..10:
    l = sum_sym_diff1(xs1, xs2, xs3, xs4, xs5, xs6, xs7, xs8, is1, is2, 20)
  assert l == 21
