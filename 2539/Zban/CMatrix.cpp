#include "CMatrix.h"
#include <stdlib.h>
#include <assert.h>

CMatrix::CMatrix(unsigned int n, unsigned int m) {
    this->n = n;
    this->m = m;
    this->data = new float*[n];
    for (int i = 0; i < n; i++) {
        this->data[i] = new float[m];
        for (int j = 0; j < m; j++) {
            data[i][j] = 0;
        }
    }
}

void CMatrix::swap(CMatrix& rhs) {
	std::swap(n, rhs.n);
	std::swap(m, rhs.m);
	std::swap(data, rhs.data);
}

CMatrix& CMatrix::operator=(const CMatrix& rhs) {
	CMatrix tmp(rhs);
	swap(tmp);
	return *this;
}

CMatrix::CMatrix(const CMatrix& rhs) {
    this->n = rhs.n;
    this->m = rhs.m;
	data = new float*[n];
	for (int i = 0; i < n; i++) {
		data[i] = new float[m];
		for (int j = 0; j < m; j++) {
			data[i][j] = rhs.data[i][j];
        }
	}
}

unsigned int CMatrix::getRows() {
    return n;
}

unsigned int CMatrix::getCols() {
    return m;
}

float* CMatrix::operator[](unsigned int id) {
    return data[id];
}

CMatrix CMatrix::operator*(float value) {
    CMatrix result(n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            result[i][j] = data[i][j] * value;
        }
    }
    return result;
}

CMatrix CMatrix::operator+(CMatrix &rhs) {
    if (n != rhs.n || m != rhs.m) assert(0);
    CMatrix result(n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            result[i][j] = data[i][j] + rhs[i][j];
        }
    }
    return result;
}

CMatrix CMatrix::operator*(CMatrix &rhs) {
    if (m != rhs.n) assert(0);
    CMatrix result(n, rhs.m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < rhs.m; j++) {
            for (int k = 0; k < m; k++) {
                result[i][j] += data[i][k] * rhs[k][j];
            }
        }
    }
    return result;
}


CMatrix::~CMatrix() {
    for (int i = 0; i < n; i++) delete[] data[i];
    delete[] data;
}

void CMatrix::print() {
    printf("%d %d\n", n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            printf("%.3f%c", data[i][j], " \n"[j + 1 == m]);
        }
    }
}
