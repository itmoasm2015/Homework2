#include <stdio.h>
#include <stdlib.h>
#include <matrix.h>

#define TEST(name, expected, actual) {          \
    printf("[TEST] %s... ", name);              \
    if((actual) != (expected)) {                \
        printf("FAILED: expected %0.10f, but was %0.10f\n", (expected), (actual)); \
    } else {                                    \
        printf("OK\n");                         \
    }                                           \
}

int main()
{
    Matrix m = matrixNew(5, 4);

    TEST("should return cols properly", 4, matrixGetCols(m));
    TEST("should return rows properly", 5, matrixGetRows(m));
    TEST("initial values should be zeroes", 0, matrixGet(m, 1, 2));

    matrixSet(m, 1, 2, 1.5);
    matrixSet(m, 0, 3, 4.34);
    TEST("should set value properly #1", 1.5, matrixGet(m, 1, 2));
    TEST("should set value properly #2", (float) 4.34, matrixGet(m, 0, 3));


    matrixDelete(m);
    return 0;
}
