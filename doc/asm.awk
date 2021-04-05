BEGIN {
  in_comment = 0
}

{
  label = ""
  if ($1 ~ ":$") {
    label = $1
    sub(/:$/, "", label)
    $1 = ""
  }

  for (i = 1; i <= NF; i ++) {

    if ($i ~ /^\/\*\*/) {               # start of doxygen's comment
      in_comment = 1
      continue
    }

    if (! in_comment) {                 # not in a doxygen comment
      if (i == 1) {
        if ($i == ".include") {         # .include "file" --> #include "file"
          $i = "#include"
          i ++
          continue
        }
        if ($i == ".set") {             # .set name, val --> #define nam val
          $i = "#define"
          sub(/,$/, " ", $(i+1))
          i = i + 2
          continue
        }
        if ($i == ".lcomm") {           # .lcomm var, len --> byte var[len]
          $i = "byte"
          sub(/,$/, "", $(i+1))
          $(i+1) = $(i+1) "[" $(i+2) "];"
          $(i+2) = ""
          i = i + 2
          continue
        }
      }
      else if (i == 2 && label) {
                                        # var: .byte val --> byte var = val;
        if ($i == ".byte" || $i == ".double" || $i == ".float" ||
            $i == ".hword" || $i == ".int" || $i == ".long" ||
            $i == ".octa" || $i == ".quad" || $i == ".short" ||
            $i == ".single" || $i == ".word" || $i == ".extern") {
          sub(/^\./, "", $i)
          $(i-1) = $i;
          $i = label;
          $(i+1) = "= " $(i+1) ";"
          i ++
          continue
        }
                             # var: .string "text" --> char[] var = "text";
        if ($i == ".string" && $(i+1) ~ "^\"") {
          $(i-1) = "char[]"
          $i = label " = "
          i ++
          while (i <= NF && $i !~ "\"$") {
            i ++
          }
          $i = $i ";"
          continue
        }
      }

      if ($i == "call" || $i == "lcall") {
        $i = ""
        $(i+1) = $(i+1) "();"
        i ++
        continue
      }
      if ($i == "ret" || $i == "lret") {
        $i = "}"
        continue
      }
      if ($i == "ljmp") {
        $i = "}"
        $(i+1) = ""
        $(i+2) = ""
        i = i + 2
        continue
      }
      if ($i ~ /mov[bwl]/) {
        sub(/,$/, "", $(i+1))
        sub(/^(\$|%)/, "", $(i+1))
        sub(/^(\$|%)/, "", $(i+2))
        $i = $(i+2) " = " $(i+1) ";"
        $(i+1) = ""
        $(i+2) = ""
        i = i + 2
        continue
      }

      $i = ""
    }
    else {                              # in a Doxygen comment
      if ($i ~ /\*\/$/) {               # end of comment
        in_comment = 0
        continue
      }
      if ($(i-1) == "/**" && $i == "}" && $(i+1) == "*/") {
        $(i-1) = "}"
        $(i) = ""
        $(i+1) = ""
        i ++
        in_comment = 0
        continue
      }
      if (i == 1) {
        if ($i == "#") {             # function declaration
          $i = "*/"
          while (++ i <= NF) {
            if ($i == "--") {
              $i = "/**<"
              $(NF+1) = "*/"
              break
            }
          }
          $(NF+1) = "/*"
          break
        }
      }
    }
  }

  print $0
}
