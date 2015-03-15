#include "gtest/gtest.h"
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <iostream>

TEST(hwmatrices, initBoost) {
    using namespace boost::numeric::ublas;
    matrix<float> m (3, 3);
}

