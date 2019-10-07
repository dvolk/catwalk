## This module contains a function to compute the symmetric
## difference of two int arrays.

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
