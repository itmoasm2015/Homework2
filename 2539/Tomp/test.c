#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "../../include/matrix.h"

int main() {
    Matrix matr = matrixNew(4, 5);
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 5; j++) {
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(matr, i, j, value);
            printf("%f ", value);
            assert(matrixGet(matr, i, j) == value);
        }
        puts("");
    }
    Matrix scaled = matrixScale(matr, 2);
    for (int i = 0; i < 4; i++) {
        //puts("");
        for (int j = 0; j < 5; j++) {
            assert(matrixGet(scaled, i, j) == matrixGet(matr, i, j) * 2);
            //printf("%f ", matrixGet(scaled, i, j));
        }
    }
    //puts("");
    matrixDelete(matr);
    matrixDelete(scaled);
    return 0;
}
