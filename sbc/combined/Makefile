all: combined.s19 combined.hex combined.bin

combined.s19: combined.asm
	as9 combined.asm -l s19 now

combined.hex: combined.s19
	srec_cat combined.s19 -Motorola -crop 0xc000 0x10000 -output combined.hex -Intel

combined.bin: combined.s19
	srec_cat combined.s19 -Motorola --crop 0xc000 0x10000 -offset -0xc000 -output combined.bin -Binary

clean:
	$(RM) combined.s19 combined.hex combined.bin combined.lst

distclean: clean
