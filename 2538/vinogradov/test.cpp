#include "include/matrix.h"
#include <iostream>
#include <climits>
#include <cassert>

using namespace std;

struct Cmat {
  Matrix mat;
  unsigned rows, cols;
  unsigned rcols;

  Cmat(Matrix mat)
    : mat(mat)
    , rows(mat.rows)
    , cols(mat.cols)
    , rcols(((cols-1)&(~3))+4) {
    assert(mat.rows == matrixGetRows(mat));
    assert(mat.cols == matrixGetCols(mat));
  }

  Cmat(unsigned rows, unsigned cols)
      : Cmat(matrixNew(rows, cols)) {
    assert(mat.rows == rows);
    assert(mat.cols == cols);
    for (unsigned i=0; i<rows; i++) {
      for (unsigned j=0; j<rcols; j++) {
	assert(really_at(i,j) == 0);
      }
    }
  }

  float really_at(unsigned i, unsigned j) {
    assert(i<rows);
    assert(j<rcols);
    return mat.values[i*rcols+j];
  }

  float get(unsigned i, unsigned j) {
    float res = matrixGet(mat, i, j);
    assert(res == really_at(i,j));
    return res;
  }

  void set(unsigned i, unsigned j, float value) {
    matrixSet(mat, i, j, value);
    assert(really_at(i,j) == value);
  }

  Cmat scale(float k) {
    Cmat b = Cmat(matrixScale(mat, k));
    assert(b.rows == rows);
    assert(b.cols == cols);
    for (unsigned i=0; i<rows; i++) {
      for (unsigned j=0; j<cols; j++) {
	cout << i << " " << j << " " << really_at(i,j) << " " << b.really_at(i,j) << "\n";
	assert(k*really_at(i, j)==b.really_at(i,j));
      }
    }
    return b;
  }

  void print() {
    cout << "matrix " << rows << "×" << cols << ":\n";
    for (unsigned i=0; i<rows; i++) {
      for (unsigned j=0; j<cols; j++) {
	cout << really_at(i, j) << " ";
      }
      cout << "\n";
    }
  }

  void del() {
    matrixDelete(mat);
  }
};

Cmat cadd(Cmat a, Cmat b) {
  assert(a.rows == b.rows);
  assert(a.cols == b.cols);
  Cmat res = Cmat(matrixAdd(a.mat, b.mat));
  assert(res.rows == a.rows);
  assert(res.cols == a.cols);
  for (unsigned i=0; i<a.rows; i++) {
    for (unsigned j=0; j<a.cols; j++) {
      float x = res.really_at(i,j);
      float y =   a.really_at(i,j);
      float z =   b.really_at(i,j);
      cout << i << " " << j << " " << x << " " << y << " " << z << "\n";
    }
  }
  return res;
}

int main() {
  const unsigned A=17, B=11;
  Cmat a(A, B);
  for (unsigned i=0; i<A; i++) {
    for (unsigned j=0; j<B; j++) {
      float fi = float(i);
      float fj = float(j);
      a.set(i, j, (fi-fj)/2);
    }
  }
  a.print();
  Cmat b = a.scale(9.99);
  b.print();
  Cmat c = cadd(a, b);
  c.print();
  a.del();
  b.del();
  c.del();
  return 0;
}
