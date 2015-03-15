#include "gtest/gtest.h"
#include <matrix.h>
#include <iostream>
#include <random>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/io.hpp>

TEST(hwmatrices, initBoost) {
    using namespace boost::numeric::ublas;
    matrix<float> m (100, 100);
}

// in fact it's a test for valgrind
TEST(hwmatrices, initHW) {
    const unsigned int rows = 255;
    const unsigned int cols = 16;
    Matrix mine = matrixNew(rows, cols);
    ASSERT_EQ(matrixGetRows(mine), rows);
    ASSERT_EQ(matrixGetCols(mine), cols);
    matrixDelete(mine);
}

TEST(hwmatrices, outOfMemoryHW) {
    // 64 Gb of memory
    Matrix mine = matrixNew((unsigned int)262144, (unsigned int)262144);
    if (mine != NULL) {
        std::cout << "Either you have more than 64 Gb of memory or matrixNew works incorrect";
        FAIL();
    }
    // free works ok with null pointer
    matrixDelete(mine);
}

namespace {
    const unsigned int rows = 1000;
    const unsigned int columns = 1000;
    const unsigned int iterations = 100000;
}

TEST(hwmatrices, randomSetGet) {
    using namespace boost::numeric::ublas;
    matrix<float> sample (rows, columns);
    Matrix hw = matrixNew(rows, columns);

    // init both matrices with zeros
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            sample(i, j) = .0;
            matrixSet(hw, i, j, .0);
        }
    }

    srand(time(NULL));
    for (int i = 0; i < iterations; i++) {
        unsigned int r = rand() % rows;
        unsigned int c = rand() % columns;
        float random = ((float) rand()) / 10e-7;
        sample(r, c) = random;
        matrixSet(hw, r, c, random);
    }

    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            ASSERT_EQ(sample(i, j), matrixGet(hw, i, j));
        }
    }
}
