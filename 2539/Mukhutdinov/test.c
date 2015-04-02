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

    Matrix m2 = matrixScale(m, 2);
    TEST("scale shouldn't change initial matrix", 1.5, matrixGet(m, 1, 2));
    TEST("should matrixScale properly #1", (float) 3, matrixGet(m2, 1, 2));
    TEST("should matrixScale properly #2", (float) 8.68, matrixGet(m2, 0, 3));

    Matrix m3 = matrixAdd(m, m2);
    TEST("should matrixSum properly #1", (float) 4.5, matrixGet(m3, 1, 2));
    TEST("should matrixSum properly #2", (float) 13.02, matrixGet(m3, 0, 3));
    TEST("should matrixSum properly #3", (float) 0, matrixGet(m3, 3, 2));

    matrixDelete(m);
    return 0;
}
