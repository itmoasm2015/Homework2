all: libhw.a

libhw.a: libhw.o
		ar rcs libhw.a libhw.o

libhw.o: matrix.asm
		yasm -o libhw.o -f elf64 matrix.asm

clean:
		rm -f libhw.a
		rm -f libhw.o
