all: libhw.a

libhw.a: hw2.o
	ar rcs libhw.a hw2.o

hw2.o: hw2.asm
	nasm -f elf64 hw2.asm

clean: 
	-rm hw2.o libhw.a

test: test.c hw2.o
	gcc -o test test.c hw2.o -g
