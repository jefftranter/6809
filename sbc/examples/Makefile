all: ex1.s19 ex2.s19 ex3.s19

ex1.s19: ex1.asm
	as9 ex1.asm -l s19

ex2.s19: ex2.asm
	as9 ex2.asm -l s19

ex3.s19: ex3.asm
	as9 ex3.asm -l s19

upload1: ex1.s19
	ascii-xfr -s ex1.s19 -l 1 -c 1 >/dev/ttyUSB0

upload2: ex2.s19
	ascii-xfr -s ex2.s19 -l 1 -c 1 >/dev/ttyUSB0

upload3: ex3.s19
	ascii-xfr -s ex3.s19 -l 1 -c 1 >/dev/ttyUSB0

clean:
	$(RM) ex1.s19 ex1.lst
	$(RM) ex2.s19 ex2.lst
	$(RM) ex3.s19 ex3.lst

distclean: clean
