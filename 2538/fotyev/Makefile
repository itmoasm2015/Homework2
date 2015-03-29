
ASRC:=$(wildcard *.asm)
CSRC:=$(wildcard *.c)
CXXSRC:=$(wildcard *.cpp)

AOBJ:=$(ASRC:%.asm=obja/%.o)
COBJ:=$(CSRC:%.c=objc/%.o)
CXXOBJ:=$(CXXSRC:%.cpp=objcxx/%.o)

.PHONY: all clean
all: libhw.a 

clean:
	-rm $(AOBJ) $(COBJ) $(CXXOBJ)  main libhw.a

objc objcxx obja:
	-mkdir $@


objc/%.o: %.c objc
	gcc -std=c11 -c -m64 -g -O2 -o $@ $<
objcxx/%.o: %.cpp objcxx
	g++ -std=c++11 -c -m64 -g -O2 -o $@ $<

obja/%.o: %.asm obja
	yasm -f elf64 -g dwarf2 -o $@ $<

libhw.a: $(AOBJ)
	ar rcs $@ $^

main:  $(COBJ) $(CXXOBJ) libhw.a
	g++ -O2 -g -m64 $^  -o $@
