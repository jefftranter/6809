This is a variant of firmware that combines both Microsoft BASIC and
the ASSIST09 monitor into one ROM.

It comes up in ASSIST09. You can start BASIC by running "G D000".

Memory map (16K EPROM):

UNUSED    $C000 - $CFFF (4K)
BASIC     $D000 - $F7FF (10K)
ASSIST09  $F800 - $FFFF (2K)
