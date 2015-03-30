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
*/

void printMatrix(Matrix m) {
    if (m == 0) {
        cout << "Empty matrix" << endl;
        return;
    }
    uint rows = matrixGetRows(m); 
    uint cols = matrixGetCols(m); 
    for (uint i = 0; i < rows; i++) {
        for (uint j = 0; j < cols; j++) {
            cout << (float) matrixGet(m, i, j) << ' ';
        }
        cout << endl;
    }
}

int main() {    

    int n = 3;
    int m = 3;
    
    Matrix a = matrixNew(n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            matrixSet(a, i, j, i + j);
        }
    }
    printMatrix(a);

    Matrix b = matrixNew(n, m);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            if (i == j) {
                matrixSet(b, i, j, 1);
            } else {
                matrixSet(b, i, j, 0);
            }
        }
    }
    printMatrix(b);

    Matrix c = matrixMul(a, b);
    cout << c << endl;
    printMatrix(c);
    
    //matrixDelete(c);

    matrixDelete(a);
    matrixDelete(b);

    return 0;
}
