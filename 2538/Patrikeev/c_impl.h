#ifndef _HOMEWORK2_C_MATRIX_H
#define _HOMEWORK2_C_MATRIX_H

typedef void * Matrix;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Create new matrix and fill it with zeros.
 * \return new matrix or 0 if out of memory.
 */
Matrix c_matrixNew(unsigned int rows, unsigned int cols);

/**
 * Destroy matrix previously allocated by matrixNew(), matrixScale(),
 * matrixAdd() or matrixMul().
 */
void c_matrixDelete(Matrix matrix);

/**
 * Get number of rows in a matrix.
 */
unsigned int c_matrixGetRows(Matrix matrix);

/**
 * Get number of columns in a matrix.
 */
unsigned int c_matrixGetCols(Matrix matrix);

/**
 * Get matrix element.
 */
float c_matrixGet(Matrix matrix, unsigned int row, unsigned int col);

/**
 * Set matrix element.
 */
void c_matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);

/**
 * Multiply matrix by a scalar.
 * \return new matrix.
 */
Matrix c_matrixScale(Matrix matrix, float k);

/**
 * Add two matrices.
 * \return new matrix or 0 if the sizes don't match. 
 */
Matrix c_matrixAdd(Matrix a, Matrix b);

/**
 * Multiply two matrices.
 * \return new matrix or 0 if the sizes don't match.
 */
Matrix c_matrixMul(Matrix a, Matrix b);


#ifdef __cplusplus
}
#endif
#endif