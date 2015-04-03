#include <bits/stdc++.h>
#include "matrix.h"

using std::vector;

class VectorMatrix {
	int n, m;
	vector<vector<float>> matrix;
public:
	VectorMatrix() {
		n = m = 0;
		matrix.clear();
	}

	void matrixNew(int n, int m) {
		this->n = n;
		this->m = m;
		matrix.resize(n);
		for (int i = 0; i < n; i++) {
			matrix[i].resize(m);
			for (int j = 0; j < m; j++) {
				matrix[i][j] = 0.f;
			}
		}
	}

	int matrixGetRows() {
		return n;
	}

	int matrixGetCols() {
		return m;
	}

	void matrixSet(int x, int y, float value) {
		matrix[x][y] = value;
	}

	float matrixGet(int x, int y) {
		return matrix[x][y];
	}
};

class Tester {
};

int main() {
	Matrix matrix = matrixNew(4, 5);
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 5; j++)
                printf("%f%c", matrixGet(matrix, i, j), " \n"[j == 4]); 
        matrixSet(matrix, 2, 2, 1.0);
        printf("%lf\n", matrixGet(matrix, 2, 2)); 
}
