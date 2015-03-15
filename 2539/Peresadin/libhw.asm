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
        mov dword [rax + 4 * rcx - 4], 0
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
    push rsi
    push rcx
    mov rbp, rdi
    mov rdi, [rbp + initRows]
    mov rsi, [rbp + initCols]
    call matrixNew
    mov rdi, [rax + data]
    mov rsi, [rbp + data]
    mov rcx, [rax + rows]
    imul rcx, [rax + cols]
    .copy
        mov rbp, [rsi + 4 * rcx - 4]
        mov qword [rdi + 4 * rcx - 4], rbp
        loop .copy
    pop rcx
    pop rsi
    pop rbp
    ret

matrixScale:
    push rcx
    call matrixClone
    mov rcx, [rdi + rows]
    imul rcx, [rdi + cols]
    unpcklps xmm0, xmm0
    unpcklps xmm0, xmm0
    .loop
        movups xmm1, [rax + data + 4 * rcx - 4]
        mulss xmm1, xmm0
        movups [rax + data + 4 * rcx - 4], xmm1
        sub rcx, 4
        cmp rcx, 0
        jne .loop
    pop rcx
    ret

matrixAdd:
    mov r8, rdi
    mov r9, rsi

    mov rdi, [r8 + initRows]
    cmp rdi, [r9 + initRows]
    jne .error
    mov rsi, [r8 + initCols]
    cmp rsi, [r9 + initCols]
    jne .error

    call matrixNew
    mov rcx, [rdi + rows]
    imul rcx, [rdi + cols]
    .loop
        movups xmm0, [r8 + data + 4 * rcx - 4]
        addss xmm0, [r9 + data + 4 * rcx - 4]
        movups [rax + data + 4 * rcx - 4], xmm0
        sub rcx, 4
        cmp rcx, 0
        jne .loop
    ret
    .error
    mov rax, 0
    ret

matrixMul:
    mov rax, [rdi + initCols]
    cmp rax, [rsi + initRows]
    jne .error
    push r12
    ;TODO trans
    mov rcx, [rdi + initCols]
    mov r11, [rdi + rows]
    mov r12, [rsi + cols]
    mov r8, 0
    .loop1
        mov r9, 0
        .loop2
            mov r10, 0
            .loop3
                inc r10
                cmp r10, rcx
                jne .loop3

            inc r9
            cmp r9, r12
        inc r8
        cmp r8, r11
        jne .loop1
    pop r12
    ret
    .error
    mov rax, 0
    ret
