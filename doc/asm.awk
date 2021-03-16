BEGIN {
  in_comment = 0
}

{
  print
  for (i = 1; i <= NF; i ++) {

    if ($i ~ /^\/\*\*/) {      # start of doxygen's comment
      in_comment = 1
    }

    if (! in_comment) {        # not in a doxygen comment
      if (i == 1) {
        if ($i == ".include") { # .include "file" --> #include "file"
          $i = "#include"
          break
        }
        else if ($i == ".set") { # .set name, valud --> #define nam value
          $i = "#define"
          sub(",", " ", $i+1)
          break
        }
      }
    }
    else {                     # in a Doxygen comment
      if ($i ~ /\*\/$/) {      # end of comment
        in_comment = 0
      }
      else if ($i == "#") {    # function declaration
        $i = "*/ "
        $0 = $0 " /*"
        break
      }
      else if ($i == "/**" && $i+1 == "}" && $i+2 == "*/") {
        $0 = "}"
        break
      }
    }
  }


  if (! in_comment) {          # out of a doxygen comment
    mpos = $1 ~ ":$" ? 2 : 1   # label

                               # var: .byte val --> byte var = val;
     if ($1 ~ ":$" && $2 == ".byte"  || $2 == ".double"  ||
             $2 == ".float"  || $2 == ".hword"  || $2 == ".int"  ||
             $2 == ".long"  || $2 == ".octa"  || $2 == ".quad"  ||
             $2 == ".short"  || $2 == ".single"  || $2 == ".word"  ||
             $2 == ".extern") {
      sub(":", "", $1)
      sub(".", "", $2)
      temp = $1;
      $1 = $2;
      $2 = temp;
      $3 = " = " $3 ";"
    }
                               # var: .string "text" --> char[] var = "text";
    else if ($1 ~ ":$" && $2 == ".string") {  # string variable
      sub(":", "", $1)
      $2 = " = ";
      $0 = "char[] " $0 ";";
    }
    else if ($1 == ".lcomm") {  # .lcomm var, len --> byte var[len]
      sub(",", "", $2)
      $1 = "byte " $2 "[" $3 "];"
      $2 = ""
      $3 = ""
    }
    else if ($mpos == "call" || $mpos == "lcall") {
      $0 = $(mpos + 1) "();"
    }
    else if ($mpos == "ret" || $mpos == "lret" || $mpos == "ljmp") {
      $0 = "}"
    }
    else {
      $0 = ""
    }
  }


  print $0
}


