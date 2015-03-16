#include "tmatrix.h"
#include "matrix.h"
#include <cstdio>
#include <cmath>
const int N = 2;
const int M = 2;

bool equals(const Matrix& a, const TMatrix& b) {
	for (int i = 0; i < N; ++i) 
		for (int j = 0; j < N; ++j)
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
    
    b = b.scale(13.52);
    a = matrixScale(a, 13.52);
			
    if (!equals(a, b)) {
        printf("\n===diff after scale===\n");
        return 0;
    }
    
    a = matrixAdd(a, c);
    b = b.add(d);
    
        if (!equals(a, b)) {
        printf("\n===diff after add===\n");
        return 0;
    }
    
	a = matrixMul(a, c);
    b = b.mul(d);
    if (!equals(a, b)) {
        printf("\n===diff after mul===\n");
        return 0;
    }
	return 0;
}

