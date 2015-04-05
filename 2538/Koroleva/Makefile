all:	
	yasm -o hw2.o -gdwarf2 -f elf64 hw2.asm
	ar rcs libhw.a hw2.o
#	gcc -o test -std=c11 -g -L. test.c -lhw

clean:
	rm -f hw2.o libhw.a
