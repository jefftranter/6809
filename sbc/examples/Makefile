all: ex1.s19

ex1.s19: ex1.asm
	as9 ex1.asm -l s19

upload: ex1.s19
	sleep 5 ; ascii-xfr -s ex1.s19 -l 100 -c 10 >/dev/ttyUSB0

clean:
	$(RM) ex1.s19 ex1.lst

distclean: clean
