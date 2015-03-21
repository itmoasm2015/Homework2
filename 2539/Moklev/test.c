#include "matrix.h"
#include "stdio.h"
#include "stdlib.h"

int main()
{
    Matrix a = matrixNew(10, 10);
    //printf("mamka %lld\n", (long long) a);
    //printf("%d %d\n", *((unsigned int*) a), *((unsigned int*) a + 1));
    printf("%d %d\n", a->rows, a->cols);
    printf("%d %d\n", (a->rows + 3) & ~3, (a->cols + 3) & ~3);
    a->cols = (a->cols + 3) & ~3;
    a->rows = (a->rows + 3) & ~3;
    int i, j;
    for (j = 0; j < a->rows; j++)
        for (i = 0; i < a->cols; i++)
            printf("%.2f%c", a->data[j * a->cols + i], " \n"[i == a->cols - 1]);
    
    return 0;
}
