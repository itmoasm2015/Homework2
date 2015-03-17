#include "matrix.h"
#include "stdio.h"

int main()
{
    Matrix a = matrixNew(15, 42);
    printf("mamka %lld\n", a);
    //printf("%d %d\n", *((unsigned int*) a), *((unsigned int*) a + 1));
    //printf("%d %d %d\n", a->rows, a->cols, a->data);

    return 0;
}
