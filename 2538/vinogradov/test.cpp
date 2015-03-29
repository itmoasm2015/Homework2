#include "include/matrix.h"
#include <iostream>
#include <climits>
#include <cassert>
#include <cmath>

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
    assert((size_t)mat.values%16 == 0);
  }

  Cmat(unsigned rows, unsigned cols)
      : Cmat(matrixNew(rows, cols)) {
    assert(mat.rows == rows);
    assert(mat.cols == cols);
    assert((size_t)mat.values%16 == 0);
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
    get(i, j);
  }

  Cmat scale(float k) {
    Cmat b = Cmat(matrixScale(mat, k));
    assert(b.rows == rows);
    assert(b.cols == cols);
    for (unsigned i=0; i<rows; i++) {
      for (unsigned j=0; j<cols; j++) {
	float exp = k*really_at(i,j);
	float got = b.really_at(i,j);
	//printf("%u %u exp:%f got:%f\n", i, j, exp, got);
	assert(exp == got);
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
  cout << "cadd\n";
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
      assert(x == y+z);
    }
  }
  return res;
}

Cmat cmul(Cmat a, Cmat b) {
  cout << "cmul\n";
  const float EPS = 1e-3;
  assert(a.cols == b.rows);
  Cmat res = Cmat(matrixMul(a.mat, b.mat));
  assert(res.rows == a.rows);
  assert(res.cols == b.cols);
  for (unsigned i=0; i<a.rows; i++) {
    for (unsigned j=0; j<b.cols; j++) {
      float val = 0;
      for (unsigned k=0; k<a.cols; k++) {
	float x = a.really_at(i,k);
	float y = b.really_at(k,j);
	val += x*y;
      }
      float z = res.really_at(i,j);
      float df = val == 0 ? abs(z) : abs(z-val)/val;
      //cout << val << " ";
      //printf("%u %u exp:%f got:%f df:%f\n", i, j, val, z, df);
      assert(df < EPS);
    }
    //cout << "\n";
  }
  return res;
}

float random_float() {
  return static_cast<float>(rand());
}

void random_fill(Cmat v) {
  for (unsigned i=0; i<v.rows; i++) {
    for (unsigned j=0; j<v.cols; j++) {
      v.set(i, j, random_float());
    }
  }
}

int main() {
  const unsigned A=129;
  const unsigned B=311;
  const unsigned C=412;
  Cmat a(A, B);
  Cmat b(B, C);
  random_fill(a);
  random_fill(b);
  Cmat c = a.scale(-1.32);
  Cmat d = cadd(a, c);
  Cmat e = cmul(a, b);
  a.del();
  b.del();
  c.del();
  d.del();
  e.del();
  return 0;
}
