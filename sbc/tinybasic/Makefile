all:	tinybasic.s19

tinybasic.s19: tinybasic.asm
	as9 tinybasic.asm -l s19 now

clean:
	$(RM) tinybasic.lst tinybasic.s19

distclean: clean
