#include "matrix.h"
#include "stdio.h"
#include "stdlib.h"

int main()
{
    Matrix a = matrixNew(15, 42);
    //printf("mamka %lld\n", (long long) a);
    //printf("%d %d\n", *((unsigned int*) a), *((unsigned int*) a + 1));
    printf("%d %d\n", a->rows, a->cols);

    return 0;
}
