#include "tmatrix.h"
#include "matrix.h"
#include <cstdio>
#include <cmath>
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

int main() {
    TMatrix b(N, M);
    Matrix a = matrixNew(N, M);
    Matrix c = matrixNew(N, M);
    TMatrix d(N, M);
    printf("%d %d\n", matrixGetRows(a), matrixGetCols(a));
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j) {
            matrixSet(a, i, j, (float)(i+j));
            matrixSet(c, i, j, (float)(i*j));
            b.set(i, j, (float)(i+j));
            d.set(i, j, (float)(i*j));
		}
	
	printf("%d %d\n", matrixGetRows(a), matrixGetCols(a));
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
    }
    
    printf("transpose testing...\n");
    fflush(stdout);
	a = matrixTranspose(a);
    b = b.transpose();
    for (int i = 0; i < M; ++i)
		for (int j = 0; j < N; ++j)
			printf("(%.2f %.2f)", matrixGet(a, i, j), b.get(i, j));
    if (!equals(a, b)) {
        printf("\n===diff after transpose===\n");
        return 0;
    }
    
	/*a = matrixMul(a, c);
    b = b.mul(d);
    if (!equals(a, b)) {
        printf("\n===diff after mul===\n");
        return 0;
    }*/
	return 0;
}

