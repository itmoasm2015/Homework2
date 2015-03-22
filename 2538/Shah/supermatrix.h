#ifndef SUPER_MATRIX_H_
#define SUPER_MATRIX_H_
#include <iostream>
#include "matrix.h"

class SuperMatrix
{
    float** values;
    size_t rows;
    size_t cols;

public:
    SuperMatrix(Matrix m);
    SuperMatrix(int n, int m);
    ~SuperMatrix();
    SuperMatrix(const SuperMatrix& sm);
    SuperMatrix& operator=(const SuperMatrix& sm);

    bool equals(Matrix m);
    SuperMatrix scale(float value);
    SuperMatrix add(const SuperMatrix& m);
    SuperMatrix mul(const SuperMatrix& m);

    unsigned int getRows() const 
    {
        return rows;
    }
    
    unsigned int getCols() const 
    {
        return cols;
    }

    float get(unsigned int i, unsigned int j) const
    {
        return values[i][j];
    }

    void set(unsigned int i, unsigned int j, float value) const
    {
        values[i][j] = value;
    }

};
#endif
