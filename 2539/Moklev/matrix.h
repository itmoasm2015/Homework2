#ifndef MATRIX_H
#define MATRIX_H

typedef struct {
    unsigned int rows;
    unsigned int cols;
    float* data;
} *Matrix;

Matrix matrixNew(unsigned int rows, unsigned int cols);
void matrixDelete(Matrix matrix);
unsigned int matrixGetRows(Matrix matrix);
unsigned int matrixGetCols(Matrix matrix);
float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
Matrix matrixScale(Matrix matrix, float k);
Matrix matrixAdd(Matrix a, Matrix b);
Matrix matrixMul(Matrix a, Matrix b);

#endif // MATRIX_H
