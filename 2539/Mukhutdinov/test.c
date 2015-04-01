#include <stdio.h>
#include <stdlib.h>
#include <matrix.h>

#define TEST(name, expected, actual) {          \
    printf("[TEST] %s... ", name);              \
    if((actual) != (expected)) {                \
        printf("FAILED: expected %d, but was %d\n", (expected), (actual)); \
    } else {                                    \
        printf("OK\n");                         \
    }                                           \
}

int main()
{
    Matrix m = matrixNew(5, 4);

    TEST("should return cols properly", 4, matrixGetCols(m));
    TEST("should return rows properly", 5, matrixGetRows(m));

    matrixDelete(m);
    return 0;
}
