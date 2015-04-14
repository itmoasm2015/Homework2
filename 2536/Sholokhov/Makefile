CC = gcc
ASM = yasm
AR = ar
CC_OPTS = -Wall -Wextra -std=c99 -m64 -O2 -L. -I../../include
ASM_OPTS = -f elf64

all: libhw.a

libhw.a: asmimpl.o
	$(AR) rcs $@ $<

asmimpl.o: asmimpl.asm
	$(ASM) -o $@ $(ASM_OPTS) $^

