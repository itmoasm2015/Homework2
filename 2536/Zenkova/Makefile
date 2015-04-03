ASMC=yasm
CC=gcc
ASM_FLAGS=-felf64 -gdwarf2
CXX_FLAGS=-std=c11 -g -L. -I.

all: test

clean:
	rm -f libhw.a
	rm -f hw.o
	rm -f test

test: libhw.a
	$(CC) -o $< $(CXX_FLAGS) $@ -lhw

libhw.a: hw.o
	ar rcs $< $@

hw.o: matrix.asm
	$(ASMC) -o $< $(ASM_FLAGS) $@
