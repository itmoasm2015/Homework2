section .text

extern calloc
extern free
extern malloc

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

;multiples-of-4 alignment macro
%macro align_to_quad 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

;Matrix matrixNew(unsigned int rows, unsigned int cols)

;void matrixDelete(Matrix matrix)

;unsigned int matrixGetRows(Matrix matrix)

;unsigned int matrixGetCols(Matrix matrix)

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)

;Matrix matrixScale(Matrix matrix, float k)

;Matrix matrixAdd(Matrix a, Matrix b)

;Matrix matrixMul(Matrix a, Matrix b)
