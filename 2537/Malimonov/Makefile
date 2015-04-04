all: libhw.a

clean:
		rm -f libhw.a
		rm -f matrix.o

libhw.a: matrix.o
		ar rcs $@ $<

matrix.o: matrix.asm
		yasm -o $@ -g dwarfd -f elf64 $^
