ASM_FLAGS = -felf64 -gdwarf2
CXX_FLAGS = 

all: tester	

tester: libhw.a tester.o
	g++ -o tester $(CXX_FLAGS) -g -L. -I. tester.o libhw.a

tester.o: tester.cpp
	g++ -o tester.o $(CXX_FLAGS) -c tester.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: matrix.asm
	yasm -o libhw.o $(ASM_FLAGS) matrix.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f tester.o
	rm -f tester
