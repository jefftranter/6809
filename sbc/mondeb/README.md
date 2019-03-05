This is a port of the MONDEB monitor debugger, written by Don Peters
and described in the book "MONDEB, An Advanced M6800 Monitor
Debugger", to the 6809 processor.

The original 6800 version is available here: https://github.com/jefftranter/6800/tree/master/mondeb

To use the code or port it to another computer, you will want to
obtain a copy of the book.

Porting notes:
- Converted to 6809 mnemonics.
- Added support for additional registers (Y, DP, U).
- Changed address of ACIA to match my board.
- Removed output of nulls.
