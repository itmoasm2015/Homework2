section .text

extern calloc
extern calloc
extern free

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul
global matrixCopy
global matrixTranspose

SIZE_OF_FLOAT EQU 4

;macro for rounding to multiplier of 4
%macro round_to_four 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

struc Matrix
    cells           resq 1 ; pointer to float array
    rows            resq 1 ; number of rows
    cols            resq 1 ; number of columns
    aligned_rows    resq 1 ; aligned number of rows
    aligned_cols    resq 1 ; aligned number of columnss
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int cols)
;Create new matrix and fill it with zeros.
;args:      RDI - number of rows
;           RSI - number of cols
;returns:   RAX - pointer to matrix instance/null
matrixNew:
    push rdi ; save the state of registers
    push rsi
    mov rdi, Matrix_size ; allocate memory for the new Matrix
    call malloc

    mov rcx, rax ; RAX contains the result of calloc, store it in RCX
    pop rsi      ; restore previously saved registers
    pop rdi

    mov [rax + rows], rdi
    mov [rax + cols], rsi

    round_to_four rdi ; align rows and columns
    round_to_four rsi

    mov [rax + aligned_rows], rdi ; initialize matrix parameters
    mov [rax + aligned_cols], rsi
    imul rdi, rsi ; calculate aligned matrix size
    mov rsi, SIZE_OF_FLOAT

    push rcx
    call calloc ; allocate memory for matrix
    pop rcx
    mov [rcx + cells], rax ; get pointer to allocated space
    mov rax, rcx ; move pointer to matrix instance
    
    ret