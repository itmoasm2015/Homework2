CC=g++
CXXFLAGS=-Wall -Wextra -g -std=c++1y 
OBJ_FILES=matrix.o test.o MyMatrix.o
TARGET=test

$(TARGET): $(OBJ_FILES)
	$(CC) $(CXXFLAGS) $^ -o $@

%.o: %.cpp
	$(CC) $(CXXFLAGS) -c $^ -o $@

%.o: %.asm
	yasm -f elf64 -g dwarf2 -o $@ $^

clean:
	rm -f $(TARGET)
	rm -f *.o
