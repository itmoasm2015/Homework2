#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include "MyMatrix.hpp"
#include "../../include/matrix.h"
#include <cassert>
#define MOD 100

using namespace std;

//void test() {

    //srand(time(NULL));

    //int n = 3;
    //int m = 3;
    //MyMatrix a(n, m);
    //MyMatrix b(n, m);

    //for (int i = 0; i < n; ++i) {
        //for (int j = 0; j < m; ++j) {
            //a[i][j] = rand() % 10;
            //b[i][j] = rand() % 10;
        //}
    //}

    //cout << a << endl;
    //cout << b << endl;
    //cout << a + b << endl;
    //cout << a * b << endl;
    //cout << 4.2 * a << endl;
    //cout << a * 4.2 + b * 3<< endl;
//}

extern "C" {
    void fun64(int a, int b, int c, int d, int e, int f, int g, int h, int i);
    void temp() {

    }

    void with_double(double a,double b,double c,double d,double e,double f,double g,double h,double i,double j);
}

void matrixPrint(Matrix b) {
    uint n = ((int*) b)[0];
    uint m = ((int*) b)[1];
    float* a = (float*) b;
    cerr << "------VOID*-----" << endl;
    cerr << "(n, m) = " << "(" << n << ", " << m << ")" << endl;
    for (uint i = 0; i < n; ++i) {
        for (uint j = 0; j < m; ++j) {
            cerr << a[i * m + j + 2] << " ";
        }
        cerr << endl;
    }
    cerr << "------END-----" << endl;
}

void fail(MyMatrix const& a, Matrix b) {
    matrixPrint(b);
    cerr << a;
    exit(1);
}

bool checkMatrix(MyMatrix const& a, Matrix b) {
    if (b == NULL) {
        if (!a.isNull()) {
            fail(a, b);
        } else {
            return true;
        }
    }

    for (uint i = 0; i < matrixGetRows(b); ++i) {
        for (uint j = 0; j < matrixGetCols(b); ++j) {
            if (a[i][j] != matrixGet(b, i, j)) {
                fail(a, b);
                cerr << "(i, j) = " << "(" << i << ", " << j << ")" << endl;
                cerr << "(a[i][j], asm[i][j]) = " << "(" << a[i][j] << ", " << matrixGet(b, i, j) << ")" << endl;
            }
        }
    }
    return true;
}

void fillRandomMatrix(uint n, uint m, MyMatrix& a, Matrix b) {
    for (uint i = 0; i < n; ++i) {
        for (uint j = 0; j < m; ++j) {
            int r = rand() % MOD;
            a[i][j] = r;
            matrixSet(b, i, j, r);
        }
    }
}

void test(int n, int m) {

    int* asm1 = (int*) matrixNew(n, m);
    int* asm2 = (int*) matrixNew(n, m);

    MyMatrix my1(n, m);
    MyMatrix my2(n, m);

    fillRandomMatrix(n, m, my1, asm1);
    fillRandomMatrix(n, m, my2, asm2);

    //checkMatrix(my1 + my2, matrixAdd(asm1, asm2));
    //Matrix temp = matrixScale(asm1, 7);
    //checkMatrix(my1 * 7, temp);

    Matrix temp = matrixMul(asm1, asm2);
    checkMatrix(my1 * my2, temp);
}

void stress() {
    int cntOp = 1000;
    for (int i = 0; i < cntOp; ++i) {
        int n = 3;
        int m = 3;
        //int n = rand() % MOD;
        //int m = rand() % MOD;
        test(n, m);
    }
}

int main() {
    srand(time(NULL));

    stress();

    return 0;
}
