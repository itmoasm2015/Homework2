CC = gcc
AR = ar
CC_OPTS = -O2 -I../../include
LD_OPTS =

all: tester

clean:
	rm -f tester
	rm -f tester.o
	rm -f libhw.a
	rm -f cimpl.o

tester: libhw.a tester.o
	$(CC) -o $@ $(LD_OPTS) $^

tester.o: tester.c
	$(CC) -o $@ -c $(CC_OPTS) $^

libhw.a: cimpl.o
	$(AR) rcs $@ $<

cimpl.o: cimpl.c
	$(CC) -o $@ -c $(CC_OPTS) $^
