CC = gcc
AR = ar
CC_OPTS = -Wall -Wextra -std=c99 -m32 -O2 -L. -I../../include

all: tester

clean:
	rm -f tester
	rm -f tester.o
	rm -f libhw.a
	rm -f cimpl.o

tester: libhw.a tester.o
	$(CC) -o $@ $(CC_OPTS) tester.o -lhw

tester.o: tester.c
	$(CC) -o $@ -c $(CC_OPTS) $^

libhw.a: cimpl.o
	$(AR) rcs $@ $<

cimpl.o: cimpl.c
	$(CC) -o $@ -c $(CC_OPTS) $^
