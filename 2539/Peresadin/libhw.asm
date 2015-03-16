section .text

extern malloc
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
global matrixTranspose

struc Matrix
    rows:     resq 1
    cols:     resq 1
    data:     resq 1
    initRows: resq 1
    initCols: resq 1
endstruc

matrixNew:
    push rsi
    push rdi
    mov rdi, Matrix_size
    call malloc
    pop rdi
    pop rsi
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
    mov rcx, rdi
    shl rdi, 2
    push rdx
    push rcx
    call malloc
    pop rcx
    pop rdx
    mov [rdx + data], rax

    .set_zeroes
        mov dword [rax + 4 * rcx - 4], 0
        loop .set_zeroes
    mov rax, rdx
    ret

matrixDelete:
    push rdi
    mov rdi, [rdi + data]
    call free
    pop rdi
    call free
    ret

matrixGetRows:
    mov rax, [rdi + initRows]
    ret

matrixGetCols:
    mov rax, [rdi + initCols]
    ret

loadAdress:
    imul rsi, [rdi + cols]
    add rsi, rdx
    shl rsi, 2
    mov rax, [rdi + data]
    add rax, rsi
    ret

matrixGet:
    call loadAdress
    movss xmm0, [rax]
    ret

matrixSet:
    call loadAdress
    movss [rax], xmm0
    ret

matrixScale:
    push rbp
    mov rbp, rdi
    mov rdi, [rbp + initRows]
    mov rsi, [rbp + initCols]
    call matrixNew
    mov rcx, [rbp + rows]
    imul rcx, [rbp + cols]
    sub rcx, 4
    unpcklps xmm0, xmm0
    unpcklps xmm0, xmm0
    mov rbp, [rbp + data]
    mov r8, [rax + data]
    .loop
        movups xmm1, [rbp + 4 * rcx]
        mulps xmm1, xmm0
        movups [r8 + 4 * rcx], xmm1
        sub rcx, 4
        jns .loop
    pop rbp
    ret

matrixAdd:
    push rdi
    push rsi
    mov r8, rdi
    mov r9, rsi
    mov rdi, [r8 + initRows]
    cmp rdi, [r9 + initRows]
    jne .error
    mov rsi, [r8 + initCols]
    cmp rsi, [r9 + initCols]
    jne .error

    call matrixNew
    pop rsi
    pop rdi
    mov rcx, [rdi + rows]
    imul rcx, [rdi + cols]
    sub rcx, 4
    mov rdi, [rdi + data]
    mov rsi, [rsi + data]
    mov r10, [rax + data]
    .loop
        movups xmm0, [rdi + 4 * rcx]
        addps xmm0, [rsi + 4 * rcx]
        movups [r10 + 4 * rcx], xmm0
        sub rcx, 4
        jns .loop
    ret
    .error
    mov rax, 0
    ret

matrixTranspose:
    push rbp
    push rdi
    push rsi

    mov rbp, rdi
    mov rsi, [rbp + initRows]
    mov rdi, [rbp + initCols]
    call matrixNew
    mov rsi, [rbp + rows]
    mov rdi, [rbp + cols]

    mov rbp, [rbp + data]
    xor r8, r8
    .loop1
        xor r9, r9
        .loop2
            mov r10, r9
            imul r10, rsi
            add r10, r8
            shl r10, 2
            movss xmm0, [rbp]
            add r10, [rax + data]
            movss [r10], xmm0
            add rbp, 4
            inc r9
            cmp r9, rdi
            jne .loop2
        inc r8
        cmp r8, rsi
        jne .loop1
    pop rsi
    pop rdi
    pop rbp
    ret

matrixMul:
    mov rax, [rdi + initCols]
    cmp rax, [rsi + initRows]
    jne .error

    push rbp
    push r12
    push r13
    push r14
    push r15

    mov r13, rdi
    mov r12, rsi
    mov rdi, [r13 + initRows]
    mov rsi, [r12 + initCols]
    call matrixNew
    mov rdi, r13
    mov rsi, r12

    push rax
    xchg rsi, rdi
    call matrixTranspose
    xchg rsi, rdi
    mov rsi, rax
    mov rdx, rsi
    pop rax

    mov rbp, [rax + data]
    mov rcx, [rdi + cols]
    mov r11, [rdi + rows]
    mov r12, [rsi + rows]
    mov rdi, [rdi + data]
    mov rsi, [rsi + data]

    xor r8, r8
    .loop1
        xor r9, r9
        mov r15, rsi
        .loop2
            lea r14, [r8 * 4]
            imul r14, rcx
            add r14, rdi

            xor r10, r10
            xorps xmm0, xmm0
            .loop3
                movups xmm1, [r14]
                mulps xmm1, [r15]

                haddps xmm1, xmm1
                haddps xmm1, xmm1
                addss xmm0, xmm1
                add r14, 4*4
                add r15, 4*4
                add r10, 4
                cmp r10, rcx
                jne .loop3
            movss [rbp], xmm0
            add rbp, 4
            inc r9
            cmp r9, r12
            jne .loop2
        inc r8
        cmp r8, r11
        jne .loop1

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp

    push rax
    mov rdi, rdx
    call matrixDelete
    pop rax

    ret
    .error
    xor rax, rax
    ret
