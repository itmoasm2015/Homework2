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
FORMAT:     db      "%u %u", 10, 0

section .bss

section .text

;;Matrix matrixNew(unsigned int rows, unsigned int cols);
;
; Takes:
;   RDI - unsigned int rows
;   RSI - unsigned int cols
; Returns:
;   RAX - Matrix (=R8)
; Uses:
;   R8 - Matrix;

matrixNew:

    push    rbp

    mov     rax, rdi
    mov     rbx, rsi

    mov     rdi, FORMAT
    mov     rsi, rax
    mov     rdx, rbx
    call    printf

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
