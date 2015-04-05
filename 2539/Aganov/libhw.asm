section .text
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

%define OFFSET_ROWS 0
%define OFFSET_COLS 4
%define OFFSET_ROWS_CAP 8
%define OFFSET_COLS_CAP 12
%define OFFSET_MATRIX 16


;matrix structure:
;    unsigned int rows
;    unsigned int columns
;    unsigned int rows_capacity = rows % 4 == 0 ? rows : rows - rows % 4 + 4
;    unsigned int columns_capacity = columns % 4 == 0 ? columns : columns - columns % 4 + 4
;    matrix rows_capacity * columns_capacity bytes


;arguments: rows in rdi(only 32bit), columns in rsi(only 32bit)
;returns pointer to matrix or NULL if some error (in rax)
;saves rdi and rsi
matrixNew:
    push    rdi
    push    rsi

    ;round to 4*k numbers
    add     rdi, 3
    and     rdi, -4
    add     rsi, 3
    and     rsi, -4

    ;calculating memory
    mov     rax, rdi
    mul     rsi
    cmp     rdx, 0
    jne     .overflow
    mov     rdx, 4;
    mul     rdx
    add     rax, 16
    adc     rdx, 0
    cmp     rdx, 0
    jne     .overflow

    ;allocating
    push    rdi
    push    rsi
    mov     rdi, rax
    mov     rsi, 1
    call    calloc
    pop     rsi
    pop     rdi

    cmp     rax, 0
    je      .overflow

    ;set cols and rows
    mov     [rax + OFFSET_ROWS_CAP], edi
    mov     [rax + OFFSET_COLS_CAP], esi
    pop     rsi
    pop     rdi
    push    rdi
    push    rsi
    mov     [rax + OFFSET_ROWS], edi
    mov     [rax + OFFSET_COLS], esi
    jmp     .exit

.overflow:
    xor     rax, rax
.exit:
    pop     rsi
    pop     rdi
    ret

;rdi - martix*
matrixDelete:
    call    free
    ret

;rdi - martix*
;returns result in rax
matrixGetRows:
    xor     rax, rax
    mov     eax, [rdi]
    ret

;rdi - martix*
;returns result in rax
matrixGetCols:
    xor     rax, rax
    mov     eax, [rdi + 4]
    ret

;rdi - martix*
;rsi(only 32bit) - row
;rdx(only 32bit) - col
;returns result in xmm0(only 32bit)
matrixGet:
    mov     rax, rsi
    mov     rcx, rdx
    mul     dword [rdi + OFFSET_COLS_CAP]
    add     rax, rcx
    mov     rsi, 4
    mul     rsi
    movd    xmm0, [rdi + rax + OFFSET_MATRIX]
    ret

;rdi - matrix*
;rsi(only 32bit) - row
;rdx(only 32bit) - col
;xmm0(only 32bit) - element
matrixSet:
    mov     rax, rsi
    mov     rcx, rdx
    mul     dword [rdi + OFFSET_COLS_CAP]
    add     rax, rcx
    mov     rsi, 4
    mul     rsi
    movd    dword [rdi + rax + OFFSET_MATRIX], xmm0;
    ret

;rdi - matrix*
;xmm0(only 32bit) - k
;rax - result(new matrix*) or NULL
matrixScale:
    ;set vector (k, k, k, k) in xmm0
    unpcklps xmm0, xmm0
    unpcklps xmm0, xmm0

    ;creating new matrix, pointer in rax, exit(0) if can't create new matrix
    sub     rsp, 16
    movups  [rsp], xmm0
    push    rdi
    mov     r8, rdi
    xor     rdi, rdi
    xor     rsi, rsi
    mov     edi, [r8 + OFFSET_ROWS]
    mov     esi, [r8 + OFFSET_COLS]
    call    matrixNew
    pop     rdi
    movups  xmm0, [rsp]
    add     rsp, 16
    cmp     rax, 0
    je      .exit

    ;calculating new matrix (r8 - end of the matrix, rcx - begin)
    xor     r8, r8
    xor     r9, r9
    mov     r8d, [rdi + OFFSET_ROWS_CAP]
    mov     r9d, [rdi + OFFSET_COLS_CAP]
    imul    r8, r9
    add     r8, 4
    imul    r8, 4
    mov     rcx, OFFSET_MATRIX
.multiply_loop:
    movups  xmm1, [rdi + rcx]
    mulps   xmm1, xmm0
    movups  [rax + rcx], xmm1
    add     rcx, 16
    cmp     r8, rcx
    jne     .multiply_loop

.exit:
    ret

;rdi - first matrix
;rsi - second matrix
;returns new matrix or NULL in rax
matrixAdd:
    ;check if matrix have equal size, otherwise exit(0)
    mov     eax, [rdi + OFFSET_ROWS]
    cmp     eax, dword [rsi + OFFSET_ROWS]
    jne     .error
    mov     eax, [rdi + OFFSET_COLS]
    cmp     eax, dword [rsi + OFFSET_COLS]
    jne     .error

    ;creating new matrix, pointer in rax, exit(0) if can't create new matrix
    push    rdi
    push    rsi
    mov     r8, rdi
    xor     rdi, rdi
    xor     rsi, rsi
    mov     edi, [r8 + OFFSET_ROWS]
    mov     esi, [r8 + OFFSET_COLS]
    call    matrixNew
    pop     rsi
    pop     rdi
    cmp     rax, 0
    jz      .error

    ;calculating borders of new matrix (r8 - end of the matrix, rcx - begin)
    xor     r8, r8
    xor     r9, r9
    mov     r8d, [rdi + OFFSET_ROWS_CAP]
    mov     r9d, [rdi + OFFSET_COLS_CAP]
    imul    r8, r9
    add     r8, 4
    imul    r8, 4
    mov     rcx, OFFSET_MATRIX

    ;adding: matrix[rax] = matrix[rsi] + matrix[rdi]
.add_loop:
    movups  xmm0, [rsi + rcx]
    addps   xmm0, [rdi + rcx]
    movups  [rax + rcx], xmm0
    add     rcx, 16
    cmp     r8, rcx
    jne     .add_loop
    ret

.error:
    xor     rax, rax
    ret

;rdi - first matrix
;rsi - second matrix
;returns new matrix or NULL in rax
matrixMul:
    ;check sizes of matrix, if they are bad then exit(0)
    mov     eax, [rdi + OFFSET_COLS]
    cmp     eax, dword [rsi + OFFSET_ROWS]
    jne     .error

    ;creating new matrix, pointer in rax, exit(0) if can't create new matrix
    push    rdi
    push    rsi
    mov     r8, rdi
    mov     r9, rsi
    xor     rdi, rdi
    xor     rsi, rsi
    mov     edi, [r8 + OFFSET_ROWS]
    mov     esi, [r9 + OFFSET_COLS]
    call    matrixNew
    pop     rsi
    pop     rdi
    cmp     rax, 0
    jz      .error

    push    rax

    ;calculating border of new matrix (r8 - end of the matrix)
    xor     r8, r8
    mov     r8d, [rax + OFFSET_ROWS_CAP]
    imul    r8d, dword [rax + OFFSET_COLS_CAP]
    imul    r8, 4
    add     r8, rax
    add     r8, 16

    ;calculating r10 - aligned number of columns in new matrix in bytes (i.e. just * 4)
    ;r9 - aligned number of columns in bytes in first matrix
    xor     r10, r10
    mov     r10d, [rax + OFFSET_COLS_CAP]
    imul    r10, 4
    xor     r9, r9
    mov     r9d, [rdi + OFFSET_COLS_CAP]
    imul    r9, 4

    ;calculating rax - data of new matrix, rdi - first, rsi - second
    add     rax, OFFSET_MATRIX
    add     rdi, OFFSET_MATRIX
    add     rsi, OFFSET_MATRIX

    ;calculating new matrix (r11 - current column)
    xor     r11, r11
.multiply_loop:
    xorps   xmm0, xmm0
    xor     rdx, rdx
    mov     rcx, r11
    ;calculating 4 number: 16 bytes from rax
.count:
    xorps   xmm1, xmm1
    movd    xmm1, [rdi + rdx]
    unpcklps xmm1, xmm1
    unpcklps xmm1, xmm1
    movups  xmm2, [rsi + rcx]
    mulps   xmm1, xmm2
    addps   xmm0, xmm1
    add     rcx, r10
    add     rdx, 4
    cmp     rdx, r9
    jne     .count
    ;calculating current column
    add     r11, 16
    cmp     r11, r10
    jne     .old_row
    xor     r11, r11
    add     rdi, r9
.old_row:
    ;set 4 floats (16 bytes) in new matrix
    movups [rax], xmm0
    add rax, 16
    cmp r8, rax
    jne .multiply_loop

    pop rax
    ret

.error:
    xor     rax, rax
    ret
