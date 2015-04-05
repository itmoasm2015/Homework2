all: libhw.a

run: test
	./test


test: libhw.a test.c
	gcc -o test -std=c99 -g -L. -I. test.c libhw.a

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: libhw.asm
	yasm -o libhw.o -felf64 -gdwarf2 libhw.asm
