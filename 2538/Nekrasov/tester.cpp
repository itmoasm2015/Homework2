#include <iostream>
#include <matrix.h>

#define SIZE1 3
#define SIZE2 3

using namespace std;

int main()
{
	Matrix matrix1 = matrixNew(SIZE1, SIZE2);
	Matrix matrix2 = matrixNew(SIZE2, SIZE1);

	for (int i = 0; i < SIZE1; ++i) {
		for (int j = 0; j < SIZE2; ++j) {
			matrixSet(matrix1, i, j, 10 * i + j);
			matrixSet(matrix2, j, i, 10 * j + i);
		}
	}

	Matrix matrix3 = matrixMul(matrix1, matrix2);

	for (int i = 0; i < SIZE1; ++i) {
		for (int j = 0; j < SIZE2; ++j) {
			printf("%f ", matrixGet(matrix1, i, j));
		}
		printf("\n");
	}
	printf("\n");

	for (int i = 0; i < SIZE2; ++i) {
		for (int j = 0; j < SIZE1; ++j) {
			printf("%f ", matrixGet(matrix2, i, j));
		}
		printf("\n");
	}
	printf("\n");

	for (int i = 0; i < SIZE1; ++i) {
		for (int j = 0; j < SIZE1; ++j) {
			printf("%f ", matrixGet(matrix3, i, j));
		}
		printf("\n");
	}
	printf("\n");

	/*for (int i = 0; i < SIZE1; ++i) {
		for (int j = 0; j < SIZE2; ++j) {
			printf("%f ", matrixGet(matrix4, i, j));
		}
		printf("\n");
	}
	printf("\n");*/

	return 0;
}
