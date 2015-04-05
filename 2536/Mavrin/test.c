#include <stdio.h>
#include "matrix.h"
#include <math.h>

float random(int i, int j, int param) {
	return i * 15 ^ param + (j % (i + 1)) + j * 3 ^ param;
}

void printMatrix(Matrix c) {
for (int i = 0; i < (int)matrixGetRows(c); i++) {
		for (int j = 0 ;j < (int)matrixGetCols(c); j++) {
			float r = matrixGet(c, i, j);
			printf("%f ", r);
		}
		printf("\n");
	}
printf("\n");
}

Matrix randomMatrix(int rows, int cols, int param) {
	Matrix a = matrixNew(rows, cols);
	for(int i = 0; i < rows; i++)
	for(int j = 0; j < cols; j++) {
		matrixSet(a, i, j, random(i, j, param));
	}
	return a;
}

int main() {
	Matrix a = randomMatrix(2, 2, 1);
	
	
	Matrix b = randomMatrix(2, 2, 7);
	Matrix c = matrixScale(a, 2.22);
	
	printMatrix(a);
	printMatrix(b);
	printMatrix(c);
	float z = matrixGet(a, 0, 0);
	printf("%f \n", z);
	
return 0;
}


