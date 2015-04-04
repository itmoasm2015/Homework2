ASM_FLAGS = -g dwarf2 -f elf64
C_FLAGS = -std=gnu11 -m64 -L. -g -I../../include

all: libhw.a

clean:
	rm -f *.a *.o

test: libhw.a test.o
	gcc -o test $(C_FLAGS) test.o -lhw

test.o: test.c
	gcc -o test.o $(C_FLAGS) -c test.c

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: matrix.asm
	yasm -o libhw.o $(ASM_FLAGS) matrix.asm
