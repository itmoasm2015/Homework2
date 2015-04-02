extern malloc
extern free

default rel

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

section .text

; matrixNew(int n, int m)
; Создает новую матрицу с n строками и m столбцами
; Матрица заполнена нулями
; rdi - n
; rsi - m
matrixNew:
    mov r8, rdi
    imul r8, rsi
    add r8, 2
    shl r8, 2
    push r8
    call malloc
    pop r8

    mov [rax], rdi
    mov [rax + 4], rsi

    push rax
    add rax, 8
    xor r9, r9
.fill_zeroes:
    mov dword [rax + r9 * 4], 0
    inc r9
    cmp r9, r8
    jl .fill_zeroes
    pop rax
    ret

matrixDelete:
    push rdi
    call free
    pop rdi
    ret

matrixGetRows:
    mov rax, [rdi]
    ret

matrixGetCols:
    mov rax, [rdi + 4]
    ret

matrixGet:
    mov r8, rsi
    imul r8, [rdi + 4]
    add r8, rdx
    add r8, 8
    movss xmm0, [rdi + r8 * 4]
    ret

matrixSet:
    mov r8, rsi
    imul r8, [rdi + 4]
    add r8, rdx
    add r8, 8
    movss [rdi + r8 * 4], xmm0
    ret

matrixScale:
    ret

matrixAdd:
    ret

matrixMul:
    ret
