ASM_FLAGS = -felf64 -gdwarf2
CXX_FLAGS = -std=c++11 -g -L.
all: libhw.a 

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: hw2.asm
	yasm -o hw.o $(ASM_FLAGS) hw2.asm

clean :
	rm -f hw.o libhw.a
