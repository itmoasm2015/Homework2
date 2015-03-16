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
    call malloc
    mov [rdx + data], rax

    mov rcx, rdi
    .set_zeroes
        mov dword [rax + 4 * rcx - 4], 0
        loop .set_zeroes
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
    lea rax, [rdi + data + rsi]
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

matrixTranspose:
    push rbp
    push rdi
    push rsi
    push r11
    mov rbp, rdi
    mov rsi, [rbp + initRows]
    mov rdi, [rbp + initCols]
    call matrixNew
    mov rbp, [rbp + data]
    xor r8, r8
    .loop1
        xor r9, r9
        .loop2
            mov r10, r9
            imul r10, rdi
            add r10, r8
            shl r10, 2
            mov r11, [rbp]
            mov [rax + data + r10], r11
            inc rbp
            inc r9
            cmp r9, rdi
            jne .loop2
        inc r8
        cmp r8, rsi
        jne .loop1
    pop r11
    push rsi
    push rdi
    push rbp
    ret

matrixMul:
    mov rax, [rdi + initCols]
    cmp rax, [rsi + initRows]
    jne .error
    push r12
    push rbp
    push r13

    mov r11, rdi
    mov r12, rsi
    mov rdi, [r11 + initRows]
    mov rsi, [r12 + initCols]
    call matrixNew
    mov rdi, r11
    mov rsi, r12

    push rax
    xchg rsi, rdi
    call matrixTranspose
    xchg rsi, rdi
    mov rsi, rax
    pop rax

    mov rbp, [rax + data]
    mov rcx, [r11 + cols]
    mov r11, [r11 + rows]
    mov r12, [r12 + cols]
    xor r8, r8
    .loop1
        xor r9, r9
        .loop2
            xor r10, r10
            xorps xmm0, xmm0
            .loop3
                mov r13, r8
                imul r13, rcx
                add r13, r10
                shl r13, 2
                movups xmm1, [rdi + data + r13]

                mov r13, r9
                imul r13, rcx
                add r13, r10
                shl r13, 2
                mulps xmm1, [rsi + data + r13]

                addps xmm0, xmm1
                add r10, 4
                cmp r10, rcx
                jne .loop3
            movups [rbp], xmm0
            add rbp, 4
            inc r9
            cmp r9, r12
            jne .loop2
        inc r8
        cmp r8, r11
        jne .loop1
    mov rdi, rsi
    call matrixDelete

    pop r13
    pop rbp
    pop r12
    ret
    .error
    mov rax, 0
    ret
