{
  if ($1 ~ /[0-9]+:/) {
    sub(/\.\.$/, "", $4)
    sub(/:$/, "", $5)
    print $4, $5
  }
}
