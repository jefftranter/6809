all: assist09-orig.s19

assist09-orig.s19: assist09-orig.asm
	as9 assist09-orig.asm -l s19

assist09-6522.s19: assist09-6522.asm
	as9 assist09-6522.asm -l s19

clean:
	$(RM) assist09-orig.s19 assist09-orig.lst
	$(RM) assist09-6522.s19 assist09-6522.lst

distclean: clean
