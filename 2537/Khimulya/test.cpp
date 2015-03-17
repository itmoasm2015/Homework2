#include "gtest/gtest.h"
#include <matrix.h>
#include <cmath>
#include <iostream>
#include <random>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/io.hpp>

typedef boost::numeric::ublas::matrix<float> matrix_ublas;

TEST(hwmatrices, initBoost) {
    using namespace boost::numeric::ublas;
    matrix_ublas m (100, 100);
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
    const unsigned int getSetRows = 1000;
    const unsigned int getSetColumns = 1000;
    const unsigned int getSetIterations = 100000;

    struct pair {
        Matrix hw;
        matrix_ublas sample;
        unsigned int rows, columns;

        pair(const unsigned int rows, const unsigned int columns) : sample(rows, columns),
                                                                rows(rows), columns(columns){
            hw = matrixNew(rows, columns);
        }

        pair(Matrix hw, matrix_ublas sample, const unsigned int rows,
             const unsigned int columns) : sample(sample), rows(rows), columns(columns) {
            this->hw = hw;
        }

        ~pair() {
            matrixDelete(hw);
        }
    };

    const float eps = 10e-7;

    void assertEqMatrices(Matrix hw, matrix_ublas sample) {
        for (int i = 0; i < sample.size1(); i++) {
            for (int j = 0; j < sample.size2(); j++) {
                ASSERT_TRUE(abs(sample(i, j) - matrixGet(hw, i, j)) < eps);
            }
        }
    }

    void assertEqMatrices(const pair& matrices) {
        assertEqMatrices(matrices.hw, matrices.sample);
    }
}

TEST(hwmatrices, randomSetGet) {
    pair test(getSetRows, getSetColumns);

    // init both matrices with zeros
    for (int i = 0; i < getSetRows; i++) {
        for (int j = 0; j < getSetColumns; j++) {
            test.sample(i, j) = .0;
            matrixSet(test.hw, i, j, .0);
        }
    }

    srand(time(NULL));
    for (int i = 0; i < getSetIterations; i++) {
        unsigned int r = rand() % getSetRows;
        unsigned int c = rand() % getSetColumns;
        float random = ((float) rand()) / 10e-7;
        test.sample(r, c) = random;
        matrixSet(test.hw, r, c, random);
    }

    assertEqMatrices(test);
}

namespace {
    const unsigned int scalarRows = 100;
    const unsigned int scalarColumns = 104;
    const unsigned int scalarIterations = 100;

    pair genRandomPair(unsigned int rows, unsigned int cols) {
        pair result(rows, cols);

        srand(time(NULL));
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                float random = ((float) rand()) / 10e-7;
                result.sample(i, j) = random;
                matrixSet(result.hw, i, j, random);
            }
        }

        return result;
    }
}

TEST(hwmatrices, randomScalarMul) {
    for (int i = 0; i < scalarIterations; i++) {
        pair test = genRandomPair(scalarRows, scalarColumns);
        pair old(test.hw, test.sample, scalarRows, scalarColumns);
        Matrix copy = matrixScale(test.hw, .5);
        test.sample *= .5;
        // check if source matrix is changed
        assertEqMatrices(old);
        test.hw = copy;
        assertEqMatrices(test);
    }
}

TEST(hwmatrices, incorrectAdd) {
    Matrix first = matrixNew(10, 20);
    Matrix second = matrixNew(20, 10);
    Matrix third = matrixNew(100, 100);

    if (matrixAdd(first, second) != NULL || matrixAdd(second, first) != NULL ||
        matrixAdd(first, third) != NULL  || matrixAdd(third, first) != NULL  ||
        matrixAdd(second, third) != NULL || matrixAdd(third, second) != NULL) {
        FAIL();
    }

    matrixDelete(first);
    matrixDelete(second);
    matrixDelete(third);
}

namespace {
    const unsigned int addRows = 100;
    const unsigned int addColumns = 104;
    const unsigned int addIterations = 100;
}

TEST(hwmatrices, randomAdd) {
    for (int i = 0; i < addIterations; i++) {
        pair test1 = genRandomPair(addRows, addColumns);
        pair test2 = genRandomPair(addRows, addColumns);
        pair old1(test1.hw, test1.sample, addRows, addColumns);
        pair old2(test2.hw, test2.sample, addRows, addColumns);
        Matrix copy1 = matrixAdd(test1.hw, test2.hw);
        Matrix copy2 = matrixAdd(test2.hw, test1.hw);
        test1.sample += test2.sample;
        test2.sample = test1.sample;
        // check if source matrices are intact
        assertEqMatrices(old1);
        assertEqMatrices(old2);
        test1.hw = copy1;
        test2.hw = copy2;
        assertEqMatrices(test1);
        assertEqMatrices(test2);
    }
}

TEST(hwmatrices, incorrectMul) {
    Matrix first = matrixNew(20, 30);
    Matrix second = matrixNew(40, 20);
    Matrix third = matrixNew(100, 100);

    if (matrixMul(first, second) != NULL ||
        matrixMul(first, third) != NULL  || matrixAdd(third, first) != NULL  ||
        matrixAdd(second, third) != NULL || matrixAdd(third, second) != NULL) {
        FAIL();
    }

    matrixDelete(first);
    matrixDelete(second);
    matrixDelete(third);
}

namespace {
    const unsigned int mulIterations = 10;
    const unsigned int mulRows0 = 50;
    const unsigned int mulColumns0 = 100;
    const unsigned int mulRows1 = 100;
    const unsigned int mulColumns1 = 200;
}

TEST(hwmatrices, matrixMul) {
    for (int i = 0; i < mulIterations; i++) {
        pair test1 = genRandomPair(mulRows0, mulColumns0);
        pair test2 = genRandomPair(mulRows1, mulColumns1);
        Matrix copy = matrixMul(test1.hw, test2.hw);
        matrix_ublas product = boost::numeric::ublas::prod(test1.sample, test2.sample);
        assertEqMatrices(copy, product);
        // check if source matrices are intact
        assertEqMatrices(test1);
        assertEqMatrices(test1);
        matrixDelete(copy);
    }
}
