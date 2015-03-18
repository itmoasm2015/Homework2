CC = g++
ASM = yasm
AR = ar
CXX_FLAGS = -std=c++11 -m64 -L. -I../../include -g
LD_FLAGS = -L. -lgmp -lgmpxx -lpthread -lboost_math_tr1 -lhw
ASM_FLAGS = -f elf64 -g dwarf2
GTEST = gtest/gtest-all.cc gtest/gtest.h gtest/gtest_main.cc

all: libhw.a clean_obj

libhw.a: libhw.o
	$(AR) rcs libhw.a libhw.o

libhw.o: hwmatrices.asm
	$(ASM) -o libhw.o $(ASM_FLAGS) hwmatrices.asm

test: libhw.a
	$(CC) -o test $(CXX_FLAGS) test.cpp $(GTEST) $(LD_FLAGS)

clean_obj:
	rm -rf *.o

clean:
	rm -rf *.o
	rm -rf libhw.a
	rm -rf test
