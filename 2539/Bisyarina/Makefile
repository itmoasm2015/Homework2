CC = gcc
ASM = yasm
AR = ar

CFLAGS = -Wall -Wextra -std=c99 -m64 -O2 -L. -I.
ASMFLAGS = -f elf64

RM = rm -f

LIB = libhw.a
TARGET = tests
C_SRS = tests.c
ASM_SRS = matrix.s
OBJ = matrix.o tests.o

all: $(TARGET)

clean:
	$(RM) $(TARGET) $(LIB) $(OBJ)

$(TARGET): $(LIB) tests.o
	$(CC) -o $@ $(CFLAGS) tests.o -lhw

tests.o: tests.c
	$(CC) -o $@ -c $(CFLAGS) $^

$(LIB): matrix.o
	$(AR) rcs $@ $<

matrix.o: matrix.s
	$(ASM) -o $@ $(ASMFLAGS) $^
