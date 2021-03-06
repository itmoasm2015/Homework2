#include "matrix.h"
#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>

int main(int argc, char* argv [])
{
	void* matrix = matrixNew(1234,5678);
	unsigned long long rows = *((unsigned long long*)matrix);
	unsigned long long cols = *((unsigned long long*)matrix + 1);
	printf("%d %d\n", rows, cols);
	rows = matrixGetRows(matrix);
	cols = matrixGetCols(matrix);
	printf("%d %d\n", rows, cols);
	float matrixElement = matrixGet(matrix, 1234, 300);
	printf("%f\n", matrixElement);
	matrixSet(matrix,1234,5677,5.43);
	matrixElement = matrixGet(matrix, 1234, 5676);
	printf("%f\n", matrixElement);
	matrixElement = matrixGet(matrix, 1234, 5677);
	printf("%f\n", matrixElement);
	matrixElement = matrixGet(matrix, 1234, 5678);
	printf("%f\n", matrixElement);
	void* matrixScaled  = matrixScale(matrix, 2.1);
	matrixElement = matrixGet(matrixScaled, 1234, 5677);
	printf("%f\n", matrixElement);
	
}
#ifdef __cplusplus
}
#endif
