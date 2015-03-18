extern calloc
extern printf

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

section .data
hello_str:      db     "hello!", 10, 0
hello_len:      equ    $ - hello_str
format:         db     "result %llu: ", 10, 0
dat:            dq      1, 2, 3, 4
da2:            dq      5, 6, 7, 8

section .bss
result:     resq    4

section .text

;;Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
    push    rbp
    mov     rbp, rsp

    movups  xmm0, [dat]
    movups  xmm1, [da2]
    mulps   xmm0, xmm1
    movups  [result], xmm0

    mov     eax, [result]
    mov     ebx, [result + 4]


    mov     rsp, rbp
    pop     rbp
    ret

;;void matrixDelete(Matrix matrix);
matrixDelete:

    ret

;;unsigned int matrixGetRows(Matrix matrix);
matrixGetRows:

    ret

;;unsigned int matrixGetCols(Matrix matrix);
matrixGetCols:
    
    ret

;;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
matrixGet:

    ret

;;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
matrixSet:

    ret

;;Matrix matrixScale(Matrix matrix, float k);
matrixScale:

    ret

;;Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:

    ret

;;Matrix matrixMul(Matrix a, Matrix b);
matrixMul:

    ret
