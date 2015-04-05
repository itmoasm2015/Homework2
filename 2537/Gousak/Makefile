ASM = yasm
AR = ar
ASM_OPTS = -f elf64 -gdwarf2

all: libhw.a

clean:
	rm -f libhw.a
	rm -f matrix.o
	
libhw.a: matrix.o
	$(AR) rcs $@ $<

matrix.o: matrix.asm
	$(ASM) -o $@ $(ASM_OPTS) $^

