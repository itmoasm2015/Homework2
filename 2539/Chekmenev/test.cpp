#include "include/matrix.h"
#include <iostream>
#include <cassert>
#include <cstdlib>
#include <ctime>
#include <cstdio>
#include <stdexcept>
#include <vector>
#include <memory>

using namespace std;

struct CMatrix {
public:
    typedef std::shared_ptr<CMatrix> pMatrix;
    CMatrix(unsigned int rows, unsigned int cols) {
        this->rows = rows;
        this->cols = cols;
        m = vector<float>(rows*cols, 0);
    }
    void matrixDelete(pMatrix matrix) {
        //delete matrix;
    }
    unsigned int matrixGetRows(pMatrix matrix) {
        return matrix->rows;
    }
    unsigned int matrixGetCols(pMatrix matrix) {
        return matrix->cols;
    }
    float matrixGet(pMatrix matrix, unsigned int row, unsigned int col) {
        int index = row * matrix->cols + col;
        return matrix->m[index];
    }
    void matrixSet(pMatrix matrix, unsigned int row, unsigned int col, float value) {
        int index = row * matrix->cols + col;
        matrix->m[index] = value;
    }
    pMatrix matrixScale(pMatrix matrix, float k) {
        pMatrix c(new CMatrix(matrix->rows, matrix->cols));
        int size = matrix->rows * matrix->cols;
        for(int i = 0; i < size; i++) {
            c->m[i] = (matrix->m[i] * k);
        }
        return c;
    }
    pMatrix matrixAdd(pMatrix a, pMatrix b) {
        pMatrix c(new CMatrix(a->rows, a->cols));
        int size = a->rows * a->cols;
        for(int i = 0; i < size; i++) {
            c->m[i] = a->m[i] + b->m[i];
        }
        return c;
    }
    pMatrix matrixMul(pMatrix a, pMatrix b) {
        int all = a->rows * b->cols;
        pMatrix c(new CMatrix(a->rows, b->cols));
        for(int i = 0; i < all; i++) {
            c->m[i] = 0;
        }
        for(unsigned int i = 0; i < a->rows; i++) {
            for(unsigned int j = 0; j < b->cols; j++) {
                for(unsigned int k = 0; k < a->cols; k++) {
                    int ind1 = i * a->cols + k,
                        ind2 = k * b->cols + j;
                    c->m[i * b->cols + j] += a->m[ind1] * b->m[ind2];
                }
            }
        }
        return c;
    }

    vector <float> m;
    unsigned int rows, cols;
};

struct Tester {
public:
    typedef void(*test_function)();
    typedef pair <string, test_function> test;

    Tester() {}
    int run(void(*test)()) {
        int start = clock();
        test();
        int end = clock();
        return end - start;
    }
    void runner(vector <test> tests, bool interrupt = true) {
        srand(time(NULL));
        int duration = 0;
        int passed = 0;
        pair <int, int> max_duration(0, 0);
        printf("\n");
        for(int i = 0; i < (int)tests.size(); i++) {

            printf("TEST %20s\n", tests[i].first.c_str());
            for(int j = 0; j < 25; j++) printf("=");
            printf("\n");

            try {
                duration = run(tests[i].second);
                if (duration > max_duration.first) {
                    max_duration = make_pair(duration, i);
                }
                passed++;

                for(int j = 0; j < 25; j++) printf("=");
                printf("\nResult: OK, Time: %.3lf s.\n", 1.0*duration/1000000);

            } catch (exception& e) {
                printf("Exception: %s\n", e.what());

                for(int j = 0; j < 25; j++) printf("=");
                printf("\nResult: FAIL, Time: %.3lf s.\n", 1.0*duration/1000000);

                if (interrupt) break;
            }

            printf("\n");
        }

        printf("SUMMARY\n");
        for(int j = 0; j < 25; j++) printf("=");
        printf("\n\tPassed:%5d\n", passed);
        printf("\tFailed:%5d\n", (int)tests.size() - passed);
        printf("\tTime: %.3lf\n", 1.0*max_duration.first/1000000);
    }
};

void printMatrix(Matrix a) {
    for (int i = 0; i < matrixGetRows(a); i++) {
        for (int j = 0; j < matrixGetCols(a); j++) {
            cout << matrixGet(a, i, j) << " ";
        }
        cout << "\n";
    }
}

float genFloat() {
    int numerator = rand();
    int denumerator = rand();
    float x = 100.0f * numerator / denumerator;
    return x;
}

void test1() {
    cout << "Test1 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        matrixDelete(a);
    }
    cout << "OK\n";
}

void test2() {
    cout << "Test2 starts ... ";
    float tmp[1001][1001];
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                int numerator = rand();
                int denumerator = rand() % 10000 + 1;
                float x = 1.0f * numerator / denumerator;
                matrixSet(a, i, j, x);
                tmp[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(a, i, j) == tmp[i][j]);
            }
        }
        matrixDelete(a);
    }
    cout << "OK\n";
}

void test3() {
    cout << "Test3 starts ... ";
    float tmp[1001][1001];
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        float k = genFloat();
        Matrix a = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                tmp[i][j] = x * k;
            }
        }
        Matrix b = matrixScale(a, k);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(b, i, j) == tmp[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
    }
    cout << "OK\n";
}

float aa[1001][1001];
float bb[1001][1001];
float cc[1001][1001];
void test4() {
    cout << "Test4 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 1000 + 1;
        int m = rand() % 1000 + 1;
        Matrix a = matrixNew(n, m);
        Matrix b = matrixNew(n, m);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        assert(n == matrixGetRows(b));
        assert(m == matrixGetCols(b));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
                cc[i][j] = aa[i][j] + bb[i][j];
            }
        }
        Matrix c = matrixAdd(a, b);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                assert(matrixGet(c, i, j) == cc[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(c);
    }
    cout << "OK\n";
}

void test5() {
    cout << "Test5 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n = rand() % 200 + 1;
        int m = rand() % 200 + 1;
        int q = rand() % 200 + 1;
        Matrix a = matrixNew(n, m);
        Matrix b = matrixNew(m, q);
        assert(n == matrixGetRows(a));
        assert(m == matrixGetCols(a));
        assert(m == matrixGetRows(b));
        assert(q == matrixGetCols(b));
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < m; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < q; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
            }
        }
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < q; j++) {
                cc[i][j] = 0;
                for (int k = 0; k < m; k++) {
                    cc[i][j] += aa[i][k] * bb[k][j];
                }
            }
        }
        Matrix c = matrixMul(a, b);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < q; j++) {
                assert(matrixGet(c, i, j) == cc[i][j]);
            }
        }
        matrixDelete(a);
        matrixDelete(b);
        matrixDelete(c);
    }
    cout << "OK\n";
}

void test7() {
    cout << "Test7 starts ... ";
    for (int t = 0; t < 100; t++) {
        int n1 = rand() % 1000 + 1;
        int m1 = rand() % 1000 + 1;
        int n2 = rand() % 1000 + 1;
        int m2 = rand() % 1000 + 1;
        Matrix a = matrixNew(n1, m1);
        Matrix b = matrixNew(n2, m2);
        assert(n1 == matrixGetRows(a));
        assert(m1 == matrixGetCols(a));
        assert(n2 == matrixGetRows(b));
        assert(m2 == matrixGetCols(b));
        for (int i = 0; i < n1; i++) {
            for (int j = 0; j < m1; j++) {
                float x = genFloat();
                matrixSet(a, i, j, x);
                aa[i][j] = x;
            }
        }
        for (int i = 0; i < n2; i++) {
            for (int j = 0; j < m2; j++) {
                float x = genFloat();
                matrixSet(b, i, j, x);
                bb[i][j] = x;
            }
        }
        Matrix c = matrixMul(a, b);
        Matrix d = matrixAdd(a, b);
        assert(c == NULL);
        assert(d == NULL);
        matrixDelete(a);
        matrixDelete(b);
    }
    cout << "OK\n";
}

void test_matrix_new() {
    int initial_rows = 10, initial_cols = 10;
    Matrix a = matrixNew(initial_rows, initial_cols);

    int rows = matrixGetRows(a);
    int cols = matrixGetCols(a);
    cout << "rows = " << rows << ", cols = " << cols << endl;
    if (initial_rows != rows) {
        throw runtime_error("matrixGetRows != initial_rows");
    }
    if (initial_cols != cols) {
        throw runtime_error("matrixGetCols != initial_cols");
    }

    matrixDelete(a);
}

void get_set_ops(int rows, int cols, int Q) {
    Matrix a = matrixNew(rows, cols);

    CMatrix::pMatrix myMatrix(new CMatrix(rows, cols));
    for(int q = 0; q < Q; q++) {
        int i = rand() % rows, j = rand() % cols;
        float val = 1.0*rand()/(1 + rand());
        myMatrix->matrixSet(myMatrix, i, j, val);
        matrixSet(a, i, j, val);
    }

    for(int q = 0; q < Q; q++) {
        int i = rand() % rows, j = rand() % cols;
        float value = myMatrix->matrixGet(myMatrix, i, j);
        float get_value = matrixGet(a, i, j);
        if (value != get_value) {
            matrixDelete(a);
            throw runtime_error("a["+std::to_string(rows)+"]["+std::to_string(cols)+"] contains wrong at ("+std::to_string(i)+","+std::to_string(j)+")");
        }
    }

    matrixDelete(a);
}

void test_matrix_get_set() {
    int rows = 1000, cols = 1000, Q = 1e7;
    get_set_ops(rows, cols, Q);
    rows = 10000, cols = 100, Q = 1e7;
    get_set_ops(rows, cols, Q);
    rows = 100000, cols = 10, Q = 1e7;
    get_set_ops(rows, cols, Q);
}
void test_matrix_get_set_random() {
    int rows = 1234, cols = 4321, Q = 1e7;
    get_set_ops(rows, cols, Q);
    rows = 5432, cols = 3210, Q = 1e7;
    get_set_ops(rows, cols, Q);
    rows = 3456, cols = 3456, Q = 1e7;
    get_set_ops(rows, cols, Q);
}

void test_matrix_scale() {
    unsigned int rows = 1000, cols = 1000;
    CMatrix::pMatrix myMatrix(new CMatrix(rows, cols));
    Matrix m = matrixNew(rows, cols);

    for(int Q = 0; Q < 100; Q++) {
        float k = 1.0 * rand() / (1 + rand());
        //cout << "k = " << k << endl;
        for(unsigned int i = 0; i < rows; i++) {
            for(unsigned int j = 0; j < cols; j++){
                matrixSet(m, i, j, 1.0*i/(1+j));
                myMatrix->matrixSet(myMatrix, i, j, 1.0*i/(1+j));
            }
        }
        Matrix scaledMatrix = matrixScale(m, k);
        myMatrix = myMatrix->matrixScale(myMatrix, k);
        for(unsigned int i = 0; i < rows; i++) {
            for(unsigned int j = 0; j < cols; j++){
                float val1 = myMatrix->matrixGet(myMatrix, i, j);
                float val2 = matrixGet(scaledMatrix, i, j);
                //printf("\t[%d][%d]: %.2f %.2f\n", i, j, val1, val2);
                assert(val1 == val2);
            }
        }
    }

    matrixDelete(m);
}

void test_matrix_add() {
    unsigned int rows = 1000, cols = 1000;
    CMatrix::pMatrix myMatrix(new CMatrix(rows, cols));
    Matrix m1 = matrixNew(rows, cols);
    Matrix m2 = matrixNew(rows, cols);

    for(unsigned int i = 0; i < rows; i++) {
        for(unsigned int j = 0; j < cols; j++){
            matrixSet(m1, i, j, i);
            matrixSet(m2, i, j, j);
            myMatrix->matrixSet(myMatrix, i, j, i + j);
        }
    }
    Matrix summedMatrix = matrixAdd(m1, m2);
    for(unsigned int i = 0; i < rows; i++) {
        for(unsigned int j = 0; j < cols; j++){
            float val1 = myMatrix->matrixGet(myMatrix, i, j);
            float val2 = matrixGet(summedMatrix, i, j);
            //printf("\t[%d][%d]: %.2f %.2f\n", i, j, val1, val2);
            assert(val1 == val2);
        }
    }

    matrixDelete(m1);
    matrixDelete(m2);
    matrixDelete(summedMatrix);
}

void test_matrix_mul() {
    int rows = 3, cols = 4;
    int rows1 = 4, cols1 = 5;

    Matrix a = matrixNew(rows, cols);
    for(int i = 0; i < rows; i++, cout << endl) {
        for(int j = 0; j < cols; j++) {
            matrixSet(a, i, j, i + j);
            printf("%3d", i + j);
        }
    }

    Matrix b = matrixNew(rows1, cols1);
    for(int i = 0; i < rows1; i++, cout << endl) {
        for(int j = 0; j < cols1; j++) {
            matrixSet(b, i, j, i + j);
            printf("%3d", i + j);
        }
    }
    Matrix c = matrixMul(a, b);
    cout << matrixGetRows(c) << " " << matrixGetCols(c) << endl;
    for(int i = 0; i < cols1; i++, cout << endl) {
        for(int j = 0; j < rows1; j++) {
            int val = matrixGet(c, i, j);
            printf("%3d", val);
        }
    }
}


int main() {
    vector <Tester::test> tests = {
        {"test1", test1},
        {"test2", test2},
        {"test3", test3},
        {"test4", test4},
        {"matrix_new", test_matrix_new},
        {"matrix_get_set", test_matrix_get_set},
        {"matrix_get_set_random", test_matrix_get_set_random},
        {"matrix_scale", test_matrix_scale},
        {"matrix_add", test_matrix_add},
        {"matrix_mul", test5},
        {"matrix_mul_wrong", test7},
    };
    Tester tester;
    tester.runner(tests);
    return 0;
}
