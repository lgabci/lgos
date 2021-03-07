BEGIN {
  in_comment = 0
}

{
  if ($0 ~ /\/\*\*([^<]|$)/) {         # start of doxygen's comment
    in_comment = 1
  }

  if (! in_comment) {          # out of a doxygen comment
    mpos = $1 ~ ":$" ? 2 : 1   # label

    if ($1 == ".include") {    # .include "file" --> #include "file"
      $1 = "#include"
    }
    else if ($1 == ".set") {   # .set name, value --> #define name value
      $1 = "#define"
      sub(",", " ")
    }
                               # var: .byte val --> byte var = val;
    else if ($1 ~ ":$" && $2 == ".byte"  || $2 == ".double"  ||
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
  else {                       # in a doxygen comment
    if ($1 == "#") {           # function declaration
      $1 = ""
      $0 = "*/ " $0 " /*"
    }
    else if ($1 == "/**" && $2 == "}" && $3 == "*/") {
      $0 = "}"
    }
    else if ($0 ~ /\*\//) {         # end of comment
      in_comment = 0
    }
  }

  if ($0 ~ /\/\*\*</ && $0 !~ /\*\//) {
    in_comment = 1
  }

  print $0
}
