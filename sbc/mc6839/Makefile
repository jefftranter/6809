quad.run: quad.asm
	lwasm --6809 --format=srec --list=quad.lst --output=quad.run quad.asm

clean:
	$(RM) quad.lst quad.run

upload1: bin/float09.s19
	ascii-xfr -s bin/float09.s19 -l 1 -c 1 >/dev/ttyUSB0

upload2: quad.run
	ascii-xfr -s quad.run -l 1 -c 1 >/dev/ttyUSB0

distclean: clean
