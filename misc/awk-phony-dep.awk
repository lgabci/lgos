BEGIN {
  print("")
}

{
  for (i = 1; i <= NF; i ++) {
    if ($i != obj ":" && $i != src && $i != "\\") {
      print($i ":")
    }
  }
}
