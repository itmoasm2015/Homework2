#include <matrix.h>
#include <stdlib.h>


struct Matrix_t {
    unsigned int rows;
    unsigned int cols;
    float * cells;
};


Matrix c_matrixNew(unsigned int rows, unsigned int cols) {
    struct Matrix_t * mx = malloc(sizeof(struct Matrix_t));
    
    mx->rows = rows;
    mx->cols = cols;

    // TODO : use efficient memory setting
    size_t mx_size = (size_t) rows * cols;
    mx->cells = malloc(sizeof(float) * mx_size);
    for (size_t i = 0; i < mx_size; i++) {
        mx->cells[i] = 0.0f;
    }
    
    return mx;
}

Matrix c_matrixClone(Matrix matrix) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    struct Matrix_t * new_mx = c_matrixNew(mx->rows, mx->cols);

    // TODO : use efficient memory copying
    size_t mx_size = (size_t) mx->rows * mx->cols;
    for (size_t i = 0; i < mx_size; i++) {
        new_mx->cells[i] = mx->cells[i];
    }
    
    return new_mx;
}

void c_matrixDelete(Matrix matrix) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;

    free(mx->cells);
    free(mx);
}

unsigned int c_matrixGetRows(Matrix matrix) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;

    return mx->rows;
}

unsigned int c_matrixGetCols(Matrix matrix) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;

    return mx->cols;
}

float c_matrixGet(Matrix matrix, unsigned int row, unsigned int col) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    size_t index = (size_t) row * mx->cols + col;

    return mx->cells[index];
}

void c_matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * mx = (struct Matrix_t *) matrix;
    size_t mx_index = (size_t) row * mx->cols + col;

    mx->cells[mx_index] = value;
}

Matrix c_matrixScale(Matrix matrix, float k) {
    // Assuming `matrix` points to a valid object.
    struct Matrix_t * new_mx = c_matrixClone(matrix);
    size_t mx_size = (size_t) new_mx->rows * new_mx->cols;

    for (size_t i = 0; i < mx_size; i++) {
        new_mx->cells[i] *= k;
    }

    return new_mx;
}

Matrix c_matrixAdd(Matrix a, Matrix b) {
    // Assuming both `a` and `b` point to valid objects.
    struct Matrix_t * mx_a = (struct Matrix_t *) a;
    struct Matrix_t * mx_b = (struct Matrix_t *) b;

    if (mx_a->rows != mx_b->rows || mx_a->cols != mx_b->cols) {
        return NULL;
    }

    struct Matrix_t * new_mx = c_matrixClone(a);
    size_t mx_size = (size_t) new_mx->rows * new_mx->cols;

    for (size_t i = 0; i < mx_size; i++) {
        new_mx->cells[i] += mx_b->cells[i];
    }

    return new_mx;
}

Matrix c_matrixMul(Matrix a, Matrix b) {
    // Assuming both `a` and `b` point to valid objects.
    struct Matrix_t * mx_a = (struct Matrix_t *) a;
    struct Matrix_t * mx_b = (struct Matrix_t *) b;

    if (mx_a->cols != mx_b->rows) {
        return NULL;
    }

    unsigned int m = mx_a->rows;
    unsigned int n = mx_a->cols;
    unsigned int p = mx_b->cols;

    struct Matrix_t * new_mx = c_matrixNew(m, p);

    size_t mx_index = 0;
    for (unsigned int i = 0; i < m; i++) {
        for (unsigned int j = 0; j < p; j++, mx_index++) {
            for (unsigned int k = 0; k < n; k++) {
                size_t mx_a_index = (size_t) i * n + k;
                size_t mx_b_index = (size_t) k * p + j;
                new_mx->cells[mx_index] += mx_a->cells[mx_a_index] * mx_b->cells[mx_b_index];
            }
        }
    }

    return new_mx;
}
