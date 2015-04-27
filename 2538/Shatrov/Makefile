OBJS=matrix.o

OS:=$(shell uname)

ifeq ($(OS), Darwin)
YASM_FLAGS=-f macho64
OBJS+=osx-wrapper.o
else
YASM_FLAGS=-f elf64 -g dwarf2
endif

all: test
test:  test.o $(OBJS) libhw.a
	g++ -O0 -g -m64 $^  -o $@

libhw.a: $(OBJS)
	ar rcs $@ $^

test.o: test.cpp
	g++ -std=c++11 -c -m64 -g -O0 -o $@ $<

%.o: %.asm
	yasm $(YASM_FLAGS) -o $@ $<

clean:
	rm -f test
	rm -f test.o
	rm -f matrix.o
	rm -f osx-wrapper.o
	rm -f libhw.a