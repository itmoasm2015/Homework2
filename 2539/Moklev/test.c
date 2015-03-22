#include "matrix.h"
#include "stdio.h"
#include "stdlib.h"

int main()
{
    Matrix a = matrixNew(10, 10);
    
    int a_cols = (matrixGetCols(a) + 3) & ~3;
    int a_rows = (matrixGetRows(a) + 3) & ~3;
    float* a_data = a->data;
    
    int i, j;
    for (j = 0; j < a_rows; j++)
        for (i = 0; i < a_cols; i++)
            printf("%.2f%c", a_data[j * a_cols + i], " \n"[i == a_cols - 1]);

    matrixDelete(a);
    
    return 0;
}
