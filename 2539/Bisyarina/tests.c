#include <stdio.h>
#include "matrix.h"
#include <math.h>

int main() {
	
	Matrix m = matrixNew(3, 5);
	matrixSet(m, 0, 0, 1);
	matrixSet(m, 0, 1, 2);
	matrixSet(m, 0, 2, 3);
	matrixSet(m, 1, 0, 4);
	matrixSet(m, 1, 1, 5);
	matrixSet(m, 1, 2, 6);
	matrixSet(m, 2, 0, 7);
	matrixSet(m, 2, 1, 8);
	matrixSet(m, 2, 2, 9);
	matrixSet(m, 2, 4, 9999.9);
	
	Matrix m2 = matrixScale(m, 2);
	Matrix m3 = matrixScale(m2, 3);
	
	int i, j;
	printf("%d %d\n", matrixGetRows(m), matrixGetCols(m));
	printf ("\n");
	for (i = 0; i < 3; i++){
		for (j = 0; j < 5; j++) {
			printf ("%f ", matrixGet(m, i, j));
		}
		printf ("\n");
	}
	
	printf ("\n");
	printf ("\n");
	printf("%d %d\n", matrixGetRows(m2), matrixGetCols(m2));
	printf ("\n");
    for (i = 0; i < 3; i++){
		for (j = 0; j < 5; j++) {
			printf ("%f ", matrixGet(m2, i, j));
		}
		printf ("\n");
	}
    
	printf ("\n");
	printf ("\n");
	printf("%d %d\n", matrixGetRows(m3), matrixGetCols(m3));
	printf ("\n");
    for (i = 0; i < 3; i++){
		for (j = 0; j < 5; j++) {
			printf ("%f ", matrixGet(m3, i, j));
		}
		printf ("\n");
	}
		
	matrixDelete(m2);
	matrixDelete(m3);
	
	matrixDelete(m);
	return 0;
}
