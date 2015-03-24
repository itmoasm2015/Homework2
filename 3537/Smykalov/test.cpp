#include <cstdio>
#include <cmath>
#include <algorithm>
#include <cassert>
#include <iostream>

#include "matrix.h"

#define eprintf(...) fprintf(stderr, __VA_ARGS__)
#define forn(i, n) for (int i = 0; (i) < (n); ++i)
static inline unsigned long long rdtsc() { unsigned long long d; __asm__ __volatile__ ("rdtsc" : "=A" (d) ); return d; }

struct TestMatrix
{
    Matrix a;
    int n, m;
    float **f;
    
    TestMatrix(): n(0), m(0) {}
    TestMatrix(int nn, int mm)
    {
        n = nn, m = mm;
        a = matrixNew(n, m);
        f = new float*[n];
        forn(i, n) f[i] = new float[m];
        forn(i, n) forn(j, m) f[i][j] = 0;
    }
    ~TestMatrix()
    {
        if (a != NULL) matrixDelete(a);
        forn(i, n) delete f[i];
        delete f;
    }
};    


inline float randFloat() { return rand() * 1. / RAND_MAX - 0.5; }
const int LIM = 100;
const float eps = 1e-5;


void testSetAndGet()
{
    int n = rand() % LIM + 1;
    int m = rand() % LIM + 1;
    TestMatrix a = TestMatrix(n, m);
    forn(_, 100)
    {
        int x = rand() % n;
        int y = rand() % m;
        if (rand() & 1)
        {
            float val = randFloat();
            matrixSet(a.a, x, y, val);
            a.f[x][y] = val;
        }
        else
        {
            float val = matrixGet(a.a, x, y);
            assert(fabs(val - a.f[x][y]) < eps);
        }
    }
    eprintf("set and get :: ok | n = %d, m = %d\n", n, m);
}

TestMatrix getRandomMatrix(int n, int m)
{
    TestMatrix res = TestMatrix(n, m);
    forn(i, n) forn(j, m)
    {
        float val = randFloat();
        matrixSet(res.a, i, j, val);
        res.f[i][j] = val;
    }
    return res;
}
    

void testAdd()
{
    int n = rand() % LIM + 1;
    int m = rand() % LIM + 1;
    TestMatrix a = getRandomMatrix(n, m);
    TestMatrix b = getRandomMatrix(n, m);
    Matrix c = matrixAdd(a.a, b.a);
    forn(i, n) forn(j, m)
    {
        float val = matrixGet(c, i, j);
        assert(fabs(val - a.f[i][j] - b.f[i][j]) < eps);
    }
    eprintf("add :: ok | n = %d, m = %d\n", n, m);
    matrixDelete(c);
}

void testScale()
{
    int n = rand() % LIM + 1;
    int m = rand() % LIM + 1;
    TestMatrix a = getRandomMatrix(n, m);
    float zz = randFloat();
    Matrix c = matrixScale(a.a, zz);
    forn(i, n) forn(j, m)
    {
        float val = matrixGet(c, i, j);
        assert(fabs(val - a.f[i][j] * zz) < eps);
    }
    eprintf("scale :: ok | n = %d, m = %d\n", n, m);
    matrixDelete(c);
}

void testMul()
{
    int n = rand() % LIM + 1;
    int m = rand() % LIM + 1;
    int k = rand() % LIM + 1;
    //n = 10, m = 10, k = 10;
    TestMatrix a = getRandomMatrix(n, m); 
    TestMatrix b = getRandomMatrix(m, k);
    Matrix c = matrixMul(a.a, b.a);
    forn(i, n) forn(j, k)
    {
        float want = 0;
        forn(ij, m) want += a.f[i][ij] * b.f[ij][j];
        float val = matrixGet(c, i, j);
        assert(fabs(want - val) < eps);
    }
    eprintf("mul :: ok | n = %d, m = %d, k = %d\n", n, m, k);
    matrixDelete(c);
}


const int maxn = 700;
float tmp[maxn][maxn];
float tmp2[maxn][maxn];

void testMulHuge()
{
    int n = maxn, m = n, k = n;
    TestMatrix a = getRandomMatrix(n, m); 
    TestMatrix b = getRandomMatrix(m, k);
    double start = clock() * 1. / CLOCKS_PER_SEC;
    Matrix c = matrixMul(a.a, b.a);
    double mid = clock() * 1. / CLOCKS_PER_SEC;
    forn(i, m) forn(j, k) tmp2[i][j] = b.f[j][i];
    forn(i, n) forn(j, k)
    {
        forn(ij, m) tmp[i][j] += a.f[i][ij] * tmp2[j][ij];
    }
    double end = clock() * 1. / CLOCKS_PER_SEC;
    eprintf("asm: %d ms\n", (int)((mid - start) * 1000));
    eprintf("c++: %d ms\n", (int)((end - mid) * 1000));
    float dd = 0;
    forn(i, n) forn(j, k)
    {
        float val = matrixGet(c, i, j);
        if (dd < fabs(val - tmp[i][j]))
        {
            dd = fabs(val - tmp[i][j]);
        }
    }
    eprintf("mul :: ok | n = %d, m = %d, k = %d  || dd = %.10f\n", n, m, k, dd);
    matrixDelete(c);
}


int main()
{
    long long seed = rdtsc();
    //seed = 0;
    srand(seed);
    eprintf("seed = %lld\n", seed);
    forn(i, 10) testSetAndGet();
    forn(i, 10) testAdd();
    forn(i, 10) testScale();
    forn(i, 10) testMul();
    testMulHuge();
    return 0;
}
