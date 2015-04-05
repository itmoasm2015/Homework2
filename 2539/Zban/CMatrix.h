#ifndef _HOMEWORK2_CMATRIX_H
#define _HOMEWORK2_CMATRIX_H

#include <stdio.h>
#include <algorithm>

#ifdef __cplusplus
extern "C" {
#endif

struct CMatrix {
    float** data;
    unsigned int n;
    unsigned int m;

    CMatrix(unsigned int n, unsigned int m);
    void swap(CMatrix& rhs);
    CMatrix& operator=(const CMatrix& rhs);
    CMatrix(const CMatrix& rhs);
    unsigned int getRows();
    unsigned int getCols();
    float* operator[](unsigned int id);
    CMatrix operator*(float value);
    CMatrix operator+(CMatrix &rhs);
    CMatrix operator*(CMatrix &rhs);
    ~CMatrix();
    void print();
};

#ifdef __cplusplus
}
#endif
#endif
