all: mond09.s19

mond09.s19: mond09.asm
	as9 mond09.asm -l s19 now

upload: mond09.s19
	ascii-xfr -s mond09.s19 -l 1 -c 1 >/dev/ttyUSB0

clean:
	$(RM) mond09.s19 mond09.lst

distclean: clean
