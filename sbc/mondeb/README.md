This is a port of the MONDEB monitor debugger, written by Don Peters
and described in the book "MONDEB, An Advanced M6800 Monitor
Debugger", to the 6809 processor.

The original 6800 version is available here: https://github.com/jefftranter/6800/tree/master/mondeb

For full functionality (e.g. setting interrupt vectors), you can burn
it into an EPROM and run it standalone. It can also be assembled and
loaded into RAM (e.g. from ASSIST09) for test purposes.

To use the code or port it to another computer, you will want to
obtain a copy of the book.

Porting notes:
- Converted to 6809 mnemonics.
- Added support for additional registers (Y, DP, U).
- Changed address of ACIA to match my board.
- Removed output of nulls.
- Added some additional bug fixes and commands based on a 6809 version
  written by Alan R. Baldwin.

------------------------------------------------------------------------

Command Summary

HELP
REG
SET <address> <value> [<value>...]
SET <address range> <value>
SET .<register> <value>
DISPLAY <address range> [DATA|USED]
DBASE [?|HEX|DEC|OCT|BIN]
IBASE [?|HEX|DEC|OCT]
GOTO [>address>]
BREAK [?|<addess>]
CONTINUE
TEST <address range>
VERIFY [ <address range>]
SEARCH <address range> <value> [<value>...]
COPY <address range> <address>
COMPARE <value1> <value2>
DUMP <address range> [TO <address>]
LOAD [FROM <address>]
DELAY <value>
FIRQ <address>
INT <address>
NMI <address>
SWI <address>
SWI2 <address>
SWI3 <address>
RSRVD <address>
SEI
CLI
SEF
CLF
