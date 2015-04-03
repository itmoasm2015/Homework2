#include <bits/stdc++.h>
#include "matrix.h"

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

        bool assertEquals(Matrix other) {
            assert(n == matrixGetRows(other));
            assert(m == matrixGetCols(other));
            for (unsigned i = 0; i != n; ++i)
                for (unsigned j = 0; j != m; ++j)
                    assert(matrix[i][j] == matrixGet(other, i, j));
       }
};

class Tester {
    const int maxn = 100;
    int testsCount, testsPassed;

    void initTester() {
        srand(239017);
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

    void testAll() {
        for (int test = 0; test != 100; ++test) {
            testCreationMatrix();
        }
    }    

    void printTestingResult(bool ok = true) {
        printf("%s, %d/%d passed\n\n", ok ? "OK" : "FAIL", testsPassed, testsCount);  
    }
};

int main() {
    Tester tester;
    tester.testAll();
    tester.printTestingResult();
}
