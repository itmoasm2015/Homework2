#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <time.h>
#include <math.h>
#include "../../include/matrix.h"

//#define R 400
//#define C 500
//#define C2 600
#define R 800
#define C 1000
#define C2 1200

float myMult[R][C2];
const float EPS = 1e-5;

float max(const float a, const float b) {
    return a < b ? b : a;
}

int main() {
    Matrix matr = matrixNew(R, C);
    for (int i = 0; i < R; i++) {
        for (int j = 0; j < C; j++) {
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(matr, i, j, value);
            //printf("%f ", value);
            assert(matrixGet(matr, i, j) == value);
        }
        //puts("");
    }
    //puts("");
    Matrix scaled = matrixScale(matr, 2);
    for (int i = 0; i < R; i++) {
        for (int j = 0; j < C; j++) {
            assert(matrixGet(scaled, i, j) == matrixGet(matr, i, j) * 2);
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(scaled, i, j, value);
            //printf("%f ", value);
        }
        //puts("");
    }
    //puts("");
    Matrix added = matrixAdd(matr, scaled);
    for (int i = 0; i < R; i++)
        for (int j = 0; j < C; j++)
            assert(matrixGet(added, i, j) == matrixGet(matr, i, j) + matrixGet(scaled, i, j));
    Matrix toMult = matrixNew(C, C2);
    for (int i = 0; i < C; i++) {
        for (int j = 0; j < C2; j++) {
            float value = rand() * 1.f / RAND_MAX;
            matrixSet(toMult, i, j, value);
            //printf("%f ", value);
        }
        //puts("");
    }
    clock_t cTime = clock();
    Matrix multiplied = matrixMul(matr, toMult);
    printf("%u\n", clock() - cTime);
    //for (int i = 0; i < R; i++) {
    //    for (int j = 0; j < C2; j++)
    //        printf("%f ", matrixGet(multiplied, i, j));
    //    puts("");
    //}
    //puts("");
    cTime = clock();
    for (int k = 0; k < C; k++)
        for (int i = 0; i < R; i++)
            for (int j = 0; j < C2; j++)
                myMult[i][j] += matrixGet(matr, i, k) * matrixGet(toMult, k, j);
    printf("%u\n", clock() - cTime);
    //for (int i = 0; i < R; i++) {
    //    for (int j = 0; j < C2; j++)
    //        printf("%f ", myMult[i][j]);
    //    puts("");
    //}
    //puts("");
    for (int i = 0; i < R; i++)
        for (int j = 0; j < C2; j++)
            assert(abs(myMult[i][j] - matrixGet(multiplied, i, j)) < max(EPS, abs(myMult[i][j]) * EPS));
    matrixDelete(matr);
    matrixDelete(scaled);
    matrixDelete(added);
    matrixDelete(toMult);
    matrixDelete(multiplied);
    return 0;
}
