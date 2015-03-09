CC = gcc
ASM = yasm
AR = ar
CC_OPTS = -Wall -Wextra -std=c99 -m64 -O2 -L. -I../../include
ASM_OPTS = -f elf64

all: tester

clean:
	rm -f tester
	rm -f tester.o
	rm -f libhw.a
	rm -f asmimpl.o
	rm -f cimpl.o

tester: libhw.a tester.o cimpl.o
	$(CC) -o $@ $(CC_OPTS) tester.o cimpl.o -lhw

tester.o: tester.c
	$(CC) -o $@ -c $(CC_OPTS) $^

libhw.a: asmimpl.o
	$(AR) rcs $@ $<

asmimpl.o: asmimpl.asm
	$(ASM) -o $@ $(ASM_OPTS) $^

cimpl.o: cimpl.c
	$(CC) -o $@ -c $(CC_OPTS) $^
