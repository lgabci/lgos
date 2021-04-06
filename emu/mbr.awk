BEGIN {
  if (! offset) {
    offset = 0
  }
}

{
  if ($1 == "LOAD") {
    offs=$2
    addr=$3
    size=$5
    if (size > 0) {
      print "dd if=" mbrfile " of=" imgfile " bs=1 count=$((" size ")) " \
        "skip=$((" offs ")) seek=$((" addr " + " offset ")) " \
        "status=none conv=notrunc"
    }
  }
}
