ASM_FLAGS = -felf64 -g dwarf2

all: libhw.a

libhw.a: matrix.o
	ar rcs libhw.a matrix.o

matrix.o: matrix.asm
	yasm -o matrix.o $(ASM_FLAGS) matrix.asm

clean:
	rm -f libhw.a
	rm -f matrix.o