all:	ex1.srec ex2.srec

ex1.srec: ex1.c
	cmoc -i --coco --srec ex1.c 

ex2.srec: ex2.c
	cmoc -i --coco --srec ex2.c 

clean:
	$(RM) ex1.srec ex1.s ex1.o ex1.lst ex1.link ex1.map
	$(RM) ex2.srec ex2.s ex2.o ex2.lst ex2.link ex2.map
