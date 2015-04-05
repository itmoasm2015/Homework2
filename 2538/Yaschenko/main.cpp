#include <cstdio>
#include <cmath>
#include <cassert>
#include <cstdlib>

#include "matrix.h"

void print(Matrix m) {
	const int rows = matrixGetRows(m);
	const int cols = matrixGetCols(m);
	for (int i = 0; i < rows; i++) {
		for (int j = 0; j < cols; j++) {
			printf("%.2f ", matrixGet(m, i, j));
		}
		printf("\n");
	}
	printf("\n");
}

bool eq(float x, float y) {
	return fabs(x - y) < 1e-7;
}

void testGetRowsCols(int tests) {
	for (int i = 0; i < tests; i++) {
		const size_t rows = 10 + i * 3;
		const size_t cols = 11 + i * 4;
		Matrix m = matrixNew(rows, cols);
		assert(matrixGetRows(m) == rows);
		assert(matrixGetCols(m) == cols);
		matrixDelete(m);
	}
}

void testElements(int tests) {
	for (int ii = 0; ii < tests; ii++) {
		const size_t rows = 10 + ii * 3;
		const size_t cols = 11 + ii * 4;
		Matrix m = matrixNew(rows, cols);
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				float x = (float)i * rows + j + 1;
				matrixSet(m, i, j, x);
				assert(eq(matrixGet(m, i, j), x));
			}
		}
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				float x = (float)i * rows + j + 1;
				assert(eq(matrixGet(m, i, j), x));
			}
		}

		matrixDelete(m);
	}
}

void testScale(int tests) {
	for (int ii = 0; ii < tests; ii++) {
		const size_t rows = 10 + ii * 3;
		const size_t cols = 11 + ii * 4;
		Matrix m = matrixNew(rows, cols);
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				float x = (float)i * rows + j + 1;
				matrixSet(m, i, j, x);
			}
		}
		Matrix scaled = matrixScale(m, 2.f);
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				float x = (float)i * rows + j + 1;
				assert(eq(x * 2, matrixGet(scaled, i, j)));
			}
		}

		matrixDelete(m);
		matrixDelete(scaled);
	}
}

void testAdd(int tests) {
	for (int ii = 0; ii < tests; ii++) {
		const size_t rows = 10 + ii * 3;
		const size_t cols = 11 + ii * 4;
		Matrix a = matrixNew(rows, cols);
		Matrix b = matrixNew(rows, cols);
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				float x = (float)i * rows + j + 1;
				matrixSet(a, i, j, x);
				matrixSet(b, i, j, x);
			}
		}
		Matrix c = matrixAdd(a, b);
		for (size_t i = 0; i < rows; i++) {
			for (size_t j = 0; j < cols; j++) {
				const float x = matrixGet(a, i, j);
				const float y = matrixGet(b, i, j);
				const float z = matrixGet(c, i, j);
				if (!eq(x + y, z)) {
					printf("%.2f + %.2f != %.2f, expected %.2f\n, diff %.2f", x, y, z, x + y, x + y - z);
				}
				assert(eq(x + y, z));
			}
		}

		matrixDelete(a);
		matrixDelete(b);
		matrixDelete(c);
	}
} 


void testTranspose() {
	const int N = 2;
	const int M = 3;
	Matrix m = matrixNew(N, M);
	
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			float x = (float)i * M + j + 1;
			matrixSet(m, i, j, x);
		}
	}

	print(m);
	Matrix transposed = matrixTranspose(m);
	print(transposed);

	matrixDelete(m);
	matrixDelete(transposed);
}

void testMul() {
	const int N = 2;
	const int M = 3;
	Matrix a = matrixNew(N, M);
	Matrix b = matrixNew(M, N);

	/*
	[1, 2, 3]
	[4, 5, 6]
	*/
	matrixSet(a, 0, 0, 1);
	matrixSet(a, 0, 1, 2);
	matrixSet(a, 0, 2, 3);
	matrixSet(a, 1, 0, 4);
	matrixSet(a, 1, 1, 5);
	matrixSet(a, 1, 2, 6);

	/*
	[2, 1]
	[3, 4]
	[6, 5]
	*/
	matrixSet(b, 0, 0, 2);
	matrixSet(b, 0, 1, 1);
	matrixSet(b, 1, 0, 3);
	matrixSet(b, 1, 1, 4);
	matrixSet(b, 2, 0, 6);
	matrixSet(b, 2, 1, 5);

	Matrix c = matrixMul(a, b);
	print(a);
	print(b);

	/*
	[]
	[]
	*/
	print(c);

	matrixDelete(a);
	matrixDelete(b);
	matrixDelete(c);
}


void testAddSmall() {
	const int N = 3;
	const int M = 3;
	Matrix a = matrixNew(N, M);
	Matrix b = matrixNew(N, M);

	/*
	[1, 2, 3]
	[4, 5, 6]
	[7, 8, 9]
	*/
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			float x = (float)i * M + j + 1;
			matrixSet(a, i, j, x);
			matrixSet(b, i, j, x);
		}
	}

	
	Matrix c = matrixAdd(a, b);
	print(a);
	print(b);

	print(c);

	matrixDelete(a);
	matrixDelete(b);
	matrixDelete(c);
}

void testScaleSmall() {
	const int N = 5;
	const int M = 3;
	Matrix a = matrixNew(N, M);

	/*
	[1, 2, 3]
	[4, 5, 6]
	[7, 8, 9]
	*/
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			float x = (float)i * M + j + 1;
			matrixSet(a, i, j, x);
		}
	}

	
	Matrix scaled = matrixScale(a, 2.f);

	print(scaled);

	matrixDelete(a);
	matrixDelete(scaled);
}



void testAll() {
	testGetRowsCols(20);
	testElements(30);
	testScale(30);
	testAdd(30);
	
	testMul();
	testScaleSmall();
	testAddSmall();
}

int main() {
	testAll();
	return 0;
}