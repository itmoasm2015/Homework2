#include "supermatrix.h"
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cmath>

SuperMatrix::SuperMatrix(int n, int m)
{
    values = new float*[n];
    rows = n;
    cols = m;
    for (size_t i = 0; i < rows; i++)
    {
        values[i] = new float[m];
    }
}

SuperMatrix::SuperMatrix(Matrix m)
{
    rows = matrixGetRows(m);
    cols = matrixGetCols(m);
    values = new float*[rows];
    for (size_t i = 0; i < rows; i++)
    {
        values[i] = new float[cols];
        for (size_t j = 0; j < cols; j++)
        {
            values[i][j] = matrixGet(m, i, j);
        }
    }
}

SuperMatrix::~SuperMatrix()
{
    for (size_t i = 0; i < rows; i++)
    {
        delete[] values[i];
    }
    delete[] values;
}

SuperMatrix::SuperMatrix(const SuperMatrix& sm) 
    : SuperMatrix((int)sm.rows, (int)sm.cols)
{
    for (size_t i = 0; i < rows; i++)
    {
        for (size_t j = 0; j < cols; j++)
        {
            values[i][j] = sm.get(i, j);
        }
    }
}

SuperMatrix& SuperMatrix::operator=(const SuperMatrix& sm)
{
    SuperMatrix t(sm);
    std::swap(rows, t.rows);
    std::swap(cols, t.cols);
    std::swap(values, t.values);
    return *this;
}


bool SuperMatrix::equals(Matrix m)
{
    for (size_t i = 0; i < rows; i++)
    {
        for (size_t j = 0; j < cols; j++)
        {
            if (fabs(values[i][j] - matrixGet(m, i, j)) > 0.01)
            {
                printf("Matrix diffs %zu %zu SuperValue: %.3f value: %.3f", i, j, values[i][j], matrixGet(m, i,j));
                return false;
            }
        }
    }
    return true;
}

SuperMatrix SuperMatrix::scale(float value)
{
    SuperMatrix tmp(rows, cols);
    for (size_t i = 0; i < rows; i++)
    {
        for (size_t j = 0; j < cols; j++)
        {
            tmp.values[i][j] = values[i][j] * value;
        }
    }
    return tmp;
}

SuperMatrix SuperMatrix::add(const SuperMatrix& sm)
{
    SuperMatrix tmp(rows, cols);
    for (size_t i = 0; i < rows; i++)
    {
        for (size_t j = 0; j < cols; j++)
        {
            tmp.values[i][j] = values[i][j] + sm.values[i][j];
        }
    }
    return tmp;
}

SuperMatrix SuperMatrix::mul(const SuperMatrix& sm)
{
    SuperMatrix tmp(rows, sm.cols);
    for (size_t i = 0; i < rows; i++)
    {
        for (size_t j = 0; j < sm.cols; j++)
        {
            tmp.values[i][j] = 0;
            for (size_t k = 0; k < cols; k++)
            {
                tmp.values[i][j] += values[i][k] * sm.values[k][j];
            }
        }
    }
    return tmp;
}
