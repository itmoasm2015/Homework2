#ifndef _HOMEWORK2_MATRIX_H
#define _HOMEWORK2_MATRIX_H

typedef void * Matrix;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Create new matrix and fill it with zeros.
 * \return new matrix or 0 if out of memory.
 */
Matrix matrixNew(unsigned int rows, unsigned int cols);

/**
 * Destroy matrix previously allocated by matrixNew(), matrixScale(),
 * matrixAdd() or matrixMul().
 */
void matrixDelete(Matrix matrix);

/**
 * Get number of rows in a matrix.
 */
unsigned int matrixGetRows(Matrix matrix);

/**
 * Get number of columns in a matrix.
 */
unsigned int matrixGetCols(Matrix matrix);

/**
 * Get matrix element.
 */
float matrixGet(Matrix matrix, unsigned int row, unsigned int col);

/**
 * Set matrix element.
 */
void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);

/**
 * Multiply matrix by a scalar.
 * \return new matrix.
 */
Matrix matrixScale(Matrix matrix, float k);

/**
 * Add two matrices.
 * \return new matrix or 0 if the sizes don't match. 
 */
Matrix matrixAdd(Matrix a, Matrix b);

/**
 * Multiply two matrices.
 * \return new matrix or 0 if the sizes don't match.
 */
Matrix matrixMul(Matrix a, Matrix b);



#ifdef __cplusplus
}
#endif
#endif