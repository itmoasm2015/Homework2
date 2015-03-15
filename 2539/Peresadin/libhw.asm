section .text

extern malloc
extern free

global matrixNew
global matrixDelete

struc Matrix
    rows:     resd 1
    cols:     resd 1
    data:     resd 1
    initRows: resd 1
    initCols: resd 1
endstruc

matrixNew:
    push rdi
    mov rdi, Matrix_size
    call malloc
    pop rdi
    mov rdx, rax ;rdx - указатель на результирующую структуру
    mov [rax + initRows], rdi
    mov [rax + initCols], rsi
    
    add rdi, 3
    add rsi, 3
    shr rdi, 2
    shr rsi, 2
    shl rdi, 2
    shl rsi, 2
    mov [rax + rows], rdi
    mov [rax + cols], rsi

    imul rdi, rsi
    call malloc
    mov [rdx + data], rax

    mov rcx, rdi
    .set_zeroes
        mov qword [rax + rcx - 1], 0
        loop .set_zeroes
    ret

matrixDelete:
    ;TODO 
    ret

matrixGetRows:
    mov rax, [rdi + initRows]
    ret

matrixGetCols:
    mov rax, [rdi + initCols]
    ret

loadAdress:
    imul r8, r9
    lea rax, [rdi + data + rdx]
    imul rsi, [rdi + cols]
    lea rax, [rax + rsi]
    ret

matrixGet:
    call loadAdress
    movss xmm0, [rax]
    ret

matrixSet:
    call loadAdress
    movss [rax], xmm0
    ret

matrixClone:
    push rbp
    mov rbp, rdi
    mov rdi, [rbp + initRows]
    mov rsi, [rbp + initCols]
    call newMatrix
    mov rdi, [rax + data]
    mov rsi, [rbp + data]
    mov rcx, [rax + rows]
    imul rcx, [rax + cols]
    .copy
        mov rbp, [rsi + rcx - 1]
        mov qword [rdi + rcx - 1], rbp
        loop .copy
    pop rbp
    ret


