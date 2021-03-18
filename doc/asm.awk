BEGIN {
  in_comment = 0
}

{
  label = ""
  if ($1 ~ ":$") {
    label = $1
    sub(/:/, "", label)
  }

  for (i = 1; i <= NF; i ++) {

    if ($i ~ /^\/\*\*/) {               # start of doxygen's comment
      in_comment = 1
    }

    if (! in_comment) {                 # not in a doxygen comment
      if (i == 1) {
        if ($i == ".include") {         # .include "file" --> #include "file"
          $i = "#include"
        }
        else if ($i == ".set") {        # .set name, val --> #define nam val
          $i = "#define"
          sub(/,/, " ", $(i+1))
          i ++
          continue
        }
        else if ($1 == ".lcomm") {      # .lcomm var, len --> byte var[len]
          $1 = "byte"
          sub(/,/, "", $2)
          $2 = $2 "[" $3 "]"
          $3 = ""
        }
      }
      else if (i == 2 && label) {
                                        # var: .byte val --> byte var = val;
        if ($i == ".byte" || $i == ".double" || $i == ".float" ||
            $i == ".hword" || $i == ".int" || $i == ".long" ||
            $i == ".octa" || $i == ".quad" || $i == ".short" ||
            $i == ".single" || $i == ".word" || $i == ".extern") {
          sub(/\./, "", $i)
          $(i-1) = $i;
          $i = label;
          $(i+1) = "= " $(i+1) ";"
          i ++
          continue
        }
                                        # var: .string "text" --> char[] var = "text";
        else if ($i == ".string" && $(i+1) ~ "^\"") {
          $1 = "char[]"
          $2 = label
          $0 = gensub(/"/, "\";", 2)
        }

      }

      if ($i == "call" || $i == "lcall") {
        $i = ""
        $(i+1) = $(i+1) "();"
      }
      if ($i == "ret" || $i == "lret" || $i == "ljmp") {
        $i = "}"
      }
##      else {
##        $0 = ""
##      }

    }
    else {                              # in a Doxygen comment
      if ($i ~ /\*\/$/) {               # end of comment
        in_comment = 0
      }
      else if ($1 == "#") {             # function declaration
        $1 = "*/ "
        $0 = $0 " /*"
        break
      }
      else if ($i == "/**" && $(i+1) == "}" && $(i+2) == "*/") {
        $i = "}"
        $(i+1) = ""
        $(i+2) = ""
      }
    }
  }

  print $0
}


