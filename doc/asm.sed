# comments for doxygen, leave it
s/\/\*\* } \*\//}/
t

/\/\*\*.*\*\// {
b
}

/^\/\*\*/,/\*\// {
s/ \* \(.*{\)/*\/ \1 \/*/
b
}

# include file .include --> #include
s/^\.include \+/#include /
t

# symbol, .set --> #define
/^\.set \+/ {
  s/\.set \+/#define /
  s/, */ /
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
s/\.lcomm \+\([^ ,]\+\), *\([[:digit:]]\+\)$/byte \1[\2];/
t


# function calls
s/^\(.*:\)\? \+\(call\|jmp\) \+[[:digit:]][bf]$//
t
s/^\(.*:\)\? \+\(call\|jmp\) \+\([^ ]*\)/\3();/
t

# all other asm things, empty row
s/.*//
