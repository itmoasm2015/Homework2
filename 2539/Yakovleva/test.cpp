#include "matrix.h"
#include <stdio.h>
#include <cstdlib>
#include <random>
#include <ctime>

float aaA[100][100];
float bbA[100][100];
float ccA[100][100];
Matrix aaM;
Matrix bbM;
Matrix ccM;
int n1, m1;
int n2, m2;
const int N = 5;
const int M = 5;


void mulMatrix() {
	if (n2 != m1) return;
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
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			ccA[i][j] = aaA[i][j] + bbA[i][j];		
		}	
	}
}

void scalarMatrix(float k) {
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			aaA[i][j] *= k;		
		}	
	}
}


int main() {
	srand(time(NULL));
	printf("START TEST\n");
	n1 = N;
	n2 = N;
	m1 = M;
	m2 = M;
// 	aaA = new float*[n1];
//    	for (int i = 0; i < n1; i++) aaA[i] = new float[m1];
// 	bbA = new float*[n2];
//    	for (int i = 0; i < n2; i++) bbA[i] = new float[m2];
// 	ccA = new float*[n2];
//    	for (int i = 0; i < n2; i++) ccA[i] = new float[m2];

	aaM = matrixNew(n1, m1);
	bbM = matrixNew(n2, m2);
	ccM = matrixNew(n2, m2);
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
			aaA[i][j] = rand() % 1000 / 123.0;
			bbA[i][j] = rand() % 1000 / 123.0;
			matrixSet(aaM, i, j, aaA[i][j]);	
			matrixSet(bbM, i, j, bbA[i][j]);
		}	
	}
	ccM = matrixMul(aaM, bbM);
	mulMatrix();
	printf("ARRAY\n");
	for (int i = 0; i < n1; i++) {
		for (int j = 0; j < m1; j++) {
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
//	for (int i = 0; i < n1; i++) delete []aaA[i];
//   	delete []aaA;
//	for (int i = 0; i < n2; i++) delete []bbA[i];
//   	delete []bbA;
//	for (int i = 0; i < n2; i++) delete []ccA[i];
//   	delete []ccA;
	matrixDelete(aaM);
	matrixDelete(bbM);
	matrixDelete(ccM);












    int r = 3;
    int c = 3;
    Matrix matrix;
    matrix = matrixNew(r, c);
    printf("!matrix = %d!\n", (int*)matrix);
    int rows = matrixGetRows(matrix);
    printf("!rows = %d!\n", rows);
    int cols = matrixGetCols(matrix);
    printf("!cols = %d!\n", cols);
    for (int i = 0; i < r; i++) {
        for (int j = 0; j < c; j++) {
	    printf("!set %d %d!\n", i, j);
	    matrixSet(matrix, i, j, 2.2);
        }
    }
    float elem = matrixGet(matrix, 1, 1);
    printf("!elem = %.3f!\n", elem);
    Matrix matrix2 = matrixScale(matrix, 5.0);
    float elem2 = matrixGet(matrix2, 1, 1);
    printf("!elem2 = %.3f!\n", elem2);
    Matrix matrixSum = matrixAdd(matrix, matrix2);
    float elemSum = matrixGet(matrixSum, 1, 1);
    printf("!elemSum = %.3f!\n", elemSum);
    Matrix matrixMult = matrixMul(matrix, matrix2);
    float elemMul = matrixGet(matrixMult, 1, 1);
    printf("!elemMul = %.3f!\n", elemMul);
    float elem3 = matrixGet(matrix, 2, 1);
    printf("!elem = %.3f!\n", elem3);
    matrixDelete(matrix);
    printf("!matrix deleted!\n");
    printf("END TEST\n");
    return 0;
}

