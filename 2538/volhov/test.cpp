#include <iostream>
#include <matrix.h>
#include <algorithm>

using namespace std;

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
            printf("%10g", matrixGet(m, i, j));
        }
        cout << endl;
    }
}

int main() {
    Matrix m = matrixNew(17, 9);
    float init = 1.2;
    for (int i = 0; i < matrixGetRows(m); i++) {
        for (int j = 0; j < matrixGetCols(m); j++) {
            matrixSet(m, i, j, init);
            init += 1.4;
        }
    }
    for (int i = 0; i < min(matrixGetRows(m), matrixGetCols(m)); i++) {
        matrixSet(m, i, i, 0);
    }
    dumpMatrix(m);
    matrixScale(m, 2.0);
    dumpMatrix(m);
    dumpMatrix(m);
    Matrix n = matrixNew(1,1);
    Matrix sum = matrixAdd(m, m);
    dumpMatrix(sum);

    matrixDelete(m);
    //cout << matrixGetRows(m) << endl;
    //cout << matrixGetCols(m) << endl;
    return 1;
}
