#include <iostream>
#include <matrix.h>
#include <algorithm>

using namespace std;

extern "C"
Matrix matrixTranspose(Matrix);

void dumpMatrix(Matrix m) {
    if (m == NULL) {
        printf("NULL MATRIX GIVEN");
        return;
    }
    int cols = matrixGetCols(m);
    int rows = matrixGetRows(m);
    cout << endl;
    for (int i=0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            printf("%4g", matrixGet(m, i, j));
        }
        cout << endl;
    }
}

int main() {
    Matrix m = matrixNew(22, 17);
    Matrix n = matrixNew(17, 19);
    float init = 1;
    for (int i = 0; i < matrixGetRows(m); i++) {
        for (int j = 0; j < matrixGetCols(m); j++) {
            matrixSet(m, i, j, init);
            //            init += 1;
        }
    }
    for (int i = 0; i < min(matrixGetRows(m), matrixGetCols(m)); i++) {
        matrixSet(m, i, i, 0);
    }
    dumpMatrix(m);
    m = matrixScale(m, 2);
    init = 2;
    for (int i = 0; i < matrixGetRows(n); i++) {
        for (int j = 0; j < matrixGetCols(n); j++) {
            matrixSet(n, i, j, init);
            // init += 1;
        }
    }
    for (int i = 0; i < min(matrixGetRows(n), matrixGetCols(n)); i++) {
        matrixSet(n, i, matrixGetCols(n) - i - 1, 0);
    }

    dumpMatrix(m);
    dumpMatrix(n);
    Matrix mul = matrixMul(m, n);
    dumpMatrix(mul);
    Matrix k = matrixNew(22, 17);
    for (int i = 0; i < matrixGetRows(k); i++) {
        for (int j = 0; j < matrixGetCols(k); j++) {
            matrixSet(k, i, j, 2);
        }
    }
    Matrix sum = matrixAdd(m, k);
    dumpMatrix(sum);
    Matrix sc = matrixScale(sum, 0.5f);
    dumpMatrix(sc);
    matrixDelete(m);
    matrixDelete(n);
    matrixDelete(k);
    matrixDelete(sum);
    matrixDelete(sc);
    //cout << matrixGetRows(m) << endl;
    //cout << matrixGetCols(m) << endl;
    return 1;
}
