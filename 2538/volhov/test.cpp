#include <iostream>
#include <matrix.h>

using namespace std;

int main() {
    std::cout << "test";
    Matrix m = matrixNew(9, 5);
    cout << m << endl;
    cout << matrixGetRows(m) << endl;
    cout << matrixGetCols(m) << endl;
    //    matrixMul(matrixNew(2,3), matrixNew(2,3));
    matrixDelete(m);
    //cout << matrixGetRows(m) << endl;
    //cout << matrixGetCols(m) << endl;
    return 1;
}
