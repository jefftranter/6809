all: combined.s19

combined.s19: combined.asm
	as9 combined.asm -l s19

clean:
	$(RM) combined.s19 combined.lst

distclean: clean
