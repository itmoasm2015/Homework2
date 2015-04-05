#include "matrix.h"
#include <stdio.h>
	
int test(int a, int b) {
	return a + b;
}


void printMatrix(Matrix c) {
	printf("%s", "PRINTING MATRIX : ");
	printf("%d x %d\n", matrixGetRows(c), matrixGetCols(c));
	for (int i = 0; i < matrixGetRows(c); i++) {
		for (int j = 0; j < matrixGetCols(c); j++) {
			printf("%f ", matrixGet(c, i, j));		
		}
		printf("\n");
	}
	printf("%s\n", "-------------");	
}


int main(int argc, char const *argv[])
{

	Matrix a = matrixNew(555555, 2);
	Matrix b = matrixNew(2, 555555);
	//Matrix b = matrixNew(100, 100);
	for (int i = 0; i < matrixGetRows(a); i++) {
		for (int j = 0; j < matrixGetCols(a); j++) {
			//printf("%d ", (i + 5));		
			matrixSet(a, i, j, (float) (i + 5));		
		}
	//	printf("\n");
	}
	for (int i = 0; i < matrixGetRows(b); i++) {
		for (int j = 0; j < matrixGetCols(b); j++) {
			matrixSet(b, i, j, (float) 1.);		
		}
	}
	//printMatrix(a);
	//printMatrix(b);
	Matrix c = matrixMul(a, b);
	//Matrix c = matrixNew(9, 13);
	//printf("\n%d\n-----", (int) c);
	printMatrix(c);	
	return 0;
}
