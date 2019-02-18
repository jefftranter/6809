This is a port of Microsoft Extended BASIC, as used in the Tandy
Color Computer 2, modified for the SBC with all I/O via serial.
See http://searle.hostei.com/grant/6809/Simple6809.html

It can be cross-assembled using the AS9 assembler found at
http://home.hccnet.nl/a.w.m.van.der.horst/m6809.html

Some quirks of this variant of BASIC that differ from some other
version of Microsoft BASIC. This may help in porting programs such as
games.

rnd() function:
rnd(0) returns a random floating point number between 0 and 1. rnd(n) returns an integer between 0 and n. Most BASICs return
a value between 0 and 1 for any argument value.

fre() function:
This is not present, but you can use the pseudo-variable MEM instead to report the amount of free memory.
