# Assemble using lwasm
lwasm:	quad.asm
	lwasm --6809 --format=srec --list=quad.lst --output=quad.run quad.asm

clean:
	$(RM) quad.lst quad.run

distclean: clean
