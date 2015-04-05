ASM_FLAGS = -felf64 -gdwarf2
CXX_FLAGS = -std=c++11 -g -L. -I.

all: test2 test

clean:
	rm -f libhw.a
	rm -f hw.o
	rm -f test

test2:
	make clean

test: libhw.a
	g++ -g -o test $(CXX_FLAGS) main.cpp -lhw

libhw.a: hw.o
	ar rcs libhw.a hw.o
hw.o:
	yasm -o hw.o $(ASM_FLAGS) matrix.asm
