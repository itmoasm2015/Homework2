#include "matrix.h"
#include "stdio.h"
#include "stdlib.h"
#include "time.h"

int main()
{
    Matrix a = matrixNew(10, 10);
    
    int a_cols = (matrixGetCols(a) + 3) & ~3;
    int a_rows = (matrixGetRows(a) + 3) & ~3;
    float* a_data = a->data;
    
    int i, j;
    
    for (j = 0; j < a_rows; j++)
        for (i = 0; i < a_cols; i++)
            matrixSet(a, j, i, (float)(i + j));

    Matrix scaled = matrixScale(a, 2.0);

    for (j = 0; j < a_rows; j++)
        for (i = 0; i < a_cols; i++) {
            //float s = matrixGet(a, j, i);
            //unsigned int as = *(unsigned int*)&s;
            printf("%.2f%c", matrixGet(a, j, i), " \n"[i == a_cols - 1]);
            //printf("%u|%u%c", as, ((unsigned int*)a_data)[j * a_cols + i], " \n"[i == a_cols - 1]);
        }
            //printf("%u%c", ((unsigned int*)a_data)[j * a_cols +  i], " \n"[i == a_cols - 1]);

    matrixDelete(scaled);
    matrixDelete(a);

    //return 0;

    int k;
    Matrix b = matrixNew(10000, 10000);
    //int b_cols = (matrixGetCols(b) + 3) & ~3;
    //int b_rows = (matrixGetRows(b) + 3) & ~3;
    //float* b_data = b->data;

    int t = clock();
    //for (k = 0; k < 10; k++)
    //for (j = 0; j < b_rows; j++)
    //    for (i = 0; i < b_cols; i++)
    //        b_data[j * b_cols + i] *= 2;
    //printf("time: %d ms\n", (clock() - t) / (CLOCKS_PER_SEC / 1000));    

    matrixDelete(b);

    b = matrixNew(10000, 10000);

    t = clock();
    for (k = 0; k < 10; k++) {
        Matrix c = matrixScale(b, 2.0);
        //matrixDelete(c);
    }
    printf("time: %d ms\n", (clock() - t) / (CLOCKS_PER_SEC / 1000));    
    
    matrixDelete(b);

    return 0;
}
