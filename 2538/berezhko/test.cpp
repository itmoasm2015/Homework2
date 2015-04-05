#include "include/matrix.h"
#include <iostream>
#include <cassert>
#include <cstdlib>
#include <ctime>

using namespace std;

void printMatrix(Matrix a) {
    for (int i = 0; i < matrixGetRows(a); i++) {
        for (int j = 0; j < matrixGetCols(a); j++) {
            cout << matrixGet(a, i, j) << " ";
        }
        cout << "\n";
    }
}

float genFloat() {
    int numerator = rand();
    int denumerator = rand();
    float x = 100.0f * numerator / denumerator;
    return x;
}

void test1() {
    cout << "Test1 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        matrixDelete(a);
    }
    cout << "OK\n";
}

void test2() {
    cout << "Test2 starts ... ";
    float tmp[1001][1001];
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                int numerator = rand();
                int denumerator = rand();
                float x = 1.0f * numerator / denumerator;
                matrixSet(a, i, j, x);
                tmp[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(a, i, j) == tmp[i][j]);
            }
        }
        matrixDelete(a);
    }
    cout << "OK\n";
}

void test3() {
    cout << "Test3 starts ... ";
    float tmp[1001][1001];
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        float k = genFloat();
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                tmp[i][j] = x * k;
            }
        }
        Matrix b = matrixScale(a, k);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(b, i, j) == tmp[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
    }
    cout << "OK\n";
}

float aa[1001][1001];
float bb[1001][1001];
float cc[1001][1001];
void test4() {
    cout << "Test4 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        Matrix b = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        assert(n == matrixGetRows(b));
        assert(m == matrixGetCols(b));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
                cc[i][j] = aa[i][j] + bb[i][j];
            }
        }
        Matrix c = matrixAdd(a, b);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(c, i, j) == cc[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(c);
    }
    cout << "OK\n";
}

void test5() {
    cout << "Test5 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 200 + 1;
        int m = rand() % 200 + 1;
        int q = rand() % 200 + 1;
        Matrix a = matrixNew(n, m);
        Matrix b = matrixNew(m, q);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        assert(m == matrixGetRows(b));
        assert(q == matrixGetCols(b));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < q; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < q; j++) {
                cc[i][j] = 0;
                for (int k = 0; k < m; k++) {
                    cc[i][j] += aa[i][k] * bb[k][j];
                }
            }
        }
        Matrix c = matrixMul(a, b);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < q; j++) {
                assert(matrixGet(c, i, j) == cc[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(c);
    }
    cout << "OK\n";
}

void test6() {
    cout << "Test6 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        void *adra = a;
        matrixDelete(a);
        Matrix b = matrixNew(n, m);
        void *adrb = b;
        matrixDelete(b);
        assert(adra == adrb);
    }
    cout << "OK\n";
}

void test7() {
    cout << "Test7 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n1 = rand() % 1000 + 1;
        int m1 = rand() % 1000 + 1;
        int n2 = rand() % 1000 + 1;
        int m2 = rand() % 1000 + 1;
        Matrix a = matrixNew(n1, m1);
        Matrix b = matrixNew(n2, m2);
        assert(n1 == matrixGetRows(a));
        assert(m1 == matrixGetCols(a));
        assert(n2 == matrixGetRows(b));
        assert(m2 == matrixGetCols(b));
        for (int i = 0; i < n1; i++) {
            for (int j = 0; j < m1; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < n2; i++) {
            for (int j = 0; j < m2; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
            }
        }
        Matrix c = matrixMul(a, b);
        Matrix d = matrixAdd(a, b);
        assert(c == NULL);
        assert(d == NULL);
        matrixDelete(a);
        matrixDelete(b);
    }
    cout << "OK\n";
}

int main() {
    srand(time(NULL));
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    return 0;
}


