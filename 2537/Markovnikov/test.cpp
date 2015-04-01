#include <stdio.h>
#include <cstdlib>
#include <climits>
#include <cmath>
#include "matrix.h"

int get_random_int(int l, int r) {
	return rand() % r + l;
}

#define TEST(test)	if (test()) \
                        printf("%s %s", #test, "OK"); \
                    else \
                        printf("%s %s", #test, "FAILED"); \

const float eps = 1e-5;
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

int main() {
	TEST(test_matrix_new);
	TEST(test_matrix_get_sizes);
    TEST(test_matrix_set);
    TEST(test_matrix_get);
    TEST(test_matrix_add);
	return 0;
}
