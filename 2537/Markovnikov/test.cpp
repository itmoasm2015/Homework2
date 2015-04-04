#include <stdio.h>
#include <cstdlib>
#include <climits>
#include <cmath>
#include "matrix.h"

int get_random_int(int l, int r) {
    return rand() % r + l;
}

#define TEST(test)  if (test()) \
                        printf("%s %s\n", #test, "OK"); \
                    else \
                        printf("%s %s\n", #test, "FAILED"); \

const float eps = 1e-4;
void printMatrix(Matrix a);
void printMatrix(float** a, unsigned int n, unsigned int m);

bool test_matrix_new() {
    Matrix a;
    unsigned int n = get_random_int(1, 1000);
    unsigned int m = get_random_int(1, 1000);
    a = matrixNew(n, m);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++)
            if (fabs(matrixGet(a, i, j)) >= eps) {
                matrixDelete(a);
                return false;
            }    
    matrixDelete(a);
    return true;
}

bool test_matrix_get_sizes() {
    Matrix a;
    unsigned int n = get_random_int(1, 1000);
    unsigned int m = get_random_int(1, 1000);
    a = matrixNew(n, m);
    unsigned int nn = matrixGetRows(a);
    unsigned int mm = matrixGetCols(a);
    matrixDelete(a);
    return (n == nn & m == mm);
}

bool test_matrix_set() {
    Matrix a;
    unsigned int n = get_random_int(1, 1000);
    unsigned int m = get_random_int(1, 1000);
    a = matrixNew(n, m);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            float value = get_random_int(1, 10000) / (1, 10000);
            matrixSet(a, i, j, value);
        }
    matrixDelete(a);
    return true;
}

bool test_matrix_get() {
    Matrix a;
    unsigned int n = get_random_int(1, 1000);
    unsigned int m = get_random_int(1, 1000);
    a = matrixNew(n, m);
    float** test = new float* [n];
    for (int i = 0; i < n; i++)
        test[i] = new float [m];
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            float value = (float) get_random_int(10000, 1000) / (float) get_random_int(1, 7000);
            matrixSet(a, i, j, value);
            test[i][j] = value;
        }
 //   printMatrix(a);
 //   printMatrix(test, n, m);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++)
            if (fabs(test[i][j] - matrixGet(a, i, j)) >= eps) {
                matrixDelete(a);
                return false;
            }
    matrixDelete(a);
    return true;
}

void printMatrix(Matrix a) {
    printf("\n");
    for (int i = 0; i < matrixGetRows(a); i++) {
        for (int j = 0; j < matrixGetCols(a); j++)
            printf("%f ", matrixGet(a, i, j));
        printf("\n");
    }
}

void printMatrix(float** a, unsigned int n, unsigned int m) {
    printf("\n");
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++)
            printf("%f ", a[i][j]);
        printf("\n");
     }
}

bool test_matrix_add() {
    Matrix a;
    Matrix b;
    Matrix c;
    unsigned int n = get_random_int(1, 10);
    unsigned int m = get_random_int(1, 10);
    float** test_c = new float* [n];
    a = matrixNew(n, m);
    b = matrixNew(n, m);
    for (int i = 0; i < n; i++) {
        test_c[i] = new float [m];
    }
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            float a_v = (float) get_random_int(5000, 20000) / (float) get_random_int(1000, 15000);
            float b_v = (float) get_random_int(5000, 20000) / (float) get_random_int(1000, 15000);
            matrixSet(a, i, j, a_v);
            matrixSet(b, i, j, b_v);
            test_c[i][j] = a_v + b_v;
        }
    c = matrixAdd(a, b);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++)
            if (fabs(matrixGet(c, i, j) - test_c[i][j]) >= eps) {
                matrixDelete(a);
                matrixDelete(b);
                matrixDelete(c);
                return false;
            }
    matrixDelete(a);
    matrixDelete(b);
    matrixDelete(c);
    return true;
}

bool test_matrix_scale() {
    Matrix a;
    unsigned int n = get_random_int(5, 10);
    unsigned int m = get_random_int(1, 10);
    a = matrixNew(n, m);
    float** test = new float* [n];
    for (int i = 0; i < n; i++)
        test[i] = new float [m];
    float v = (float) get_random_int(10000, 20000) / (float) get_random_int(1, 15000);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            float value = (float) get_random_int(10000, 20000) / (float) get_random_int(1, 15000);
            matrixSet(a, i, j, value);
            test[i][j] = value * v;
        }
    Matrix res = matrixScale(a, v);
//    printMatrix(res);
//    printMatrix(test, n, m);
    for (int i = 0; i < n; i++)
        for (int j = 0; j  < m; j++)
            if (fabs(matrixGet(res, i, j) - test[i][j]) >= eps) {
                matrixDelete(res);
                matrixDelete(a);
                return false;
            }
    matrixDelete(res);
    matrixDelete(a);
    return true;
}

bool test_matrix_transpose() {
    Matrix a;
    unsigned int n = 20;
    unsigned int m = 30;
    a = matrixNew(n, m);
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            float v = (float) get_random_int(10000, 20000) / (float) get_random_int(1, 15000);
            matrixSet(a, i, j, v);
        }
    Matrix res = matrixMul(a, a);
 //   printMatrix(a);
 //   printMatrix(res);
    if (matrixGetRows(res) != m || matrixGetCols(res) != n)
        return false;
    for (int i = 0; i < m; i++)
        for (int j = 0; j < n; j++) {
            if (fabs(matrixGet(a, j , i) - matrixGet(res, i, j)) >= eps) {
                printMatrix(a);
                printMatrix(res);
                matrixDelete(a);
                matrixDelete(res);
                return false;
            }
        }
    matrixDelete(a);
    matrixDelete(res);
    return true;
}

bool test_matrix_mul() {
    Matrix a;
    Matrix b;
    unsigned int n = get_random_int(1, 100);
    unsigned int m = get_random_int(1, 100);
    unsigned int q = get_random_int(1, 100);
    
    a = matrixNew(m, n);
    b = matrixNew(n, q);
    float** test_a = new float* [m];
    float** test_b = new float* [n];
    for (int i = 0; i < m; i++)
        test_a[i] = new float [n];
    for (int i = 0; i < n; i++)
        test_b[i] = new float [q];
    for (int i = 0; i < m; i++)
        for (int j = 0; j < n; j++) {
            float v_a = (float) get_random_int(10, 20) / (float) get_random_int(10, 20);
            matrixSet(a, i, j, v_a);
            test_a[i][j] = v_a;
        }
    for (int i = 0; i < n; i++)
        for (int j = 0; j < q; j++) {
            float v_b = (float) get_random_int(10, 20) / (float) get_random_int(10, 20);
            matrixSet(b, i, j, v_b);
            test_b[i][j] = v_b;
        }
    
    Matrix res = matrixMul(a, b);
    float** test_res = new float* [m];
    
    if (matrixGetRows(res) != m || matrixGetCols(res) != q)
        return false;
    for (int i = 0; i < m; i++)
        test_res[i] = new float [q];
    for (int i = 0; i < m; i++)
        for (int j = 0; j < q; j++)
            test_res[i][j] = 0;
    for (int i = 0; i < m; i++)
        for (int j = 0; j < q; j++)
            for (int k = 0; k < n; k++) {
                test_res[i][j] += test_a[i][k] * test_b[k][j];
            }
   // printMatrix(res);
   // printMatrix(test_res, m, q);
    for (int i = 0; i < m; i++)
        for (int j = 0; j < q; j++) {
            if (fabs(test_res[i][j] - matrixGet(res, i, j)) >= eps)
                return false;
        }
    matrixDelete(a);
    matrixDelete(b);
    matrixDelete(res);
    return true;
}

int main() {
	TEST(test_matrix_new);
	TEST(test_matrix_get_sizes);
    TEST(test_matrix_set);
    TEST(test_matrix_get);
    TEST(test_matrix_add);
    TEST(test_matrix_scale);
    TEST(test_matrix_mul);
    //TEST(test_matrix_transpose);
	return 0;
}
