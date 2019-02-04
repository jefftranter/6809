all: disasm.s19

disasm.s19: disasm.asm
	as9 disasm.asm -l s19 now

upload: disasm.s19
	ascii-xfr -s disasm.s19 -l 1 -c 1 >/dev/ttyUSB0

clean:
	$(RM) disasm.s19 disasm.lst

distclean: clean
