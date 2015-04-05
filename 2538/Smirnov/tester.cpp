#include "matrix.h"
#include <cstdio>
#include <iostream>
#include <stdlib.h>

using namespace std;

Matrix a, b, c;

const int N = 5;

void init() {
	a = matrixNew(N, N);
	b = matrixNew(N, N);
	cout << matrixGetRows(a) << ' ' ;
	cout << matrixGetCols(a) << endl;
}
void print() {
	cout << "---------------------------------" << endl;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++)
			printf("%f ", matrixGet(a, i, j));
		cout << endl;
	}
	cout << "---------------------------------" << endl;
}


void test1() {	
	for (size_t i = 0; i < N; i++)
		for (size_t j = 0; j < N; j++)
			matrixSet(a, i, j, 2);
	for (size_t i = 0; i < N; i++)
		for (size_t j = 0; j < N; j++)
			matrixSet(b, i, j, 1);
	print();
}

void test2() {	
	c =  matrixMul(a, b);
	a = c;
	print();
}


int main() {	
	init();		

	test1();
	test2();

	return 0;
}