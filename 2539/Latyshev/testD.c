#include "stdio.h"
#include "matrix.h"
#include "assert.h"
#include "math.h"

#define eps 1e-6

int main() {
	Matrix a = matrixNew(4, 5);
	assert(matrixGetRows(a) == 4);
	assert(matrixGetCols(a) == 5);
	matrixDelete(a);
    assert(matrixGet(a, 0, 0) == 0.0f);
	assert(matrixGet(a, 3, 4) == 0.0f);
	matrixSet(a, 0, 0, 1.0f);
	assert(matrixGet(a, 0, 0) == 1.0f);
	matrixSet(a, 3, 4, 10.0f);
	assert(matrixGet(a, 3, 4) == 10.0f);
	matrixSet(a, 1, 1, 5.0f);
	matrixSet(a, 2, 2, 7.0f);
	Matrix b = matrixCopy(a);
	assert(matrixGet(b, 0, 0) == 1.0f);
	assert(matrixGet(b, 3, 4) == 10.0f);
	assert(matrixGet(b, 1, 1) == 5.0f);
	assert(matrixGet(b, 2, 2) == 7.0f);
	Matrix c = matrixScale(b, 2.0f);
    assert(matrixGet(c, 0, 0) == 2.0f);
	assert(matrixGet(c, 3, 4) == 20.0f);
	assert(matrixGet(c, 1, 1) == 10.0f);
	assert(matrixGet(c, 2, 2) == 14.0f);
	Matrix d = matrixAdd(b, c);
	matrixSet(d, 1, 2, 6.0f);
	assert(matrixGet(d, 0, 0) == 3.0f);
	assert(matrixGet(d, 3, 4) == 30.0f);
	assert(matrixGet(d, 1, 1) == 15.0f);
	assert(matrixGet(d, 2, 2) == 21.0f);
	assert(matrixGet(d, 1, 2) == 6.0f);
	/*Matrix e = matrixTranspose(d);
	assert(matrixGet(e, 0, 0) == 3.0f);
	assert(matrixGet(e, 2, 1) == 6.0f);*/
	Matrix m1 = matrixNew(4, 2);
	matrixSet(m1, 0, 0, 1.0f);
	matrixSet(m1, 0, 1, 2.0f);
	matrixSet(m1, 1, 0, 3.0f);
	matrixSet(m1, 1, 1, 4.0f);
	matrixSet(m1, 2, 0, 5.0f);
	matrixSet(m1, 2, 1, 6.0f);
	matrixSet(m1, 3, 0, 7.0f);
	matrixSet(m1, 3, 1, 8.0f);
	Matrix m2 = matrixNew(2, 3);
	matrixSet(m2, 0, 0, 2.0f);
	matrixSet(m2, 0, 1, 3.0f);
	matrixSet(m2, 0, 2, 5.0f);
	matrixSet(m2, 1, 0, 7.0f);
	matrixSet(m2, 1, 1, 11.0f);
	matrixSet(m2, 1, 2, 13.0f);
	Matrix r = matrixMul(m1, m2);
	assert(matrixGet(r, 0, 0) == 16.0f);
	assert(matrixGet(r, 0, 1) == 25.0f);
	assert(matrixGet(r, 0, 2) == 31.0f);
	assert(matrixGet(r, 1, 0) == 34.0f);
	assert(matrixGet(r, 1, 1) == 53.0f);
	assert(matrixGet(r, 1, 2) == 67.0f);
	assert(matrixGet(r, 2, 0) == 52.0f);
	assert(matrixGet(r, 2, 1) == 81.0f);
	assert(matrixGet(r, 2, 2) == 103.0f);
	assert(matrixGet(r, 3, 0) == 70.0f);
	assert(matrixGet(r, 3, 1) == 109.0f);
	assert(matrixGet(r, 3, 2) == 139.0f);
	matrixDelete(a);
    matrixDelete(r);

}
