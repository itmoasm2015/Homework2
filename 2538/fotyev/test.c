#include "matrix.h"

#include <stdio.h>

void print_matrix(FILE * fp, Matrix m)
{
  fprintf(fp, "%p ", m);
  if(!m)
    return;
  fprintf(fp, "%d %d\n", matrixGetRows(m), matrixGetCols(m));
  for(int i = 0; i < matrixGetRows(m); i++)
  {
    for(int j = 0; j < (matrixGetCols(m)); j++)
    {
      fprintf(fp, "%.1f ", matrixGet(m, i, j));
    }
    fprintf(fp, "\n");
  }
  fprintf(fp, "\n");

}

int main()
{
  Matrix m1 = matrixNew(80000, 100);
  printf("%lld\n", (unsigned long long int)m1 & 31);

  matrixSet(m1, 0, 7, 3.f);
  matrixSet(m1, 0, 8, 5.f);
  matrixSet(m1, 2, 2, 15.f);
  matrixSet(m1, 2, 3, 45.f);
  matrixSet(m1, 0, 0, 0.1f);
  matrixSet(m1, 2, 9, 0.2f);

  print_matrix(stdout, m1);

  Matrix m2 = matrixScale(m1, 2.f);
  print_matrix(stdout, m2);

  Matrix m3 = matrixAdd(m1, m2);
  print_matrix(stdout, m3);

  Matrix m4 = matrixTranspose(m3);
  print_matrix(stdout, m4);


  matrixDelete(m1);
  matrixDelete(m2);
  matrixDelete(m3);
  matrixDelete(m4);

  m1 = matrixNew(3, 9);
  matrixSet(m1, 0, 0, 2.f);
  matrixSet(m1, 1, 1, 2.f);
  matrixSet(m1, 2, 2, 2.f);
  m2 = matrixNew(9, 40);
  matrixSet(m2, 0, 1, 1.f);
  matrixSet(m2, 1, 0, 2.f);
  matrixSet(m2, 2, 0, 3.f);
  m3 = matrixMul(m1, m2);
  print_matrix(stdout, m3);

  matrixDelete(m1);
  matrixDelete(m2);
  matrixDelete(m3);
  //matrixDelete(m4);

}
