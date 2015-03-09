section .text


extern malloc
extern free


global matrixNew
global matrixClone
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul


                    struc   Matrix_t
rows:               resq    1
cols:               resq    1
rows_align:         resq    1
cols_align:         resq    1
cells:              resq    1
                    endstruc


; Matrix matrixNew(unsigned int rows, unsigned int cols);
;
; Takes:
;   RDI - unsigned int rows
;   RSI - unsigned int cols
; Returns:
;   RAX - Matrix (=R8)
; Uses:
;   R8 - Matrix

matrixNew:          push rdi
                    push rsi
                    mov rdi, Matrix_t_size
                    call malloc
                    mov r8, rax
                    pop rsi
                    pop rdi
                    mov [r8 + rows], rdi
                    mov [r8 + cols], rsi
; RDI - ceil(rows / 4) * 4
; RSI - ceil(cols / 4) * 4
                    dec rdi
                    shr rdi, 2
                    shl rdi, 2
                    lea rdi, [rdi + 4]
                    dec rsi
                    shr rsi, 2
                    shl rsi, 2
                    lea rsi, [rsi + 4]
                    mov [r8 + rows_align], rdi
                    mov [r8 + cols_align], rsi
                    imul rdi, rsi
                    lea rdi, [rdi * 4]
                    push rdi
                    push r8
                    call malloc
                    pop r8
                    pop rcx
                    shr rcx, 2
                    mov [r8 + cells], rax
                    mov rdi, rax
                    xor eax, eax
                    cld
                    rep stosd                       ; fill cells with zeros
                    mov rax, r8
                    ret

; Matrix matrixClone(Matrix matrix);
;
; Takes:
;   RDI - Matrix matrix
; Returns:
;   RAX - new Matrix (=RDX)
; Uses:
;   R8 - Matrix matrix (=RDI)

matrixClone:        mov r8, rdi
                    mov rdi, [r8 + rows]
                    mov rsi, [r8 + cols]
                    push r8
                    call matrixNew
                    pop r8
                    mov rcx, [r8 + rows_align]
                    imul rcx, [r8 + cols_align]
                    mov rsi, [r8 + cells]
                    mov rdi, [rax + cells]
                    cld
                    rep movsd                       ; copy cells from old to new matrix
                    ret

; void matrixDelete(Matrix matrix);
;
; Takes:
;   RDI - Matrix matrix

matrixDelete:       push rdi
                    mov rdi, [rdi + cells]
                    call free
                    pop rdi
                    call free
                    ret

; unsigned int matrixGetRows(Matrix matrix);
;
; Takes:
;   RDI - Matrix matrix
; Returns:
;   RAX - matrix.rows

matrixGetRows:      mov rax, [rdi + rows]
                    ret

; unsigned int matrixGetCols(Matrix matrix);
;
; Takes:
;   RDI - Matrix matrix
; Returns:
;   RAX - matrix.cols

matrixGetCols:      mov rax, [rdi + cols]
                    ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;
; Takes:
;   RDI - Matrix matrix
;   RSI - unsigned int row
;   RDX - unsigned int col
; Returns:
;   XMM0 - matrix.cells[index]
; Uses:
;   R8 - matrix.cells
;   R9 - index (=row * cols_align + col)

matrixGet:          mov r8, [rdi + cells]
                    mov r9, [rdi + cols_align]
                    imul r9, rsi
                    lea r9, [r9 + rdx]
                    movss xmm0, [r8 + r9 * 4]
                    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;
; Takes:
;   RDI - Matrix matrix
;   RSI - unsigned int row
;   RDX - unsigned int col
;   XMM0 - float value 
; Uses:
;   R8 - matrix.cells
;   R9 - index (=row * cols_align + col)

matrixSet:          mov r8, [rdi + cells]
                    mov r9, [rdi + cols_align]
                    imul r9, rsi
                    lea r9, [r9 + rdx]
                    movss [r8 + r9 * 4], xmm0
                    ret

; Matrix matrixScale(Matrix matrix, float k);
;
; Takes:
;   RDI - Matrix matrix
;   XMM0 - float k
; Returns:
;   RAX - new Matrix
; Uses:
;   RCX - (matrix.rows_align * matrix.cols_align) / 4
;   RDX - new_matrix.cells

matrixScale:
; I honestly believe that xmm0 is not affected by malloc()
; And therefore I do not save it on stack
                    call matrixClone
                    mov rcx, [rax + rows_align]
                    imul rcx, [rax + cols_align]
                    shr rcx, 2
                    mov rdx, [rax + cells]
                    shufps xmm0, xmm0, 0            ; xmm0 = (k:k:k:k)
.scale_loop:        movups xmm1, [rdx]
                    mulps xmm1, xmm0                ; qword [rdx] *= xmm0
                    movups [rdx], xmm1
                    lea rdx, [rdx + 16]
                    loop .scale_loop
                    ret

; Matrix matrixAdd(Matrix a, Matrix b);
;
; Takes:
;   RDI - Matrix a
;   RSI - Matrix b
; Returns:
;   RAX - new Matrix
; Uses:
;   RCX - (new_matrix.rows_align * new_matrix.cols_align) / 4
;   RDX - new_matrix.cells
;   R8 - temporary register 1
;   R9 - temporary register 2

matrixAdd:          mov r8, [rdi + rows]
                    mov r9, [rsi + rows]
                    cmp r8, r9
                    jne .failure
                    mov r8, [rdi + cols]
                    mov r9, [rsi + cols]
                    cmp r8, r9
                    jne .failure
                    push rsi
                    call matrixClone
                    pop rsi
                    mov rcx, [rax + rows_align]
                    imul rcx, [rax + cols_align]
                    shr rcx, 2
                    mov rdx, [rax + cells]
                    mov r8, [rsi + cells]
.add_loop:          movups xmm0, [rdx]
                    addps xmm0, [r8]
                    movups [rdx], xmm0
                    lea rdx, [rdx + 16]
                    lea r8, [r8 + 16]
                    loop .add_loop
                    ret
.failure:           xor rax, rax
                    ret

; Matrix matrixTranspose(Matrix matrix);
;
; Takes:
;   RDI - Matrix matrix (m*n)
; Returns:
;   RAX - matrix^T (n*m)
; Uses:
;   R8 - m
;   R9 - n
;   R10 - mx_index
;   R11 - new_mx_index
;   RCX - i (0..m-1)
;   RDX - j (0..n-1)

matrixTranspose:    push rdi
                    mov rsi, [rdi + rows]
                    mov rdi, [rdi + cols]
                    call matrixNew
                    pop rdi
                    mov r8, [rax + cols_align]
                    mov r9, [rax + rows_align]
                    mov r10, [rdi + cells]
                    mov rdi, [rax + cells]
                    xor rcx, rcx
.transpose_loop_1:  xor rdx, rdx
                    lea r11, [rdi + rcx * 4]
.transpose_loop_2:  movups xmm0, [r10]
                    movss [r11], xmm0
                    psrldq xmm0, 4
                    lea r11, [r11 + r8 * 4]
                    movss [r11], xmm0
                    psrldq xmm0, 4
                    lea r11, [r11 + r8 * 4]
                    movss [r11], xmm0
                    psrldq xmm0, 4
                    lea r11, [r11 + r8 * 4]
                    movss [r11], xmm0
                    lea r11, [r11 + r8 * 4]
                    lea rdx, [rdx + 4]
                    lea r10, [r10 + 16]
                    cmp rdx, r9
                    jb .transpose_loop_2
                    inc rcx
                    cmp rcx, r8
                    jb .transpose_loop_1
                    ret

; Matrix matrixMul(Matrix a, Matrix b);
;
; Takes:
;   RDI - Matrix a (m*n)
;   RSI - Matrix b (n*p)
; Returns:
;   RAX - new Matrix (m*p)
; Uses:
;   R8 - i (m-1..0)
;   R9 - j (p-1..0)
;   R10 - n
;   R11 - k (0..n-1)
;   RCX - new_mx_index
;   RBX - temporary variable 1
;   RBP - temporary variable 2
;   RDX - temporary variable 3

matrixMul:          mov r8, [rdi + cols]
                    mov r9, [rsi + rows]
                    cmp r8, r9
                    jne .failure
                    push rbx
                    push rbp
                    push rdi
                    push rsi
                    mov rdi, rsi
                    call matrixTranspose
                    pop rsi
                    pop rdi
                    push rax
                    push rdi
                    mov rdi, [rdi + rows]
                    mov rsi, [rsi + cols]
                    call matrixNew                  ; create new m*p matrix
                    mov rcx, [rax + cells]
                    pop rdi
                    pop rsi
                    push rsi
                    mov r8, [rdi + rows_align]
                    mov r9, [rsi + rows_align]
                    mov r10, [rdi + cols_align]
                    mov rdi, [rdi + cells]
                    mov rsi, [rsi + cells]
                    mov rdx, rsi
                    mov rbx, r10
                    mov rbp, r9
.mul_loop_1:        dec r8
                    mov rsi, rdx
                    mov r9, rbp
.mul_loop_2:        dec r9
                    mov r10, rbx
                    shr r10, 2
                    movss xmm0, [fzero]
.mul_loop_3:        dec r10
                    movups xmm1, [rdi]              ; calculate dot product
                    movups xmm2, [rsi]
                    dpps xmm1, xmm2, 0xF1
                    addss xmm0, xmm1
                    lea rdi, [rdi + 16]
                    lea rsi, [rsi + 16]
                    test r10, r10
                    jnz .mul_loop_3
                    sub rdi, rbx
                    sub rdi, rbx
                    sub rdi, rbx
                    sub rdi, rbx
                    movss [rcx], xmm0
                    lea rcx, [rcx + 4]
                    test r9, r9
                    jnz .mul_loop_2
                    lea rdi, [rdi + rbx * 4]
                    test r8, r8
                    jnz .mul_loop_1
                    pop rdi
                    push rax
                    call matrixDelete
                    pop rax
                    pop rbp
                    pop rbx
                    ret
.failure:           xor rax, rax
                    ret


section .rodata


fzero               dd 0.0