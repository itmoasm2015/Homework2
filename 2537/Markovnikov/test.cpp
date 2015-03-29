#include <stdio.h>
#include <cstdlib>
#include <climits>
#include "matrix.h"

int get_random_int(int l, int r) {
	return rand() % r + l;
}

#define TEST(test)	if (test()) \
											printf("%s %s", #test, "OK"); \
										else \
											printf("%s %s", #test, "FAILED"); \

bool test_matrix_new() {
	Matrix a;
	unsigned int n = get_random_int(1, 1000);
	unsigned int m = get_random_int(1, 1000);
	a = matrixNew(n, m);
	matrixDelete(a);
	return true;
}

bool test_matrix_get_sizes() {
	Matrix a;
	unsigned int n = get_random_int(1, 1000);
	unsigned int m = get_random_int(1, 1000);
	a = matrixNew(n, m);
	unsigned int nn = matrixGetRows(a);
	unsigned int mm = matrixGetCols(a);
	matrixDelete(a);
	return (n == nn & m == mm);
}

int main() {
	TEST(test_matrix_new);
	TEST(test_matrix_get_sizes);
//  Matrix a;
//	a = matrixNew(256, 1025);
	return 0;
}
