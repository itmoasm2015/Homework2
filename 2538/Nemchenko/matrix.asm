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
    mov  r8d, [rdi + 4]  ; r8d = m
    imul esi, r8d        ; esi = row * m
    add  esi, edx        ; esi = row * m + col
    lea  rax, [rdi + rsi * 4 + 8]
    ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
matrixGet:
    push r8
    push rax
    call matrixGetAddress
    movss xmm0, [rax]
    pop rax
    pop r8
    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
matrixSet:
    call matrixGetAddress
    movss [rax], xmm0
    ret

; Matrix matrixScale(Matrix matrix, float k);
matrixScale:
    ;--allocate new Matrix
    push r12
    push r13
    push rdi

    mov esi, [rdi + 4]
    mov edi, [rdi]
    call matrixNew

    pop rdi

    push rax
    ;--

    mov  r12d, [rdi]       ; r12d = n
    mov  r13d, [rdi + 4]   ; r13d = m

    mov  [rax], r12d       ; *rax = n
    mov  [rax + 4], r13d   ; *(rax + 1) = m

    add  rax, 8            ; rax - point to new matrix
    add  rdi, 8            ; rdi - pointer to matrix

    imul r12d, r13d        ; r12d = m * n

    ; highest and lowest 32 bits of xmm0 will be equal (float) k
    ; xmm0 = (k, k, k, k)
    unpcklps xmm0, xmm0
    unpcklps xmm0, xmm0

    xor  r13d, r13d
    .while_r9_less_r8
        cmp r13d, r12d
        jge .end_while_r9_less_r8

        movups xmm1, [rdi]
        mulps  xmm1, xmm0  ; xmm1 = (a[0] * b[0], a[1] * b[1], ..)
        movups [rax], xmm1

        add rdi, 4 * 4     ; skip 4 floats
        add rax, 4 * 4

        add r13d, 4        ; go to the nex 4 floats
        jmp .while_r9_less_r8
    .end_while_r9_less_r8

    pop rax
    pop r13
    pop r12
    ret

; Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:
    mov  r12d, [rdi]      ; r12d = n
    mov  r13d, [rdi + 4]  ; r13d = m

    cmp r12d, [rsi]       
    jne .ret0            ; getRows(a) != getRows(b)

    cmp r13d, [rsi + 4]   
    jne .ret0            ; getCols(a) != getCols(b)

    ;--allocate new Matrix
    push rsi
    push rdi

    mov esi, [rdi + 4]
    mov edi, [rdi]
    call matrixNew

    pop rdi
    pop rsi

    push rax
    ;--

    mov  [rax], r12d       ; *rax = n
    mov  [rax + 4], r13d   ; *(rax + 1) = m

    add  rax, 8            ; rax - point to new matrix
    add  rdi, 8            ; rdi - pointer to matrix a
    add  rsi, 8            ; rsi - pointer to matrix b

    imul r12d, r13d        ; r12d = m * n
    xor  r13d, r13d
    .while_r9_less_r8
        cmp r13d, r12d
        jge .end_while_r9_less_r8

        movups xmm0, [rdi]
        movups xmm1, [rsi]
        addps  xmm0, xmm1  ; xmm0 = (a[0] + b[0], a[1] + b[1], ..)
        movups [rax], xmm0

        add rdi, 4 * 4     ; skip 4 floats
        add rsi, 4 * 4
        add rax, 4 * 4

        add r13d, 4        ; go to the nex 4 floats
        jmp .while_r9_less_r8
    .end_while_r9_less_r8

    pop rax
    ret

    .ret0:
        mov rax, 0
        ret
        

; Matrix matrixMul(Matrix a, Matrix b);
; a - [n * m]
; b - [m * k]
matrixMul:
    mov r12d, [rdi]       ; r12d = getRows(a)
    mov r13d, [rdi + 4]   ; r13d = getCols(a)

    cmp r13d, [rsi]  
    jne .ret0             ; getCols(a) != getRows(b) 

    ;--allocate new Matrix [n * k]
    push rsi
    push rdi

    mov edi, r12d         ; edi = getRows(a)
    mov esi, [rsi + 4]    ; esi = getCols(b)
    call matrixNew

    pop rdi
    pop rsi

    push rax
    ;--

    ; rdi  = a
    ; rsi  = b
    ; rax  = result
    ; r12d = getRows(a)
    ; r13d = getCols(a)
    ; r15d = getCols(b)
    ; for (sz_t resRow = 0; resRow < getRows(); ++resRow)
    ;  for (sz_t resCol = 0; resCol < rhs.getCols(); ++resCol)
    ;    for (sz_t i = 0; i < getCols(); ++i)
    ;      result[resRow][resCol] += matrix[resRow][i] * rhs[i][resCol];
    mov r15d, [rsi + 4]
    xor r8d, r8d
    .while_r8d_less_rows_a:
        cmp r8d, r12d
        jge .end_while_r8d_less_rows_a
        xor r9d, r9d
        .while_r9d_less_cols_b:
            cmp r9d, r15d
            jge .end_while_r9d_less_cols_b
            xor r10d, r10d
            .while_r10d_less_cols_a:
                cmp r10d, r13d
                jge .end_while_r10d_less_cols_a
                push rdi
                push rsi

                mov  rsi, r8
                mov  rdx, r10
                call matrixGet
                movups xmm1, xmm0


                mov rdi, [rsp]
                mov rsi, r10
                mov rdx, r9
                call matrixGet
                mulss  xmm1, xmm0

                mov rdi, rax
                mov rsi, r8
                mov rdx, r9
                call matrixGet
                addss xmm0, xmm1

                mov rdi, rax
                call matrixSet

                pop rsi
                pop rdi

                inc r10
                jmp .while_r10d_less_cols_a
            .end_while_r10d_less_cols_a:

            inc r9
            jmp .while_r9d_less_cols_b
        .end_while_r9d_less_cols_b:

        inc r8
        jmp .while_r8d_less_rows_a
    .end_while_r8d_less_rows_a:


      
    ret

    .ret0:
        mov rax, 0
        ret

