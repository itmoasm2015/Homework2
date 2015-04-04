ASM_FLAGS = -felf64 -gdwarf2

all: libhw.a

clean:
	rm -f libhw.a
	rm -f hw.o

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: matrix.asm
	yasm -o hw.o $(ASM_FLAGS) matrix.asm
