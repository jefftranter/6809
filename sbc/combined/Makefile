all: combined.s19 combined.hex combined.bin

combined.s19: combined.asm
	as9 combined.asm -l s19 now

combined.hex: combined.s19
	srec_cat combined.s19 -Motorola -crop 0xc000 0x10000 -output combined.hex -Intel

combined.bin: combined.s19
	srec_cat combined.s19 -Motorola --crop 0xc000 0x10000 -offset -0xc000 -output combined.bin -Binary

program: combined.bin
	minipro -p 27C128@DIP28 -y -w combined.bin
	minipro -p 27C128@DIP28 -y -m combined.bin

check:
	minipro -p 27C128@DIP28 -y -m combined.bin

clean:
	$(RM) combined.s19 combined.hex combined.bin combined.lst

distclean: clean
