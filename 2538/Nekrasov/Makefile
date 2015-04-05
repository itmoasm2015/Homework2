CC = g++
CFLAGS = -Wall -O2 -Wextra -std=c++11 -m64 -L. -I. -g

all: tester

tester: libmatrix.a tester.o
	$(CC) $(CFLAGS) tester.o -o $@ -lmatrix

tester.o: tester.cpp
	$(CC) -c $(CFLAGS) $< -o $@

libmatrix.a: matrix.o
	ar rcs $@ $<

matrix.o: matrix.asm
	yasm $< -g dwarf2 -f elf64 -o $@

clean:
	rm -f matrix.o
	rm -f libmatrix.a
	rm -f tester.o
	rm -f tester
