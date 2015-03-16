#ifndef __H_MATRIX
#define __H_MATRIX
#include <cstdio>
struct Matrix {
  float *values;
  unsigned int rows, cols;
};
extern "C" Matrix matrixNew(unsigned int rows, unsigned int cols);
extern "C" void matrixDelete(Matrix matrix);
extern "C" unsigned int matrixGetRows(Matrix matrix);
extern "C" unsigned int matrixGetCols(Matrix matrix);
extern "C" float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
extern "C" void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
extern "C" Matrix matrixScale(Matrix matrix, float k);
extern "C" Matrix matrixAdd(Matrix a, Matrix b);
extern "C" Matrix matrixMul(Matrix a, Matrix b);
#endif
