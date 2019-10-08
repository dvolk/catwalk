## This module contains a function to compute the symmetric
## difference of two int arrays.

import sequtils
import intsets

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

proc sym_diff*(xs: seq[int], ys: seq[int], buf: var IntSet) =
  let
    last1 = len(xs) - 1
    last2 = len(ys) - 1
  var
    first1 = 0
    first2 = 0


  if last1 < 0:
    for y in ys:
      buf.incl(y)
    return
  if last2 < 0:
    for x in xs:
      buf.incl(x)
    return

  if xs[last1] < ys[first2]:
    for x in xs:
      buf.incl(x)
    for y in ys:
      buf.incl(y)
    return

  while first1 != last1:
    if first2 == last2:
      for j in first1..last1-1:
        buf.incl(xs[j])
      return
    if xs[first1] < ys[first2]:
      buf.incl(xs[first1])
      inc first1
    else:
      if ys[first2] < xs[first1]:
        buf.incl(ys[first2])
      else:
        inc first1
      inc first2

  for j in first2..last2-1:
    buf.incl(ys[j])

when isMainModule:
  var
    buf = initIntSet()
  symdiff(@[1,2,3], @[5,6,7], buf)
  symdiff(@[1,2,3], @[1,2,3], buf)
  symdiff(@[], @[1,2,3], buf)
  symdiff(@[1,2,3], @[], buf)
  symdiff(@[8,9,10], @[11, 12, 13], buf)
  let l = len(buf)
  echo l
  echo buf
  assert l == 12

  
