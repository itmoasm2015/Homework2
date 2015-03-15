#include "gtest/gtest.h"
#include <matrix.h>
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

    void assertEqMatrices(const pair& matrices) {
        for (int i = 0; i < matrices.rows; i++) {
            for (int j = 0; j < matrices.columns; j++) {
                ASSERT_EQ(matrices.sample(i, j), matrixGet(matrices.hw, i, j));
            }
        }
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
    const unsigned int scalarColumns = 100;
    const unsigned int scalarIterations = 1000;

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
        assertEqMatrices(old);
        test.hw = copy;
        assertEqMatrices(test);
    }
}
