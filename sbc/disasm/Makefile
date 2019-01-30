all: disasm.s19

disasm.s19: disasm.asm
	as9 disasm.asm -l s19

upload: disasm.s19
	sleep 5 ; ascii-xfr -s disasm.s19 -l 100 -c 10 >/dev/ttyUSB0

clean:
	$(RM) disasm.s19 disasm.lst

distclean: clean
