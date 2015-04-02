#include "matrix.h"
#include <stdio.h>
#include <cstdlib>

char out[10000];

int main() {
    printf("START TEST\n");
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

