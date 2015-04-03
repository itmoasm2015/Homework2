#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include "MyMatrix.hpp"

int main() {
    using namespace std;

    srand(time(NULL));

    int n = 3;
    int m = 3;
    MyMatrix a(n, m);
    MyMatrix b(n, m);

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < m; ++j) {
            a (i, j) = rand() % 10;
            b (i, j) = rand() % 10;
        }
    }

    cout << a << endl;
    cout << b << endl;
    cout << a + b << endl;
    cout << a * b << endl;
    cout << 4.2 * a << endl;
    cout << a * 4.2 + b * 3<< endl;

    return 0;
}
