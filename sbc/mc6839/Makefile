# Assemble using asm6809
asm6809: quad.asm
	asm6809 -v -S -3 -o quad.s19 -l quad.lst quad.asm

# Assemble using lwasm
lwasm:	quad.asm
	lwasm --6809 --format=srec --list=quad.lst --output=quad.s19 quad.asm

clean:
	$(RM) quad.lst quad.s19

distclean: clean
