; calee-save RBX, RBP, R12-R15
; rdi , rsi ,
; rdx , rcx , r8 ,
; r9 , zmm0 - 7
global main

global matrixNew
global matrixDelete
global matrixSet
global matrixGet
global matrixGetRows
global matrixGetCols
global matrixAdd
global matrixScale
global matrixMul

extern calloc
extern free

; matrix saved in memory:
; n - count of rows, m - count of column
; [n, m, a[0][0], a[0][1], ..., a[n][m], 0, 0, 0..]
; total number of elements is 2 + n * m + 4 - (n * m) % 4 = 6 + n * m - (n * m) % 4
; last 4 - (n * m) % 4 elements are zero
; size of each element is 4 bytes

section .text

; Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
    push rbx
    push rdi         ; save arguments
    push rsi

    imul edi, esi    ; edi = n * m

    xor  edx, edx
    mov  eax, edi    
    mov  ebx, 4
    div  ebx  
    neg  edx
    add  edx, 6      ; edx = 6 - (n * m) % 4
    add  edi, edx    ; edi = n * m + 6 - (n * m) % 4
    mov  rsi, 4

    call calloc

    pop rsi
    pop rdi

    mov  [rax], edi
    mov  [rax + 4], esi
    
    pop rbx
    ret

; void matrixDelete(Matrix matrix);
matrixDelete:
    call free
    ret

; unsigned int matrixGetRows(Matrix matrix);
matrixGetRows:
    mov rax, [rdi]
    ret

; unsigned int matrixGetCols(Matrix matrix);
matrixGetCols:
    mov rax, [rdi + 4]
    ret

; return pointer to matrix[row][col]
; float* matrixGet(Matrix matrix, unsigned int row, unsigned int col);
matrixGetAddress:
    mov  r8, [rdi + 4]  ; r8 = m
    imul rsi, r8        ; rsi = row * m
    add  rsi, rdx       ; rsi = row * m + col
    lea  rax, [rdi + rsi]
    ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
matrixGet:
    call matrixGetAddress
    movss xmm0, [rax]
    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
matrixSet:
    call matrixGetAddress
    movss [rax], xmm0
    ret

; Matrix matrixScale(Matrix matrix, float k);
matrixScale:
    push rdi
    push rsi

    call matrixGetCols
    mov rsi, [rdi]
    mov rdi, [rdi + 4]
    mov rdi, rax
    call matrixGetRows

    ret

; Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:

    ret

; Matrix matrixMul(Matrix a, Matrix b);
matrixMul:

    ret





