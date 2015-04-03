#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <time.h>
#include <math.h>
#include "../../include/matrix.h"

float myMult[4][6];
const float EPS = 1e-5;

float max(const float a, const float b) {
    return a < b ? b : a;
}

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
    puts("");
    Matrix scaled = matrixScale(matr, 2);
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 5; j++) {
            assert(matrixGet(scaled, i, j) == matrixGet(matr, i, j) * 2);
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(scaled, i, j, value);
            printf("%f ", value);
        }
        puts("");
    }
    puts("");
    Matrix added = matrixAdd(matr, scaled);
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 5; j++)
            assert(matrixGet(added, i, j) == matrixGet(matr, i, j) + matrixGet(scaled, i, j));
    Matrix toMult = matrixNew(5, 6);
    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 6; j++) {
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(toMult, i, j, value);
            printf("%f ", value);
            if (i < 4 && j < 5) 
                matrixSet(matr, i, j, value);
        }
        puts("");
    }
    int cTime = time(0);
    Matrix multiplied = matrixMul(matr, toMult);
    printf("%u\n", time(0) - cTime);
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 6; j++)
            printf("%f ", matrixGet(multiplied, i, j));
        puts("");
    }
    puts("");
    cTime = time(0);
    for (int k = 0; k < 5; k++)
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 6; j++)
                myMult[i][j] += matrixGet(matr, i, k) * matrixGet(toMult, k, j);
    printf("%u\n", time(0) - cTime);
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 6; j++)
            printf("%f ", myMult[i][j]);
        puts("");
    }
    puts("");
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 6; j++)
            assert(abs(myMult[i][j] - matrixGet(multiplied, i, j)) < max(EPS, abs(myMult[i][j]) * EPS));
    matrixDelete(matr);
    matrixDelete(scaled);
    matrixDelete(added);
    matrixDelete(toMult);
    matrixDelete(multiplied);
    return 0;
}
