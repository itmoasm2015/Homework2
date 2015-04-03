#include "matrix.h"
#include <stdio.h>
#include <cstdlib>
#include <random>
#include <ctime>

float aaA[110][110];
float bbA[110][110];
float ccA[110][110];
Matrix aaM;
Matrix bbM;
Matrix ccM;
int n1, m1;
int n2, m2;
int n3, m3;
const int N = 5;
const int M = 5;
const float EPS = 0.000000001;


void mulMatrix() {
	if (n2 != m1) return;
	n3 = n1;
	m3 = m2;
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m2; j++) {
			float sum = 0;
			for (int k = 0; k < n2; k++) {
				sum += aaA[i][k] * bbA[k][j];	
			}
			ccA[i][j] = sum;
		}	
	}
}

void sumMatrix() {
	if (n1 != n2) return;
	if (m1 != m2) return;
	n3 = n1;
	m3 = m1;
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			ccA[i][j] = aaA[i][j] + bbA[i][j];
		}	
	}
}

void scaleMatrix(float k) {
	n3 = n1;
	m3 = m1;
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			ccA[i][j] = aaA[i][j] * k;		
		}	
	}
}

void setRandMatrix(int nn1, int mm1, int nn2, int mm2, int maxN) {
	n1 = nn1;
	n2 = nn2;
	m1 = mm1;
	m2 = mm2;
	aaM = matrixNew(n1, m1);
	bbM = matrixNew(n2, m2);
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			aaA[i][j] = rand() % maxN / 100000.0;
			matrixSet(aaM, i, j, aaA[i][j]);
		}	
	}
	for (int i = 0; i < n2; i++) {
		for (int j = 0; j < m2; j++) {
			bbA[i][j] = rand() % maxN / 100000.0;
			matrixSet(bbM, i, j, bbA[i][j]);
		}	
	}
}

bool compareMatrix() {
	if (n3 != matrixGetRows(ccM)) return false;
	if (m3 != matrixGetCols(ccM)) return false;
	for (int i = 0; i < n3; i++) {
		for (int j = 0; j < m3; j++) {
			if (fabs(ccA[i][j] - matrixGet(ccM, i, j)) > EPS) return false;
		}
	}
	return true;
}

void printMatrix() {
	printf("ARRAY\n");
	for (int i = 0; i < n3; i++) {
		for (int j = 0; j < m3; j++) {
			printf("%.4f ", ccA[i][j]);
		}	
		printf("\n");
	}
	printf("MATRIX\n");
	for (int i = 0; i < matrixGetRows(ccM); i++) {
		for (int j = 0; j < matrixGetCols(ccM); j++) {
			printf("%.4f ", matrixGet(ccM, i, j));
		}	
		printf("\n");
	}

}

void testScale(int maxN) {
	for (int test = 1; test <= 100; test++) {
		int m = rand() % 100 + 1;
		float k = rand() % maxN + 1 + 0.0;
		setRandMatrix(m, test, m, test, maxN);	
		ccM = matrixScale(aaM, k);
		if (ccM == 0) {
			printf("bad size %d %d\n", m, test);
			continue;
		}
		scaleMatrix(k);
		if (!compareMatrix()) {
			printMatrix();
			break;
		} else {
			printf("OK SCALE %d\n", test);		
		}
		matrixDelete(aaM);
		matrixDelete(bbM);
		matrixDelete(ccM);
	}
}

void testAdd(int maxN) {
	for (int test = 1; test <= 100; test++) {
		int m = rand() % 100;
		setRandMatrix(m, test, m, test, maxN);	
		ccM = matrixAdd(aaM, bbM);
		if (ccM == 0) {
			printf("bad size %d %d\n", m, test);
			continue;
		}
		sumMatrix();
		if (!compareMatrix()) {
			printMatrix();
			break;
		} else {
			printf("OK SUM %d\n", test);		
		}
		matrixDelete(aaM);
		matrixDelete(bbM);
		matrixDelete(ccM);
	}
}

void testMul(int maxN) {
	for (int test = 1; test <= 100; test++) {
		int m = rand() % 100 + 1;
		int h = rand() % 100 + 1;
		setRandMatrix(test, m, m, h, maxN);	
		ccM = matrixMul(aaM, bbM);
		if (ccM == 0) {
			printf("bad size\n");
			continue;
		}
		mulMatrix();
		if (!compareMatrix()) {
			printMatrix();
			break;
		} else {
			printf("OK MUL %d\n", test);		
		}
		matrixDelete(aaM);
		matrixDelete(bbM);
		matrixDelete(ccM);
	}
}

int main() {
	srand(time(NULL));
	printf("START TEST\n");
	int maxN = 1;
	for (int i = 1; i < 9; i++) {
		testScale(maxN);
		testAdd(maxN);
		testMul(maxN);
		maxN *= 10;	
	}
	printf("END TEST\n");
	return 0;
}

