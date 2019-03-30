default: asm6809

# Assemble using asm6809
asm6809: example1.s
	asm6809 -v -S -3 -o example1.s19 -l example1.lst example1.s

# Assemble using lwasm
lwasm:	example1.s
	lwasm --6309 --format=srec --list=example1.lst --output=example1.s19 example1.s

clean:
	$(RM) example1.lst example1.s19

distclean: clean
