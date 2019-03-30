This is a variant of firmware that combines both Microsoft BASIC and
the ASSIST09 monitor into one ROM. It also includes my disassembler
which adds a new monitor U command and trace function which adds a new
monitor T command.

It comes up in ASSIST09. You can start BASIC by running "G C000".

Memory map (16K EPROM):

BASIC         $C000 - $E3FF (9K)
DISASSEMBLER  $E400 - $EFFF (3K)
TRACE         $F000 - $F8FF (2K)
ASSIST09      $F800 - $FFFF (2K)

RAM usage:

BASIC         $0000 - $0178
DISASSEMBLER  $6FD0 - $6FDC
TRACE         $6FE0 - $6FFC
ASSIST09      $7000 - $7051
