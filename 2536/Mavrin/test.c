#include <stdio.h>
#include "matrix.h"
#include <math.h>

int main() {
	Matrix a = matrixNew(2, 2);
	matrixSet(a, 0, 0, 2.0);
	matrixSet(a, 0, 1, 3.0);
	matrixSet(a, 1, 0, 1.0);
	matrixSet(a, 1, 1, 5.0);
	Matrix b = matrixNew(2, 2);
	matrixSet(b, 0, 0, 2.0);
	matrixSet(b, 0, 1, 3.0);
	matrixSet(b, 1, 0, 1.0);
	matrixSet(b, 1, 1, 5.0);
	Matrix c = matrixAdd(a, b);
	for (int i = 0; i < (int)matrixGetRows(c); i++) {
		for (int j = 0 ;j < (int)matrixGetCols(c); j++) {
			float r = matrixGet(c, i, j);
			printf("%f\n", r);
		}
	}
return 0;
}
