CC=g++
CXXFLAGS=-Wall -Wextra -g -std=c++1y
CPP_FILES=MyMatrix.cpp test.cpp
TARGET=test

all: $(CPP_FILES) MyMatrix.hpp
	$(CC) $(CXXFLAGS) $(CPP_FILES) -o $(TARGET)

clean:
	rm -f $(TARGET)
