ASM = yasm
AR = ar
ASM_OPTS = -g dwarf2 -f elf64

all: libhw.a

clean:
	rm -f libhw.a
	rm -f matrix.o

libhw.a: matrix.o
	$(AR) rcs $@ $<

matrix.o: matrix.asm
	$(ASM) -o $@ $(ASM_OPTS) $^
