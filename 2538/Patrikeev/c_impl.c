#include "c_impl.h"
#include <stdio.h>
#include <stdlib.h>

struct Matrix_t {
    unsigned int rows;
    unsigned int cols;
    float * array;
};

/**
 * Create new matrix and fill it with zeros.
 * \return new matrix or 0 if out of memory.
 */
Matrix c_matrixNew(unsigned int rows, unsigned int cols) {
    struct Matrix_t * matrix = (struct Matrix_t*) calloc(1, sizeof(struct Matrix_t));
    if (matrix == NULL) {
        return 0;
    }
    matrix->array = (float*) calloc(rows * cols, sizeof(float));
    if (matrix->array == NULL) {
        return 0;
    }
    matrix->rows = rows;
    matrix->cols = cols;
    return matrix;
}

/**
 * Destroy matrix previously allocated by matrixNew(), matrixScale(),
 * matrixAdd() or matrixMul().
 */
void c_matrixDelete(Matrix matrix) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    free(mx->array);
    free(mx);
}

/**
 * Get number of rows in a matrix.
 */
unsigned int c_matrixGetRows(Matrix matrix) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    return mx->rows;
}

/**
 * Get number of columns in a matrix.
 */
unsigned int c_matrixGetCols(Matrix matrix) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    return mx->cols;
}

/**
 * Get matrix element.
 */
float c_matrixGet(Matrix matrix, unsigned int row, unsigned int col) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    unsigned int cols = mx->cols;
    return mx->array[row * cols + col];
}

/**
 * Set matrix element.
 */
void c_matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    unsigned int cols = mx->cols;
    mx->array[row * cols + col] = value;
}

/**
 * Multiply matrix by a scalar.
 * \return new matrix.
 */
Matrix c_matrixScale(Matrix matrix, float k) {
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    unsigned int cols = mx->cols;
    unsigned int rows = mx->rows;
    struct Matrix_t * result = c_matrixNew(rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result->array[i * cols + j] = mx->array[i * cols + j] * k;
        }
    }
    return result;
}

/**
 * Add two matrices.
 * \return new matrix or 0 if the sizes don't match. 
 */
Matrix c_matrixAdd(Matrix a, Matrix b) {
    struct Matrix_t * matrixA = (struct Matrix_t *) a;
    struct Matrix_t * matrixB = (struct Matrix_t *) b;
    if (matrixA->rows != matrixB->rows || matrixA->cols != matrixB->cols) {
        return 0;
    }
    unsigned int rows = matrixA->rows;
    unsigned int cols = matrixA->cols;
    struct Matrix_t * result = c_matrixNew(rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result->array[i * cols + cols] = matrixA->array[i * cols + cols] + matrixB->array[i * cols + cols];
        }
    }
    return result;
}

/**
 * Multiply two matrices.
 * \return new matrix or 0 if the sizes don't match.
 */
Matrix c_matrixMul(Matrix a, Matrix b);