#include <stdio.h>
#include "matrix.h"
#include <math.h>

int main() {
	
	Matrix m = matrixNew(2, 2);
	matrixSet(m, 0, 0, 3.4);
	printf("LOL%f", matrixGet(m, 0, 0));
	matrixDelete(m);
	
	return 0;
}
