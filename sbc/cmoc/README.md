These are some example programs built using the CMOC C compiler.
See https://perso.b2b2c.ca/~sarrazip/dev/cmoc.html

ex1: First example without any i/o. Runs fine from ASSIST09 ("C
$2800"). Return value is in D.

ex2: Second example showing string output and input. Needs to write
custom output and input routines. Does not return from main() -
workaround is just to jump to ASSIST09 RESET at end of main(). All of
the input and output routines seem to work fine, printf() brings in a
lot of code though. Start address is 2800.
