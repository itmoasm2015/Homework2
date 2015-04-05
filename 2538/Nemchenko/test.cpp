#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include "MyMatrix.hpp"
#include "../../include/matrix.h"

using namespace std;

//void test() {

    //srand(time(NULL));

    //int n = 3;
    //int m = 3;
    //MyMatrix a(n, m);
    //MyMatrix b(n, m);

    //for (int i = 0; i < n; ++i) {
        //for (int j = 0; j < m; ++j) {
            //a[i][j] = rand() % 10;
            //b[i][j] = rand() % 10;
        //}
    //}

    //cout << a << endl;
    //cout << b << endl;
    //cout << a + b << endl;
    //cout << a * b << endl;
    //cout << 4.2 * a << endl;
    //cout << a * 4.2 + b * 3<< endl;
//}

extern "C" {
    void fun64(int a, int b, int c, int d, int e, int f, int g, int h, int i);
    void temp() {

    }

    void with_double(double a,double b,double c,double d,double e,double f,double g,double h,double i,double j);
}

int main() {

    int n = 10000;
    int m = 20000;
    int* mem = (int*) matrixNew(n, m);

    matrixSet(mem, 10, 20, 89);
    matrixSet(mem, 1, 200, 9);
    matrixSet(mem, 0, 0, 999);

    cout << matrixGetRows(mem) << endl;
    cout << matrixGet(mem, 10, 20) << endl;
    cout << matrixGet(mem, 1, 200) << endl;
    cout << matrixGet(mem, 0, 0) << endl;
    cout << mem[2] << endl;

    return 0;
}
