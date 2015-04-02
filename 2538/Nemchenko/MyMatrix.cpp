#include <iostream>
#include <cstdio>
#include <algorithm>
#include <vector>
#include "MyMatrix.hpp"

MyMatrix MyMatrix::NULL_MATRIX(0, 0);

MyMatrix::MyMatrix(unsigned int rows, unsigned int cols) {
    matrix.resize(rows, std::vector<double>(cols));
}

MyMatrix::MyMatrix(MyMatrix&& rhs) {
    matrix = std::move(rhs.matrix);
}

MyMatrix::MyMatrix(MyMatrix const&) = default;

unsigned int MyMatrix::getRows() const {
    return matrix.size();
}

unsigned int MyMatrix::getCols() const {
    return matrix[0].size();
}

double& MyMatrix::operator()(unsigned int row, unsigned int col) {
    return matrix[row][col];
}

double MyMatrix::operator()(unsigned int row, unsigned int col) const {
    return matrix[row][col];
}

MyMatrix& MyMatrix::operator*(float scale) {
    for (sz_t i = 0; i < getRows(); ++i) {
        for (double& value : matrix[i]) {
            value *= scale;
        }
    }
    return *this;
}

MyMatrix MyMatrix::operator+(MyMatrix const& rhs) const {
    if (getRows() != rhs.getRows() || getCols() != rhs.getCols()) {
        return NULL_MATRIX;
    }

    MyMatrix result(getCols(), getRows());
    for (sz_t i = 0; i < getCols(); ++i) {
        for (sz_t j = 0; j < getRows(); ++j) {
            result (i, j) = matrix[i][j] + rhs (i, j);
        }
    }
    return result;
}

MyMatrix MyMatrix::operator*(MyMatrix const& rhs) const {
    if (getCols() != rhs.getRows()) {
        return NULL_MATRIX;
    }

    MyMatrix result(getRows(), rhs.getCols());

    for (sz_t resRow = 0; resRow < getRows(); ++resRow)
        for (sz_t resCol = 0; resCol < rhs.getCols(); ++resCol)
            for (sz_t i = 0; i < getCols(); ++i)
                result (resRow, resCol) += matrix[resRow][i] * rhs (i, resCol);
    return result;
}

MyMatrix& operator*(float scale, MyMatrix& matrix) {
    return matrix * scale;
}

std::ostream& operator<<(std::ostream& out, MyMatrix const& matrix) {
    for (MyMatrix::sz_t i = 0; i < matrix.getRows(); ++i) {
        for (MyMatrix::sz_t j = 0; j < matrix.getCols(); ++j) {
            out << matrix (i, j) << ' ';
        }
        out << std::endl;
    }
    return out;
}
