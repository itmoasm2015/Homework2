#include "tmatrix.h"
#include "matrix.h"
#include <cstdio>
#include <cmath>
#include <cstdlib>
const int N = 2;
const int M = 2;

#ifdef __cplusplus
extern "C" {
#endif
Matrix matrixTranspose(Matrix a);
#ifdef __cplusplus
}
#endif

bool equals(const Matrix& a, const TMatrix& b) {
	if (matrixGetRows(a) != b.rows() || matrixGetCols(a) != b.cols())
		return false;
	int n = b.rows();
	int m = b.cols();
	for (int i = 0; i < n; ++i) 
		for (int j = 0; j < m; ++j)
            if (fabs(b.get(i, j) - matrixGet(a, i, j)) > 0.01)
                return false;
    return true;
}

Matrix randMatrxix(int n, int m) {
	Matrix ret = matrixNew(n, m);
	for (int i = 0; i < n; ++i)
		for (int j = 0; j < m; ++j)
			matrixSet(ret, i, j, float(rand() * 1.0 / RAND_MAX));
	return ret;
}

TMatrix randTMatrxix(int n, int m) {
	TMatrix ret(n, m);
	for (int i = 0; i < n; ++i)
		for (int j = 0; j < m; ++j)
			ret.set(i, j, float(rand() * 1.0 / RAND_MAX));
	return ret;
}

TMatrix toTMatrix(Matrix a) {
	
}

int main() {
    Matrix a = randMatrxix(2, 3);
    Matrix b = randMatrxix(3, 5);
	
	/*printf("%d %d\n", matrixGetRows(a), matrixGetCols(a));
    if (!equals(a, b)) {
        printf("\n===diff after set===\n");
        return 0;
    }
    
    printf("scale testing...\n");
    fflush(stdout);
    b = b.scale(13.52);
    a = matrixScale(a, 13.52);
    if (!equals(a, b)) {
        printf("\n===diff after scale===\n");
        return 0;
    }
    
    printf("add testing...\n");
    fflush(stdout);
    a = matrixAdd(a, c);
    b = b.add(d);
    
        if (!equals(a, b)) {
        printf("\n===diff after add===\n");
        return 0;
    }*/
    
    /*printf("transpose testing...\n");
    fflush(stdout);
    TMatrix ans = TMatrix(b).transpose();
	a = matrixTranspose(b);
	printf("%d %d\n", ans.rows(), ans.cols());
	for (int i = 0; i < ans.rows(); ++i)
		for (int j = 0; j < ans.cols(); ++j)
			printf("(%.2f %.2f) ", matrixGet(a, i, j), ans.get(i, j));
			
    if (!equals(a, ans)) {
        printf("\n===diff after transpose===\n");
        return 0;
    }*/
    
	printf("mul testing...\n");
    fflush(stdout);
    TMatrix ans =  TMatrix(a).mul(b);
    a = matrixMul(a, b);
    if (!equals(a, ans)) {
        printf("\n===diff after mul===\n");
        return 0;
    }
    
    
    /*printf("deleting testing...\n");
    fflush(stdout);
	matrixDelete(a);
	matrixDelete(c);*/
	return 0;
}

