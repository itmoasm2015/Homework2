libhw.a: matrix.o
	ar rcs libhw.a matrix.o
matrix.o: matrix.asm
	yasm -felf64 -gdwarf2 -Werror -o matrix.o matrix.asm
test: libhw.a test.cpp
	g++ -std=c++11 -g -o test test.cpp -I../../include/ -L. -l hw
clean:
	rm -rf *.o *.a test
