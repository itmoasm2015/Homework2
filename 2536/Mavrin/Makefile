ASM_FLAGS = -felf64 -gdwarf2
CXX_FLAGS = -std=c11 -g -L. -I.
all: test
clean:
	rm -f libhw.a
	rm -f hw.o
	rm -f test
test: libhw.a
	gcc -o test $(CXX_FLAGS) test.c -lhw
libhw.a: hw.o
	ar rcs libhw.a hw.o
hw.o:
	yasm -o hw.o $(ASM_FLAGS) matrix.asm
