all: ar

ar: asm
	ar rcs libhw.a matrix.o

asm: matrix.asm
	yasm -felf64 -gdwarf2 matrix.asm

clean:
	rm libhw.a
	rm *.o
