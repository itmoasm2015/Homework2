#include "matrix.h"
#include <iostream>
#include <stdlib.h>

using namespace std;

int main() {

    void * test = matrixNew(10, 20);
    cout << test << endl;
    

    return 0;
}
