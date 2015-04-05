#include <cmath>
#include <iostream>
#include <algorithm>
#include <math.h>
#include <time.h>
#include "libhw.h"
#include "CMatrix.h"

void matrixPrint(Matrix b) {
    if (b == 0) {
        printf("%d\n", 0);
        return;
    }
    int n = matrixGetRows(b);
    int m = matrixGetCols(b);
    printf("%d %d\n", n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            printf("%.3lf%c", matrixGet(b, i, j), " \n"[j + 1 == m]);
        }
    }
}

int test = 0;

double max(double a, double b) {
    return a > b ? a : b;
}

bool equals(CMatrix &a, Matrix &b) {
    bool ok = b != 0;
    if (ok) {
        int n = matrixGetRows(b);
        int m = matrixGetCols(b);
        ok &= n == a.getRows();
        ok &= m == a.getCols();
        if (ok) {
            for (int i = 0; i < n; i++) for (int j = 0; j < m; j++) ok &= fabs(matrixGet(b, i, j) - a[i][j]) / max(a[i][j], 1.0) < 1e-3;
        }
    }
    return ok;
}

void check(CMatrix &a, Matrix &b) {
    bool ok = equals(a, b);
    printf("Test %d: %s\n", ++test, (ok ? "OK" : "FAIL"));
    if (!ok) {
        a.print();
        matrixPrint(b);
    }
}

int Rand() {
    return rand() % 100;
}

const int mx = 100;
void test2() {
    int n = Rand() % mx + 1;
    int m = Rand() % mx + 1;
    CMatrix a(n, m);
    Matrix b = matrixNew(n, m);
    bool ok = equals(a, b);
    for (int it = 0; it < 10; it++) {
        int t = Rand() % 5;
        if (t == 0) {
            int i = Rand() % n;
            int j = Rand() % m;
            float x = Rand();
            a[i][j] = x;
            matrixSet(b, i, j, x);
        }
        if (t == 1) {
            float x = (Rand() + 1) / 100.0;
            a = a * x;
            Matrix c = matrixScale(b, x);
            matrixDelete(b);
            b = c;
        }
        if (t == 2) {
            CMatrix a1(n, m);
            Matrix b1 = matrixNew(n, m);
            for (int i = 0; i < n; i++) {
                for (int j = 0; j < m; j++) {
                    float x = Rand();
                    a1[i][j] = x;
                    matrixSet(b1, i, j, x);
                }
            }
            a = a + a1;
            Matrix b2 = matrixAdd(b, b1);
            matrixDelete(b1);
            matrixDelete(b);
            b = b2;
        }
        if (t == 3) {
            int k = Rand() % mx + 1;
            CMatrix a1(m, k);
            Matrix b1 = matrixNew(m, k);
            for (int i = 0; i < m; i++) {
                for (int j = 0; j < k; j++) {
                    float x = Rand();
                    a1[i][j] = x;
                    matrixSet(b1, i, j, x);
                }
            }
            a = a * a1;
            Matrix b2 = matrixMul(b, b1);
            matrixDelete(b1);
            matrixDelete(b);
            b = b2;
            m = k;
        }
        if (t == 4) {
            int k = Rand() % mx + 1;
            CMatrix a1(k, n);
            Matrix b1 = matrixNew(k, n);
            for (int i = 0; i < k; i++) {
                for (int j = 0; j < n; j++) {
                    float x = Rand();
                    a1[i][j] = x;
                    matrixSet(b1, i, j, x);
                }
            }
            a = a1 * a;
            Matrix b2 = matrixMul(b1, b);
            matrixDelete(b1);
            matrixDelete(b);
            b = b2;
            n = k;
        }
        ok &= equals(a, b);
    }
    printf("Test %d: %s\n", ++test, (ok ? "OK" : "FAIL"));
    if (!ok) {
        a.print();
        matrixPrint(b);
    }

    matrixDelete(b);
}

void testTime() {
    int n = 1000, m = 1000;
    CMatrix a(n, m);
    Matrix b = matrixNew(n, m);
    for (int i = 0; i < n; i++) for (int j = 0; j < m; j++) {
        int x = Rand();
        a[i][j] = x;
        matrixSet(b, i, j, x);
    }

    time_t start = clock();
    CMatrix a1 = a * a;
    printf("%.3lf\n", (clock() - start) / (double)CLOCKS_PER_SEC);
    start = clock();
    Matrix b1 = matrixMul(b, b);
    printf("%.3lf\n", (clock() - start) / (double)CLOCKS_PER_SEC);       
    printf("%d\n", equals(a1, b1));
    matrixDelete(b);
    matrixDelete(b1);
}

int main()
{
    CMatrix a(2, 2);
    Matrix b = matrixNew(2, 2);
    check(a, b);

    a[0][0] = 2;
    a[1][1] = 3;
    matrixSet(b, 0, 0, 2.0f);
    matrixSet(b, 1, 1, 3.0f);
    check(a, b); 
   
    a = a * a;
    matrixSet(b, 0, 0, 4.0f);
    matrixSet(b, 1, 1, 9.0f);
    check(a, b);    

    Matrix b1 = matrixScale(b, 2);
    CMatrix a1 = a * 2.0;
    check(a1, b1);

    Matrix b2 = matrixAdd(b, b1);
    CMatrix a2 = a + a1;
    check(a2, b2);

    matrixDelete(b);
    matrixDelete(b1);
    matrixDelete(b2);

    for (int it = 0; it < 100; it++) {
        test2();
    }

    int n = 31, m = 31;
    b = matrixNew(n, m);
    a = CMatrix(n, m);
    for (int i = 0; i < n; i++) for (int j = 0; j < m; j++) {
        a[i][j] = (float) 2 * (i + j);
        matrixSet(b, i, j, (float) 2 * (i + j));
    }
    b1 = matrixMul(b, b);
    a = a * a;
    check(a, b1);
    matrixDelete(b);
    matrixDelete(b1);

    b = matrixNew(1, 1);
    b1 = matrixNew(2, 2);
    printf("%d\n", matrixMul(b, b1) == NULL);
    matrixDelete(b);
    matrixDelete(b1);

    printf("%d\n", matrixNew(1000000, 1000000) == NULL);

    b = matrixNew(1000000, 1);
    b1 = matrixNew(1, 1000000);
    printf("%d\n", matrixMul(b, b1) == NULL);
    matrixDelete(b);
    matrixDelete(b1);
    
    testTime();

    return 0;
}
