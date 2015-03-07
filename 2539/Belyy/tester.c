#include <matrix.h>
#include <stdio.h>


int all_tests = 0;
int passed_tests = 0;


Matrix matrix_from_array(unsigned int rows, unsigned int cols, float values[]) {
    Matrix matrix = matrixNew(rows, cols);

    size_t array_index = 0;
    for (unsigned int i = 0; i < rows; i++) {
        for (unsigned int j = 0; j < cols; j++, array_index++) {
            matrixSet(matrix, i, j, values[array_index]);
        }
    }

    return matrix;
}

int compare_matrices(Matrix a, Matrix b) {
    if (a == NULL || b == NULL) {
        return 0;
    }
    if (matrixGetRows(a) != matrixGetRows(b) || matrixGetCols(a) != matrixGetCols(b)) {
        return 0;
    }

    unsigned int m = matrixGetRows(a);
    unsigned int n = matrixGetRows(b);

    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            if (matrixGet(a, i, j) != matrixGet(b, i, j)) {
                return 0;
            }
        }
    }

    return 1;
}


float m_one[]   = {  1,   0,   0,
                     0,   1,   0,
                     0,   0,   1        };
float m_test1[] = {  1,   2,   3,
                     4,   5,   6};
float m_test2[] = {  7,   8,   9,
                    10,  11,  12        };
float m_test3[] = {  1,   2,   3,   4,
                     5,   6,   7,   8,
                     9,  10,  11,  12   };
float m_ans1[]  = {  8,  10,  12,
                    14,  16,  18};
float m_ans2[]  = {128, 152, 176, 200,
                   173, 206, 239, 272   };


Matrix matrix_zero;
Matrix matrix_one;
Matrix matrix_test1;
Matrix matrix_test2;
Matrix matrix_test3;
Matrix matrix_ans1;
Matrix matrix_ans2;


#define TEST(test)      int result##test = test(); \
                        all_tests++; \
                        if (result##test) { \
                            passed_tests++; \
                        } else { \
                            fprintf(stderr, "FAILED: " #test "\n"); \
                        }


int zero_after_creation() {
    Matrix matrix = matrixNew(10, 15);
    unsigned int rows = matrixGetRows(matrix);
    unsigned int cols = matrixGetCols(matrix);

    int result = 1;

    for (unsigned int i = 0; i < rows; i++) {
        for (unsigned int j = 0; j < rows; j++) {
            float value = matrixGet(matrix, i, j);
            // We want bit-exact equality to zero.
            if (value != 0.0f) {
                result = 0;
                goto return_result;
            }
        }
    }

    return_result:
    matrixDelete(matrix);

    return result;
}

int matrixAdd_correctness() {
    Matrix mx_result1 = matrixAdd(matrix_zero, matrix_zero);
    Matrix mx_result2 = matrixAdd(matrix_zero, matrix_one);
    Matrix mx_result3 = matrixAdd(matrix_test3, matrix_zero);

    int result = 1;
    result *= compare_matrices(mx_result1, matrix_zero);
    result *= compare_matrices(mx_result2, matrix_one);
    if (mx_result3 != NULL) {
        result = 0;
    }

    matrixDelete(mx_result1);
    matrixDelete(mx_result2);

    return result;
}

int matrixAdd_correctness2() {
    Matrix mx_result = matrixAdd(matrix_test1, matrix_test2);

    int result = compare_matrices(mx_result, matrix_ans1);

    matrixDelete(mx_result);

    return result;
}

int matrixMul_correctness() {
    Matrix mx_result1 = matrixMul(matrix_one, matrix_one);
    Matrix mx_result2 = matrixMul(matrix_test2, matrix_one);
    Matrix mx_result3 = matrixMul(matrix_one, matrix_test3);
    Matrix mx_result4 = matrixMul(matrix_one, matrix_test1);

    int result = 1;
    result *= compare_matrices(mx_result1, matrix_one);
    result *= compare_matrices(mx_result2, matrix_test2);
    result *= compare_matrices(mx_result3, matrix_test3);
    if (mx_result4 != NULL) {
        result = 0;
    }

    matrixDelete(mx_result1);
    matrixDelete(mx_result2);
    matrixDelete(mx_result3);

    return result;
}

int matrixMul_correctness2() {
    Matrix mx_result = matrixMul(matrix_test2, matrix_test3);

    int result = compare_matrices(mx_result, matrix_ans2);

    matrixDelete(mx_result);

    return result;
}


int main() {
    // Fill in test matrices.
    matrix_zero = matrixNew(3, 3);
    matrix_one = matrix_from_array(3, 3, m_one);
    matrix_test1 = matrix_from_array(2, 3, m_test1);
    matrix_test2 = matrix_from_array(2, 3, m_test2);
    matrix_test3 = matrix_from_array(3, 4, m_test3);
    matrix_ans1 = matrix_from_array(2, 3, m_ans1);
    matrix_ans2 = matrix_from_array(2, 4, m_ans2);

    // Run tests.
    TEST(zero_after_creation);
    TEST(matrixAdd_correctness);
    TEST(matrixAdd_correctness2);
    TEST(matrixMul_correctness);
    TEST(matrixMul_correctness2);

    // Delete test matrices.
    matrixDelete(matrix_zero);
    matrixDelete(matrix_one);
    matrixDelete(matrix_test1);
    matrixDelete(matrix_test2);
    matrixDelete(matrix_test3);
    matrixDelete(matrix_ans1);
    matrixDelete(matrix_ans2);

    // Show the results.
    printf("Passed tests: %d/%d\n", passed_tests, all_tests);
    return 0;
}
