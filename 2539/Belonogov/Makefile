CFLAGS=-g 
CXXFLAGS=-g -std=c++11 -fsanitize=address
YASM=yasm
YFLAGS=-f elf64 -g dwarf2
AR=ar rcs


all: test lib


test: test.o hw_matrix.o
	g++ $(CXXFLAGS) -o $@ $^

%.o: %.asm
	yasm -f elf64 -g dwarf2 -o $@ $^ 

lib: hw_matrix.o
	$(AR) libhw.a $^

clean:
	rm -f *.o *.a test


