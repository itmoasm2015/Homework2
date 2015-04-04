ASM = yasm
ASFLAGS = -f elf64

CFLAGS = -Wall -I../../include -L.

all: main


debug: CFLAGS += -g
debug: ASFLAGS += -g dwarf2
debug: main


clean:
	rm -f libhw.o
	rm -f libhw.a
	rm -f main.o
	rm -f main 

main: libhw.a main.o
	$(CC) $(CFLAGS) -o main main.o -lhw

main.o: main.cpp
	$(CC) $(CFLAGS) -c main.cpp -o main.o

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: libhw.asm
	$(ASM) $(ASFLAGS) libhw.asm -o libhw.o 
