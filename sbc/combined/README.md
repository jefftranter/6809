This is a variant of firmware that combines both Microsoft BASIC and
the ASSIST09 monitor into one ROM. It also includes my disassembler
which adds a new monitor U command.

It comes up in ASSIST09. You can start BASIC by running "G D000".

Memory map (16K EPROM):

DISASSEMBLER  $C000 - $CFFF (4K)
BASIC         $D000 - $F7FF (10K)
ASSIST09      $F800 - $FFFF (2K)

ASSIST09 uses RAM starting at $7000.
