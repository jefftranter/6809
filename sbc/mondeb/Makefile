all: mondeb.s19

mondeb.s19: mondeb.asm
	as9 mondeb.asm -l s19 now

clean:
	$(RM) mondeb.s19 mondeb.lst

distclean: clean
