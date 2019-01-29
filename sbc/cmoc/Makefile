all:	ex1.srec ex2.srec

ex1.srec: ex1.c
	cmoc -i --coco --srec ex1.c 

ex2.srec: ex2.c
	cmoc -i --coco --srec ex2.c 

upload1: ex1.srec
	ascii-xfr -s ex1.srec -l 100 -c 10 >/dev/ttyUSB0

upload2: ex2.srec
	ascii-xfr -s ex2.srec -l 100 -c 10 >/dev/ttyUSB0

clean:
	$(RM) ex1.srec ex1.s ex1.o ex1.lst ex1.link ex1.map
	$(RM) ex2.srec ex2.s ex2.o ex2.lst ex2.link ex2.map
