#include <matrix.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>


float eps = 1e-6;

int all_tests = 0;
int passed_tests = 0;

// Asm imports.
Matrix matrixTranspose(Matrix matrix);
// C imports.
Matrix c_matrixNew(unsigned int rows, unsigned int cols);
Matrix c_matrixSet(Matrix a, unsigned int row, unsigned int col, float value);
Matrix c_matrixMul(Matrix a, Matrix b);
float c_matrixGet(Matrix a, unsigned int row, unsigned int col);
void c_matrixDelete(Matrix matrix);

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

    for (unsigned int i = 0; i < m; i++) {
        for (unsigned int j = 0; j < n; j++) {
            if (fabs(matrixGet(a, i, j) - matrixGet(b, i, j)) > eps) {
                return 0;
            }
        }
    }

    return 1;
}

void output_matrix(Matrix matrix) {
    if (matrix == NULL) {
        printf("(NULL)\n");
        return;
    }

    unsigned int m = matrixGetRows(matrix);
    unsigned int n = matrixGetCols(matrix);

    printf("(%ux%u)\n", m, n);
    for (unsigned int i = 0; i < m; i++) {
        for (unsigned int j = 0; j < n; j++) {
            float value = matrixGet(matrix, i, j);
            printf("%f\t", value);
        }
        printf("\n");
    }
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
float m_ans3[]  = {  1,   4,
                     2,   5,
                     3,   6             };


Matrix matrix_zero;
Matrix matrix_one;
Matrix matrix_test1;
Matrix matrix_test2;
Matrix matrix_test3;
Matrix matrix_ans1;
Matrix matrix_ans2;
Matrix matrix_ans3;


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
        for (unsigned int j = 0; j < cols; j++) {
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

int matrixScale_correctness() {
    Matrix mx_result1 = matrixScale(matrix_zero, 3.14159);
    Matrix mx_result2 = matrixScale(matrix_test2, 1.0);
    Matrix mx__helper = matrixScale(matrix_test3, 2.0);
    Matrix mx_result3 = matrixScale(mx__helper, 0.5);

    int result = 1;
    result *= compare_matrices(mx_result1, matrix_zero);
    result *= compare_matrices(mx_result2, matrix_test2);
    result *= 1 - compare_matrices(mx__helper, matrix_test3);
    result *= compare_matrices(mx_result3, matrix_test3);
    if (mx_result1 == matrix_zero) {
        result = 0;
    }

    matrixDelete(mx_result1);
    matrixDelete(mx_result2);
    matrixDelete(mx__helper);
    matrixDelete(mx_result3);

    return result;
}

int matrixAdd_correctness() {
    Matrix mx_result1 = matrixAdd(matrix_zero, matrix_zero);
    Matrix mx_result2 = matrixAdd(matrix_zero, matrix_one);
    Matrix mx_result3 = matrixAdd(matrix_test3, matrix_zero);

    int result = 1;
    result *= compare_matrices(mx_result1, matrix_zero);
    result *= compare_matrices(mx_result2, matrix_one);
    if (mx_result1 == matrix_zero) {
        result = 0;
    }
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

int matrixTranspose_correctness() {
    Matrix mx_result1 = matrixTranspose(matrix_one);
    Matrix mx_result2 = matrixTranspose(matrix_test1);

    int result = 1;
    result *= compare_matrices(mx_result1, matrix_one);
    result *= compare_matrices(mx_result2, matrix_ans3);
    if (mx_result1 == matrix_one) {
        result = 0;
    }

    matrixDelete(mx_result1);

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
    if (mx_result1 == matrix_one) {
        result = 0;
    }
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

int matrixMul_performance() {
    unsigned int m = rand() % 750 + 250;
    unsigned int n = rand() % 750 + 250;
    unsigned int p = rand() % 750 + 250;
    Matrix mx_asm_a = matrixNew(m, n);
    Matrix mx_asm_b = matrixNew(n, p);
    Matrix mx_c_a = c_matrixNew(m, n);
    Matrix mx_c_b = c_matrixNew(n, p);
    
    // Initialization.
    for (unsigned int i = 0; i < m; i++) {
        for (unsigned int j = 0; j < n; j++) {
            float value = (float) (rand() % 1000) - 500.0;
            matrixSet(mx_asm_a, i, j, value);
            c_matrixSet(mx_c_a, i, j, value);
        }
    }
    for (unsigned int i = 0; i < n; i++) {
        for (unsigned int j = 0; j < p; j++) {
            float value = (float) (rand() % 1000) - 500.0;
            matrixSet(mx_asm_b, i, j, value);
            c_matrixSet(mx_c_b, i, j, value);
        }
    }

    clock_t start = clock();
    // Asm multiplication.
    Matrix mx_asm_result = matrixMul(mx_asm_a, mx_asm_b);
    clock_t after_asm = clock();
    // C multiplication.
    Matrix mx_c_result = c_matrixMul(mx_c_a, mx_c_b);
    clock_t after_c = clock();

    // Check asm results for correctness.
    int correct = 1;
    if (mx_asm_result == NULL) {
        correct = 0;
    }
    if (correct && (matrixGetRows(mx_asm_result) != m
                 || matrixGetCols(mx_asm_result) != p)) {
        correct = 0;
    }
    for (unsigned int i = 0; i < m && correct; i++) {
        for (unsigned int j = 0; j < p && correct; j++) {
            if (fabs(matrixGet(mx_asm_result, i, j) - c_matrixGet(mx_c_result, i, j)) > eps) {
                correct = 0;
            }
        }
    }

    // Show the results.
    if (correct) {
        printf("Asm multiplication time: %.3lfs\n", (double) (after_asm - start) / CLOCKS_PER_SEC);
        printf("C multiplication time: %.3lfs\n", (double) (after_c - after_asm) / CLOCKS_PER_SEC);
    }

    // Cleanup. 
    c_matrixDelete(mx_c_a);
    c_matrixDelete(mx_c_b);
    c_matrixDelete(mx_c_result);
    matrixDelete(mx_asm_a);
    matrixDelete(mx_asm_b);
    matrixDelete(mx_asm_result);

    return correct;
}


int main() {
    // Initialize random needed for performance tests.
    srand(time(NULL));

    // Fill in test matrices.
    matrix_zero = matrixNew(3, 3);
    matrix_one = matrix_from_array(3, 3, m_one);
    matrix_test1 = matrix_from_array(2, 3, m_test1);
    matrix_test2 = matrix_from_array(2, 3, m_test2);
    matrix_test3 = matrix_from_array(3, 4, m_test3);
    matrix_ans1 = matrix_from_array(2, 3, m_ans1);
    matrix_ans2 = matrix_from_array(2, 4, m_ans2);
    matrix_ans3 = matrix_from_array(3, 2, m_ans3);

    // Run tests.
    TEST(zero_after_creation);
    TEST(matrixScale_correctness);
    TEST(matrixAdd_correctness);
    TEST(matrixAdd_correctness2);
    TEST(matrixTranspose_correctness);
    TEST(matrixMul_correctness);
    TEST(matrixMul_correctness2);
    TEST(matrixMul_performance);

    // Delete test matrices.
    matrixDelete(matrix_zero);
    matrixDelete(matrix_one);
    matrixDelete(matrix_test1);
    matrixDelete(matrix_test2);
    matrixDelete(matrix_test3);
    matrixDelete(matrix_ans1);
    matrixDelete(matrix_ans2);
    matrixDelete(matrix_ans3);

    // Show the results.
    printf("Passed tests: %d/%d\n", passed_tests, all_tests);
    return 0;
}
