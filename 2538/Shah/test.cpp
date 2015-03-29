#include "matrix.h"
#include <stdio.h>
#include <limits>
#include <string.h>
#include <stdlib.h>
#include <cassert>
#include <ctime>
#include <random>
#include "supermatrix.h"

using namespace std;

std::random_device rd;
std::mt19937 gen(rd());
const int TEST_COUNT = 10;
const int SCALE_MIN_SIZE = 100;
const int SCALE_MAX_SIZE = 1000;
const int ADD_MIN_SIZE = 100;
const int ADD_MAX_SIZE = 1000;
const int MUL_MIN_SIZE = 500;
const int MUL_MAX_SIZE = 1000;

int randInt(int l, int r)
{
    std::uniform_int_distribution<> dis(l, r);
    return dis(gen);
}

float randFloat()
{
    return rand() * 1.0 / RAND_MAX;
}

Matrix genMatrix(int n, int m)
{
    Matrix matr = matrixNew(n, m);
    for (size_t i = 0; i < matrixGetRows(matr); i++)
    {
        for (size_t j = 0; j < matrixGetCols(matr); j++)
        {
            matrixSet(matr, i, j, randFloat());
        }
    }
    return matr;
}

void test_scale()
{
    printf("====== TESTING SCALING ======\n");
    for (int lp = 0; lp < TEST_COUNT; lp++)
    {
        Matrix a = genMatrix(randInt(SCALE_MIN_SIZE, SCALE_MAX_SIZE), randInt(SCALE_MIN_SIZE, SCALE_MAX_SIZE));
        SuperMatrix sm(a);

        float val = randFloat();
        double t1 = clock();
        Matrix ans = matrixScale(a, val);
        t1 = (clock() - t1);

        double t2 = clock();
        SuperMatrix s2 = sm.scale(val);
        t2 = (clock() - t2);
        
        if (!s2.equals(ans))
        {
            printf("test: %d failure\n", lp + 1);
        }

        printf("test: %d speedup: %.3f%%\n", lp + 1, (1.0 - t1/t2) * 100.0);
        matrixDelete(a);
        matrixDelete(ans);
    }
}

void test_add()
{
    printf("====== TESTING ADDING ======\n");
    for (int lp = 0; lp < TEST_COUNT; lp++)
    {
        Matrix a = genMatrix(randInt(ADD_MIN_SIZE, ADD_MAX_SIZE), randInt(ADD_MIN_SIZE, ADD_MAX_SIZE));
        Matrix b = genMatrix(matrixGetRows(a), matrixGetCols(a));
        SuperMatrix sm(a);
        SuperMatrix sm2(b);

        double t1 = clock();
        Matrix ans = matrixAdd(a, b);
        t1 = (clock() - t1);

        double t2 = clock();
        SuperMatrix s2 = sm.add(sm2);
        t2 = (clock() - t2);
        
        if (!s2.equals(ans))
        {
            printf("test: %d failure\n", lp + 1);
        }

        printf("test: %d dims: %u %u speedup: %.3f%%\n", lp + 1, s2.getRows(), s2.getCols(), (1.0 - t1/t2) * 100.0);
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(ans);
    }
}

void test_mul()
{
    printf("====== TESTING MUL ======\n");
    for (int lp = 0; lp < TEST_COUNT; lp++)
    {
        Matrix a = genMatrix(randInt(MUL_MIN_SIZE, MUL_MAX_SIZE), randInt(MUL_MIN_SIZE, MUL_MAX_SIZE));
        Matrix b = genMatrix(matrixGetCols(a), randInt(MUL_MIN_SIZE, MUL_MAX_SIZE));
        SuperMatrix sm(a);
        SuperMatrix sm2(b);

        double t1 = clock();
        Matrix ans = matrixMul(a, b);
        t1 = (clock() - t1);

        double t2 = clock();
        SuperMatrix s2 = sm.mul(sm2);
        t2 = (clock() - t2);
        
        if (!s2.equals(ans))
        {
            printf("test: %d failure\n", lp + 1);
            return;
        }

        printf("test: %d dims: %u %u speedup: %.3f%%\n", lp + 1, s2.getRows(), s2.getCols(), (1.0 - t1/t2) * 100.0);
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(ans);
    }
}

int main()
{
    srand(time(NULL));
    test_scale();
    test_add();
    test_mul();
    return 0;
}
