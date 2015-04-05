#include <stdio.h>
#include <stdlib.h>
#include "matrix.h"

int main()
{
    printf("Testing work:\n");
    int n = 1;
    int m = 1;
    Matrix a = matrixNew(n, m);
    for (int i = 0; i < matrixGetRows(a); i++)
        for (int j = 0; j < matrixGetCols(a); j++)
            matrixSet(a, i, j, (float)(i + 1) / (j + 1));
    for (int i = 0; i < matrixGetRows(a); i++)
    {
        for (int j = 0; j < matrixGetCols(a); j++)
            printf("%.5f ", matrixGet(a, i, j));
        printf("\n");
    }
    printf("\n");
    Matrix b = matrixScale(a, 10);
    for (int i = 0; i < matrixGetRows(b); i++)
    {
        for (int j = 0; j < matrixGetCols(b); j++)
            printf("%.5f ", matrixGet(b, i, j));
        printf("\n");
    }
    printf("\n");
    Matrix c = matrixAdd(a, b);
    for (int i = 0; i < matrixGetRows(c); i++)
    {
        for (int j = 0; j < matrixGetCols(c); j++)
            printf("%.5f ", matrixGet(c, i, j));
        printf("\n");
    }
    printf("\n");
    Matrix d = matrixTranspose(c);
    for (int i = 0; i < matrixGetRows(d); i++)
    {
        for (int j = 0; j < matrixGetCols(d); j++)
            printf("%.5f ", matrixGet(d, i, j));
        printf("\n");
    }

    /*c = matrixAdd(a, matrixNew(1, 1));
    if (c == NULL)
        printf("Yeah\n"), c = matrixNew(3, 3);*/
    Matrix e = matrixMul(matrixNew(1, 1), matrixNew(1, 1));
    for (int i = 0; i < matrixGetRows(e); i++)
    {
        for (int j = 0; j < matrixGetCols(e); j++)
            printf("%.5f ", matrixGet(e, i, j));
        printf("\n");
    }
    matrixDelete(a);
    matrixDelete(b);
    matrixDelete(c);
    matrixDelete(d);
    matrixDelete(e);
	return 0;
}
