# gptrixie
A tool to generate NativeCall code from C headers

You will need gccxml and gcc/g++ 4.9
Beware some distrib provide gccxml as castxml and it sucks, you will need to change the code to use gccxml.real
of have sure the gccxml executable is gccxml

use it like this :

perl6 -I . gptrixie.p6 --enums --structs --functions path/myheader.h

Try to not copy the header if it use other one.
