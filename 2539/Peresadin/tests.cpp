#include "tmatrix.h"
#include "matrix.h"
#include <cstdio>
const int N = 10;
int main() {
    //TMatrix b(N, N);
    Matrix a = matrixNew(N, N);
    printf("%d %d\n", matrixGetRows(a), matrixGetCols(a));
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j) {
            matrixSet(a, i, j, (float)(i+j));
            //b.set(i, j, (float)(i+j));
		}
	/*for (int i = 0; i < N; ++i) {
		for (int j = 0; j < N; ++j)
			printf("(%.3f, %.3f)", matrixGet(a, i, j), b.get(i, j));
		printf("\n");
	}*/
	return 0;
}

