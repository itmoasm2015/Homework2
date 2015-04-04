#include <bits/stdc++.h>
#include "matrix.h"

const float EPS = 1e-3;

class VectorMatrix {
        static const int maxn = 100;
	unsigned n, m;
        float matrix[maxn][maxn];
public:
	VectorMatrix() {
	    n = m = 0;
	}

	void _matrixNew(unsigned n, unsigned m) {
	    this->n = n;
	    this->m = m;
            for (unsigned i = 0; i != n; ++i) {
		for (unsigned j = 0; j != m; ++j) {
		    matrix[i][j] = 0.f;
		}
	    }
	}

        unsigned _matrixGetRows() {
	    return n;
	}

	unsigned _matrixGetCols() {
	    return m;
	}

	void _matrixSet(unsigned x, unsigned y, float value) {
	    matrix[x][y] = value;
	}

	float _matrixGet(unsigned x, unsigned y) {
	    return matrix[x][y];
	}

        VectorMatrix _matrixScale(float k) {
            VectorMatrix newMatrix;
            newMatrix._matrixNew(n, m);
            for (unsigned i = 0; i != n; ++i)
                for (unsigned j = 0; j != m; ++j)
                    newMatrix._matrixSet(i, j, matrix[i][j] * k);
            return newMatrix;
        }

        VectorMatrix _matrixAdd(VectorMatrix other) {
            VectorMatrix newMatrix;
            newMatrix._matrixNew(n, m);
            for (unsigned i = 0; i != n; ++i)
                for (unsigned j = 0; j != m; ++j)
                    newMatrix._matrixSet(i, j, matrix[i][j] + other._matrixGet(i, j));
            return newMatrix;
        }

        bool assertEquals(Matrix other) {
            assert(n == matrixGetRows(other));
            assert(m == matrixGetCols(other));
            for (unsigned i = 0; i != n; ++i)
                for (unsigned j = 0; j != m; ++j)
                    assert(fabs(matrix[i][j] - matrixGet(other, i, j)) < EPS);
       }
};

class Tester {
    const int maxn = 100;
    int testsCount, testsPassed;

    void initTester() {
        srand(123345);
        testsCount = 0;
        testsPassed = 0;
    }
public:
    Tester() {
        initTester();
    }

    void testCreationMatrix() {
        unsigned n = rand() % maxn + 1;
        unsigned m = rand() % maxn + 1;
        Matrix actual = matrixNew(n, m);
        VectorMatrix expected;
        expected._matrixNew(n, m);
        testsCount++;
        expected.assertEquals(actual);
        if (actual) {
           matrixDelete(actual);
        }
        testsPassed++;
    }

    void testSetElements() {
        unsigned n = rand() % maxn + 1;
        unsigned m = rand() % maxn + 1;
        Matrix actual = matrixNew(n, m);
        VectorMatrix expected;
        expected._matrixNew(n, m);
        testsCount++;
        unsigned changesCount = n * m * 100;
        for (unsigned change = 0; change != changesCount; ++change) {
            unsigned x = rand() % n;
            unsigned y = rand() % m;
            float value = (rand() % 10) * 1.f / (rand() % 100 + 1);
            assert(fabs(matrixGet(actual, x, y) - expected._matrixGet(x, y)) <= EPS);
            expected._matrixSet(x, y, value);
            matrixSet(actual, x, y, value);
            assert(fabs(matrixGet(actual, x, y) - expected._matrixGet(x, y)) <= EPS);
        }
        expected.assertEquals(actual);
        if (actual) {
            matrixDelete(actual);
        }
        testsPassed++;
    }

    void testScaleMultiply() {
        unsigned n = rand() % maxn + 1;
        unsigned m = rand() % maxn + 1;
        Matrix matrix = matrixNew(n, m);
        VectorMatrix expected;
        expected._matrixNew(n, m);
        for (unsigned i = 0; i != n; ++i)
            for (unsigned j = 0; j != m; ++j) {
                float value = rand() % 1000 * 1.f / (rand() % 100 + 1);
                expected._matrixSet(i, j, value);
                matrixSet(matrix, i, j, value);
            }
        float k = rand() % 1000 * 1.f / (rand() % 100 + 1);
        if (rand() & 1)
            k *= -1.f;

        testsCount++;
        Matrix actual = matrixScale(matrix, k);
        VectorMatrix expectedMatrix = expected._matrixScale(k);
        expectedMatrix.assertEquals(actual);
        testsPassed++;
    }

    void testAddMatrix() {
        unsigned n = rand() % maxn + 1;
        unsigned m = rand() % maxn + 1;
        Matrix matrix = matrixNew(n, m);
        VectorMatrix vectorMatrix;
        vectorMatrix._matrixNew(n, m);
        for (unsigned i = 0; i != n; ++i)
            for (unsigned j = 0; j != m; ++j) {
                float value = rand() % 1000 * 1.f / (rand() % 100 + 1);
                matrixSet(matrix, i, j, value);
                vectorMatrix._matrixSet(i, j, value);
            }

        Matrix matrix2 = matrixNew(n, m);
        VectorMatrix vectorMatrix2;
        vectorMatrix2._matrixNew(n, m);
        for (unsigned i = 0; i != n; ++i)
            for (unsigned j = 0; j != m; ++j) {
                float value = rand() % 1000 * 1.f / (rand() % 100 + 1);
                matrixSet(matrix2, i, j, value);
                vectorMatrix2._matrixSet(i, j, value);
            }

        testsCount++;
        Matrix actual = matrixAdd(matrix, matrix2);
        VectorMatrix expected = vectorMatrix._matrixAdd(vectorMatrix2);
        expected.assertEquals(actual);
        testsPassed++;
    }

    void testAll() {
        printf("Testing matrix creation\n");
        for (int test = 0; test != 100; ++test) {
            testCreationMatrix();
        }
        printTestingResult();
        testsCount = 0;
        testsPassed = 0;

        printf("Testing matrix set and get elements\n");
        for (int test = 0; test != 10; ++test) {
            testSetElements();
        }
        printTestingResult();
        testsCount = 0;
        testsPassed = 0;

        printf("Testing matrix multiply\n");
        for (int test = 0; test != 100; ++test) {
            testScaleMultiply();
        }
        printTestingResult();
        testsCount = 0;
        testsPassed = 0;

        printf("Testing matrix sum\n");
        for (int test = 0; test != 100; ++test) {
            testAddMatrix();
        }
        printTestingResult();
        testsCount = 0;
        testsPassed = 0;
    }    

    void printTestingResult(bool ok = true) {
        printf("%s, %d/%d tests passed\n\n", ok ? "OK" : "FAIL", testsPassed, testsCount);  
    }
};

int main() {
    Tester tester;
    tester.testAll();
}
