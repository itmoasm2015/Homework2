makeall: clean test
#makeall: clean libhw.a

test: test.o libhw.a
	gcc -Wall -msse -g -std=c99 -o $@ $^ 
	./test

test.o:
	gcc test.c -Wall -g -std=c99 -c -o $@

libhw.a: matrix.o
	ar rcs $@ $^

matrix.o: 
	yasm -felf64 -gdwarf2 matrix.asm -o $@

clean:
	rm -f test
	rm -f test.o
	rm -f libhw.a
	rm -f matrix.o

