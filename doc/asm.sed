# parts for Doxygen, leave it
/^\.doxygen-begin$/,/^\.doxygen-end$/ {
  // s/.*//
  b
}

# include file .include --> #include
s/^[ \t]*\.include[ \t]\+/#include /
t

# symbol, .set --> #define
/^[ \t]*\.set[ \t]\+/ {
  s/[ \t]*\.set[ \t]\+/#define /
  s/,[ \t]*/ /
  b
}

# variable, var: .byte 25 --> unsigned char var = 25;
s/^ *\([^ ]\+\) *: *\.\(byte\|double\|float\|hword\|int\|long\|\octa\|\
\|quad\|short\|single\|word\|extern\) \+\([x[:xdigit:]]\+\)/\2 \1 = \3;/
t

# string variable, var: .string "text" --> char[] var = "text";
s/^ *\([^ ]\+\) *: *\.string \+\("[^"]*"\)/char[] \1 = \2;/
t

# BSS variables, .lcomm var, size --> byte var[size];
/^[ \t]*\.lcomm[ \t]\+/ {
  s/[ \t]*\.lcomm[ \t]\+\([^ \t,]\+\),[ \t]*\([[:digit:]]\+\)$/byte \1[\2];/
  b
}

# function calls
s/^\(.*:\)\? \+\(call\|jmp\) \+[[:digit:]][bf]$//
t
s/^\(.*:\)\? \+\(call\|jmp\) \+\([^ ]*\)/\3();/
t

# all other asm thing, empty row
s/.*//
