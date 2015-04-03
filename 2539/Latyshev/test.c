#include <stdio.h>
#include "matrix.h"
#include <math.h>

#define EPS 0.001

int matrixEquals(Matrix a, Matrix b) {
	if(matrixGetRows(a) != matrixGetRows(b))
		return 0;
	
	if(matrixGetCols(a) != matrixGetCols(b))
		return 0;
	
	for(int i = 0; i < matrixGetRows(a); i++)
		for(int j = 0; j < matrixGetCols(a); j++)
			if((matrixGet(a, i, j) - matrixGet(b, i, j)) > EPS)
				return 0;
	
	return 1;
}

float random(int i, int j, int param) {
	return i * 15 ^ param + (j % (i + 1)) + j * 3 ^ param;
}

int testCreation(int rows, int cols) {
	Matrix a = matrixNew(rows, cols);
	Matrix b = matrixScale(a, 0.0f);
	
	int rv = matrixEquals(a, b) * (matrixGetRows(a) == rows) * (matrixGetCols(a) == cols);
	
	matrixDelete(a);
	matrixDelete(b);
	
	return rv;
}

Matrix randomMatrix(int rows, int cols, int param) {
	Matrix a = matrixNew(rows, cols);
	for(int i = 0; i < rows; i++)
		for(int j = 0; j < cols; j++) {
			matrixSet(a, i, j, random(i, j, param));
		}
	return a;
}

int testScale(int rows, int cols) {
	Matrix a = randomMatrix(rows, cols, 1);
	float f = random(rows * cols, rows + cols, 2);
	Matrix b = matrixScale(a, f);
	int result = 1;
	for(int i = 0; i < rows; i++)
		for(int j = 0; j < cols; j++) {
			result *= (fabs(matrixGet(b, i, j) - matrixGet(a, i, j) * f) < EPS);
		}
	matrixDelete(a);
	matrixDelete(b);
	return result;
}

int testAddition(int rows, int cols) {
	Matrix a = randomMatrix(rows, cols, 1);
	Matrix b = randomMatrix(rows, cols, 2);
	Matrix c = matrixAdd(a, b);
	int result = 1;
	for(int i = 0; i < rows; i++)
		for(int j = 0; j < cols; j++) {
			result *= (fabs(matrixGet(a, i, j) + matrixGet(b, i, j) - matrixGet(c, i, j)) < EPS);
		}
	matrixDelete(a);
	matrixDelete(b);
	matrixDelete(c);
	return result;
}

int testMul(int rows, int cols) {
	Matrix a = randomMatrix(rows, cols, 1);
	Matrix b = randomMatrix(cols, rows, 2);
	
	int result = 1;
	
	Matrix c = matrixMul(a, a);
	if(c != 0) {
		result = (rows == cols);
		matrixDelete(c); // uh
	}
	
	c = matrixMul(a, b);
	if(c == 0)
		result = 0;
	else {
		for(int i = 0; i < rows; i++)
			for(int j = 0; j < rows; j++) {
				float sum = 0.0f;
				for(int k = 0; k < cols; k++) {
					sum += matrixGet(a, i, k) * matrixGet(b, k, j);
				}
				result *= ((matrixGet(c, i, j) - sum) < EPS);
			}
	}
	
	matrixDelete(a);
	matrixDelete(b);
	matrixDelete(c);
	
	return result;
}

int testZeroMul(int rows, int cols) {
	Matrix a = matrixNew(rows, 0);
	Matrix b = matrixNew(0, cols);
	
	int result = 1;
	
	Matrix c = matrixMul(a, b);
	if(c == 0)
		return 0;
	
	Matrix zeros = matrixNew(rows, cols);
	
	result *= matrixEquals(c, zeros);
	
	matrixDelete(a);
	matrixDelete(b);
	matrixDelete(c);
	matrixDelete(zeros);
	
	return result;
}

#define TEST(a) test++; if(!((a)(rows, cols))) printf("Test failed: %s(%d, %d)\n", #a, rows, cols); else success++;

int main() {
	
	int test = 0;
	int success = 0;
	
	for(int rows = 1; rows <= 16; rows++) {
		for(int cols = 1; cols <= 16; cols++) {
			TEST(testCreation);
			TEST(testScale);
			TEST(testAddition);
			TEST(testMul);
			//TEST(testZeroMul);
		}
	}
	
	printf("Testing don %d/%d\n", success, test);
	
	printf("Starting HUGE testing\n");
	
	int huge_a[] = {1, 10000, 4, 16, 1024};
	int huge_b[] = {100000, 1, 1024, 2048, 1024};
	int huge_c[] = {1, 10000, 4, 16, 1024};
	
	for(int i = 0; i < 22; i++) {
		Matrix a = randomMatrix(huge_a[i], huge_b[i], 1);
		Matrix b = randomMatrix(huge_b[i], huge_c[i], 2);
		
		matrixDelete(matrixMul(a, b));
		
		matrixDelete(a);
		matrixDelete(b);
	}
	
	return 0;
}
