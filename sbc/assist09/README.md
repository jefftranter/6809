This is the source for the Motorola ASSIST09 machine language monitor provided for their development boards. There are several versions here:

assist09-orig.asm - The original version that used a 6820 PIA for serial i/o and breakpoints and ran on a Motorola development board.

assist09-6522.asm - A version that was ported by A VD Horst to run on a system using a 6522 VIA.

assist09-6850.asm - My port that runs on my single board computer that uses a 6850 ACIA.

The files will assemble with the as9 assembler found at http://home.hccnet.nl/a.w.m.van.der.horst/m6809.html
