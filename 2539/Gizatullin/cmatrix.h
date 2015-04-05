#ifndef CMATRIX_H
#define CMATRIX_H
#include <iostream>
#include "matrix.h"

class CMatrix
{
    float** a;
    
    size_t rows;
    size_t cols;

public:

    CMatrix(int n, int m);

    CMatrix(Matrix other);
    
    CMatrix(const CMatrix& other);
    
    ~CMatrix();
    
    CMatrix& operator=(const CMatrix& other);

    bool equals(Matrix other);
    
    
    CMatrix scale(float value);
    
    CMatrix add(const CMatrix& other);
    
    CMatrix mul(const CMatrix& other);

    
    unsigned int getCols() const 
    {
        return cols;
    }

    unsigned int getRows() const 
    {
        return rows;
    }    

    void set(unsigned int i, unsigned int j, float value) const
    {
        a[i][j] = value;
    }

    float get(unsigned int i, unsigned int j) const
    {
        return a[i][j];
    }
};

#endif
