#include "matrix.h"
#include <cmath>
#include <iostream>
#include <stdlib.h>

using namespace std;

typedef unsigned int uint;

#define EPS 1e-6

//common operations

/*bool equals(Matrix a, Matrix b) {
    unsigned int rowsA = matrixGetRows(a);
    unsigned int colsA = matrixGetCols(a);
    unsigned int rowsB = matrixGetRows(b);
    unsigned int colsB = matrixGetCols(b);
    if (rowsA != rowsB || colsA != colsB) {
        return false;
    }
    for (unsigned int i = 0; i < rowsA; i++) {
        for (unsigned int j = 0; j < colsA; j++) {
            if (fabs(matrixGet(a, i, j) - matrixGet(b, i, j)) > EPS) {
                return false;
            }
        }
    }
    return true;
}

void printMatrix(Matrix m) {
    uint rows = matrixGetRows(m); 
    uint cols = matrixGetCols(m); 
    for (uint i = 0; i < rows; i++) {
        for (uint j = 0; j < cols; j++) {
            cout << matrixGet(m, i, j) << ' ';
        }
        cout << endl;
    }
}*/

int main() {    

    Matrix a = matrixNew(10, 20);
    cout << a << endl;
    //matrixDelete(a);

    return 0;
}
