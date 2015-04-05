#ifndef TEST_HPP
#define TEST_HPP
#include <vector>
#include <iostream>

struct MyMatrix {
public:
    typedef std::vector<std::vector<double>> matrix_t;
    typedef matrix_t::size_type sz_t;

    MyMatrix(unsigned int rows, unsigned int cols); 

    MyMatrix(MyMatrix&& rhs); 

    MyMatrix(MyMatrix const&);

    unsigned int getRows() const;

    unsigned int getCols() const;

    double* operator[](unsigned int row);

    const double* operator[](unsigned int row) const;

    MyMatrix& operator*(float scale);

    MyMatrix operator+(MyMatrix const& rhs) const;

    MyMatrix operator*(MyMatrix const& rhs) const;

private:
    matrix_t matrix;
    static MyMatrix NULL_MATRIX;
};

std::ostream& operator<<(std::ostream& s, MyMatrix const& a);
MyMatrix& operator*(float scale, MyMatrix& matrix);

#endif
