#include "../../include/matrix.h"
#include <stdio.h>

void print_matrix(FILE * fp, Matrix m)
{
    fprintf(fp, "%p ", m);
    if(!m)
        return;
    fprintf(fp, "%d %d\n", matrixGetRows(m), matrixGetCols(m));
    for(int i = 0; i < matrixGetRows(m); i++)
    {
        for(int j = 0; j < (matrixGetCols(m)); j++)
        {
            fprintf(fp, "%6.2f ", matrixGet(m, i, j));
        }
        fprintf(fp, "\n");
    }
    fprintf(fp, "\n");

}

int main()
{
    Matrix m1 = matrixNew(3, 2);
    Matrix m2 = matrixNew(2, 3);

    matrixSet(m1, 0, 0, 3.f);
    matrixSet(m1, 1, 1, 2.f);
    matrixSet(m1, 2, 1, 1.f);
    matrixSet(m1, 1, 0, 4.f);
    matrixSet(m1, 2, 0, 24.f);

    matrixSet(m2, 0, 0, 3.f);
    matrixSet(m2, 1, 1, 2.f);
    matrixSet(m2, 0, 2, 5.f);
    matrixSet(m2, 1, 2, 4.f);
    matrixSet(m2, 1, 0, 12.f);
    print_matrix(stdout, m1);
    print_matrix(stdout, m2);

    Matrix m3 = matrixMul(m1, m2);
    print_matrix(stdout, m3);


    matrixDelete(m1);
    matrixDelete(m2);
    matrixDelete(m3);

   

    
}