#include <stdio.h>
#include <stdlib.h>
#include <matrix.h>
#include <math.h>

const float eps = 1e-6;

#define TEST(name, expected, actual, type) {          \
    printf("[TEST] %s... ", name);              \
    if((actual) != (expected)) {                \
        printf("FAILED: expected " type ", but was " type "\n", (expected), (actual)); \
    } else {                                    \
        printf("OK\n");                         \
    }                                           \
}

Matrix fromArray(float *source, unsigned int rows, unsigned int cols) {
    Matrix m = matrixNew(rows, cols);
    if (m == NULL) return NULL;

    size_t arr_i = 0;
    for (int i = 0; i < rows; ++i)
    {      
        for (int j = 0; j < cols; ++j)
        {
            matrixSet(m, i, j, source[arr_i]);
            arr_i++;
        }
    } 
    return m;
}

void showMatrix(Matrix m) {
    if (m == NULL) {
        printf("(NULL)\n");
    }
    int rows = matrixGetRows(m);
    int cols = matrixGetCols(m);
    for (int i = 0; i < rows; ++i)
    {
        for (int j = 0; j < cols; ++j)
        {
            printf("%15f", matrixGet(m, i, j));
        }
        printf("\n");
    }
    printf("\n");
}

char compareMatrices(Matrix a, Matrix b) {
    if(a == NULL || b == NULL) {
        return 0;
    }
    if (matrixGetRows(a) != matrixGetRows(b) || matrixGetCols(a) != matrixGetCols(b)) {
        return 0;
    }
    size_t m = matrixGetRows(a);
    size_t n = matrixGetRows(b);
    for (size_t i = 0; i < m; i++) {
        for (size_t j = 0; j < n; j++) {
            if (fabs(matrixGet(a, i, j) - matrixGet(b, i, j)) > eps) {
                return 0;
            }
        }
    }
    return 1; 
}

float m_test1[] = { 1, 2, 3,
                    4, 5, 6};
float m_test2[] = { 7, 8, 9,
                    10, 11, 12 };
float m_test3[] = { 1, 2, 3, 4,
                    5, 6, 7, 8,
                    9, 10, 11, 12 };
float m_ans1[] = { 8, 10, 12,
                   14, 16, 18};
float m_ans2[] = { 128, 152, 176, 200,
                   173, 206, 239, 272 };
float m_ans3[] = { 1, 4,
                   2, 5,
                   3, 6 };

int main()
{
    Matrix m = matrixNew(5, 4);

    TEST("should return cols properly", 4, matrixGetCols(m), "%d");
    TEST("should return rows properly", 5, matrixGetRows(m), "%d");
    TEST("initial values should be zeroes", 0.0f, matrixGet(m, 1, 2), "%f");

    matrixSet(m, 1, 2, 1.5);
    matrixSet(m, 0, 3, 4.34);
    TEST("should set value properly #1", 1.5, matrixGet(m, 1, 2), "%f");
    TEST("should set value properly #2", (float) 4.34, matrixGet(m, 0, 3), "%f");

    Matrix m2 = matrixScale(m, 2);
    TEST("scale shouldn't change initial matrix", 1.5, matrixGet(m, 1, 2), "%f");
    TEST("should matrixScale properly #1", (float) 3, matrixGet(m2, 1, 2), "%f");
    TEST("should matrixScale properly #2", (float) 8.68, matrixGet(m2, 0, 3), "%f");

    Matrix m3 = matrixAdd(m, m2);
    TEST("should matrixSum properly #1", (float) 4.5, matrixGet(m3, 1, 2), "%f");
    TEST("should matrixSum properly #2", (float) 13.02, matrixGet(m3, 0, 3), "%f");
    TEST("should matrixSum properly #3", (float) 0, matrixGet(m3, 3, 2), "%f");

    Matrix id = matrixNew(4, 4);
    for(int i = 0; i < 4; i++) {
        matrixSet(id, i, i, 1);
    }

    Matrix muld = matrixMul(id, m);
    TEST("should return NULL if matrices cannot multiply", NULL, muld, "%d");
    matrixDelete(muld);

    muld = matrixMul(m, id);
    char is_ok = compareMatrices(m, muld);
    TEST("M * id == M", 1, is_ok, "%d");
    matrixDelete(muld);

    Matrix mtest1 = fromArray(m_test1, 2, 3);
    Matrix mtest2 = fromArray(m_test2, 2, 3);
    Matrix mtest3 = fromArray(m_test3, 3, 4);
    Matrix mans1 = fromArray(m_ans1, 2, 3);
    Matrix mans2 = fromArray(m_ans2, 2, 4);
    Matrix mans3 = fromArray(m_ans3, 3, 2);

    matrixDelete(m);
    m = matrixAdd(mtest1, mtest2);
    is_ok = compareMatrices(m, mans1);
    TEST("matrixSum corretness", 1, is_ok, "%d");

    muld = matrixMul(mtest2, mtest3);
    showMatrix(mans2);
    showMatrix(muld);

    is_ok = compareMatrices(mans2, muld);
    TEST("matrixMul corretness", 1, is_ok, "%d"); 

    matrixDelete(mtest1);
    matrixDelete(mtest2);
    matrixDelete(mtest3);
    matrixDelete(mans1);
    matrixDelete(mans2);
    matrixDelete(mans3);
    matrixDelete(muld);
    matrixDelete(m);
    matrixDelete(m2);
    matrixDelete(m3);
    return 0;
}
