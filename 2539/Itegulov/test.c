#include "stdio.h"
#include "matrix.h"
#include "assert.h"
#include "math.h"

#define eps 1e-6

int main() {
	Matrix a = matrixNew(4, 5);
	assert(matrixGetRows(a) == 4);
	assert(matrixGetCols(a) == 5);
	assert(matrixGet(a, 0, 0) == 0.0f);
	assert(matrixGet(a, 3, 4) == 0.0f);
	matrixSet(a, 0, 0, 1.0f);
	assert(matrixGet(a, 0, 0) == 1.0f);
	matrixSet(a, 3, 4, 10.0f);
	assert(matrixGet(a, 3, 4) == 10.0f);
	matrixDelete(a);
}
