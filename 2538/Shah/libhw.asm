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

%define ROWS 0
%define COLS 4
%define ALIGN_ROWS 8
%define ALIGN_COLS 12
%define VALUE 16

%macro roundTo4 1
    add %1, 3
    and %1, ~3
%endmacro

%macro roundTo16 1
    add %1, 15
    and %1, ~15
%endmacro

; struct Matrix
; pointer to area
; in first two dwords stroed real dims of matrix
; in second two dwords stored aligned dims of matrix
; values starts from (pointer + 16) aligned by 16 bytes


; this macros allocating memory
; and save dims of matrix
; rdi - count of rows
; rsi - count of columns
; return rax - pointer to new Matrix
%macro allocateMemory 0
    push rdi
    push rsi
    roundTo4 rsi
    roundTo4 rdi
    imul rdi, rsi
    lea rdi, [4*rdi + 64]
    push rsi
    call malloc
    pop rsi
    mov rdi, [rsp]
    mov [rax + COLS], edi
    mov rdi, [rsp + 8]
    mov [rax + ROWS], edi
    roundTo4 rdi
    mov [rax + ALIGN_ROWS], edi
    mov [rax + ALIGN_COLS], esi
    pop rsi
    pop rdi
%endmacro

; rdi - count of rows
; rsi - count of columns
matrixNew:
    push rsi
    allocateMemory
    ; rax - point to Matrix size

    mov esi, [rax + ALIGN_ROWS]
    imul esi, [rax + ALIGN_COLS]
    shl rsi, 2

    push rax
    add rax, VALUE
    roundTo16 rax
    ; zero
    xorps xmm0, xmm0
    ; fill matrix with zeroes
.fill_zero:
    sub rsi, 16 
    jnge .end_fiil

    movaps [rax + rsi], xmm0
    jmp .fill_zero
.end_fiil:
    pop rax
    pop rsi
    ret

; rdi - pointer to Matrix struct
matrixDelete:
    call free
    ret

; rdi - pointer to Matrix struct
matrixGetRows:
    mov eax, [rdi + ROWS]
    ret

; rdi - pointer to Matrix struct
matrixGetCols:
    mov eax, [rdi + COLS]
    ret

; rdi - pointer to Matrix struct
; rsi - row number
; rdx - column number
; return rax - address
%macro getCellAddress 0
    imul esi, dword [rdi + ALIGN_COLS]
    add rsi, rdx
    lea rax, [rdi + VALUE]
    roundTo16 rax
    lea rax, [rax + rsi*4]
%endmacro

; rdi - pointer to Matrix struct
; rsi - row number
; rdx - column number
; xmm0 - ans
matrixGet:
    getCellAddress
    movss xmm0, [rax]
    ret

; rdi - pointer to Matrix struct
; rsi - row number
; rdx - column number
matrixSet:
    getCellAddress
    movss [rax], xmm0
    ret

; rdi - pointer to Matrix struct
; xmm0 - scalar
matrixScale:
    ; create new matrix
    push rdi
    mov esi, [rdi + COLS] 
    mov edi, [rdi + ROWS]
    allocateMemory
    pop rdi

    ; in esi count of cells
    mov esi, [rdi + ALIGN_COLS]
    imul esi, [rdi + ROWS]
    shl rsi, 2

	unpcklps xmm0, xmm0	; xmm0 = 0:0:k:k
	unpcklps xmm0, xmm0	; xmm0 = k:k:k:k
    ; works fater than shufps xmm0, xmm0, 0x00

    push rax
    add rdi, VALUE
    roundTo16 rdi
    add rax, VALUE
    roundTo16 rax

.loop_clone:
    sub rsi, 16
    jnge .end_loop_clone

	movaps xmm1, [rdi+rsi]
	mulps xmm1, xmm0
	movaps [rax+rsi], xmm1
	jmp .loop_clone

.end_loop_clone:
    pop rax
    ret

; adding two matrix
; rdi - first matrix
; rsi - second matrix
; rax - pointer to new matrix 
matrixAdd:
    push rsi
    push rdi
    push rbx

    ; check equals rows
    mov ebx, [rsi + ROWS]
    cmp [rdi + ROWS], ebx
    jnz .diff_size

    ; check equals columns
    mov ebx, [rsi + COLS]
    cmp [rdi + COLS], ebx
    jnz .diff_size

    ; create new matrix
    mov esi, [rdi + COLS] 
    mov edi, [rdi + ROWS]
    allocateMemory
    mov rdi, [rsp + 8]
    mov rsi, [rsp + 16]

    mov ebx, [rsi + ROWS]
    imul ebx, [rsi + ALIGN_COLS]
    shl rbx, 2
    push rax
    add rdi, VALUE
    roundTo16 rdi
    add rsi, VALUE
    roundTo16 rsi
    add rax, VALUE
    roundTo16 rax

.sum_loop:
    sub ebx, 16
    jnge .end_add

	movaps xmm0, [rdi + rbx]
	addps xmm0, [rsi + rbx]
	movaps [rax+rbx], xmm0
    jmp .sum_loop

.diff_size:
    xor rax, rax
    push rax
.end_add:
    pop rax
    pop rbx
    pop rdi
    pop rsi
    ret

; rdi - first matrix a(n, l)
; rsi - second matrix b(l, m)
; return rax - pointer to new matrix c(n, m)
matrixMul:
    push rbx
    push r10
    push r11
    push r12
    push r13

    ; check dims
    mov ebx, [rsi + ROWS]
    cmp [rdi + COLS], ebx
    jnz .diff_size_mul

    ; create transposed matrix
    ; bT(m, l)
    mov rbx, rdi
    mov rcx, rsi
    ; rbx - first matrix a
    ; rcx - second matrix b
    mov edi, [rcx + COLS]
    mov esi, [rcx + ROWS]
    push rcx
    push rbx
    allocateMemory
    pop rbx
    pop rcx
    ; rdx - pointer to bT
    mov rdx, rax
    
    xor r8, r8
    mov r10d, [rdx + ALIGN_ROWS]
    mov r11d, [rdx + ALIGN_COLS]
    mov r12d, [rcx + ALIGN_COLS]
    shl r12, 2
    push rdx
    push rbx
    push rcx
    lea rcx, [rcx + VALUE]
    roundTo16 rcx

    lea rdx, [rdx + VALUE]
    roundTo16 rdx
    ; r8 - i
    ; r9 - j
    ; r10 - aligned rows of bT
    ; r11 - aligned columns of bT
    ; r12 - aligned columns of b

.loop_i:
    cmp r8, r10
    jge .end_loop_i

    xor r9, r9
    lea rsi, [rcx + r8*4]
.loop_j:
    cmp r9, r11
    jge .end_loop_j

    ; bT[i][j] = b[j][i]
    movss xmm0, [rsi]
    add rsi, r12
    movss [rdx], xmm0
    add rdx, 4

    inc r9
    jmp .loop_j

.end_loop_j:
    inc r8
    jmp .loop_i

.end_loop_i:
    pop rcx
    pop rbx
    pop rdx
    ; now we have transposed matrix in rdx
    ; first matrix in rbx
    ; second matrinx in rcx

    ; create resulting matrix c(n, m)
    mov edi, [rbx + ROWS]
    mov esi, [rcx + COLS]
    push rbx
    push rcx
    push rdx
    allocateMemory
    pop rdx
    pop rcx
    pop rbx
    ; rax - pointer to result matrix

    push rax
    xor r8, r8
    mov r11d, [rbx + ALIGN_ROWS]
    mov r12d, [rcx + ALIGN_COLS]
    mov r14d, [rbx + ALIGN_COLS]
    shl r14, 2

    push rdx
    ; rbx - point to values
    add rbx, VALUE
    roundTo16 rbx
    ; rdx - point to values
    add rdx, VALUE
    roundTo16 rdx
    ; rax - point to values
    add rax, VALUE
    roundTo16 rax
    mov rdi, rbx

    ; r8 - i
    ; r9 - j
    ; r10 - k
    ; r11 - aligned rows of a
    ; r12 - aligned cols of b
    ; r14 - (aligned cols of a) * 4
    ; rsi - pointer to a[i][k]
    ; rdi - pointer to bT[j][k]
    ; rax - pointer to c[i][j]
.loop_mul_i:
    cmp r8, r11
    jge .end_loop_mul_i

    xor r9, r9
    mov rsi, rdx
    ; rsi - pointer to bT[j][0]
.loop_mul_j:
    cmp r9, r12
    jge .end_loop_mul_j

    xor r10, r10
    ; store result in xmm0
    xorps xmm0, xmm0

.loop_mul_k:
    cmp r10, r14
    jge .end_loop_mul_k

    ; xmm1 = 4 a[i][k]
    movaps xmm1, [rdi + r10]
    ; xmm1 = 4 a[i][k] * b[k][j]
    mulps xmm1, [rsi + r10]
    ; xmm0 = 4 sum 
    addps xmm0, xmm1

    add r10, 16
    jmp .loop_mul_k

.end_loop_mul_k:
    ; sum four sums in one
    haddps xmm0, xmm0
    haddps xmm0, xmm0
    ; save result in matrix
    movss [rax], xmm0
    add rax, 4
    lea rsi, [rsi + r14]
    inc r9
    jmp .loop_mul_j

.end_loop_mul_j:
    lea rdi, [rdi + r14]
    inc r8
    jmp .loop_mul_i

.end_loop_mul_i:
    pop rdx
    ; in rdx was pointer to transposed matrix
    ; so we don't need it anymore
    ; delete transposed matrix
    mov rdi, rdx
    call matrixDelete
    jmp .end_mul
   
.diff_size_mul:
    xor rax, rax
    push rax
.end_mul:
    pop rax
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbx
    ret

; It is old version of two matrix
; it works four times slower than mul with transpose
; just leave there if smth going wrong with transpose
; This function is deprecated
; rdi - first matrix
; rsi - second matrix
matrixMulSlow:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13

    mov ebx, [rsi + ROWS]
    cmp [rdi + COLS], ebx
    jnz .diff_size_mul

    mov rbx, rdi ; first matrix
    mov rcx, rsi ; second matrix
    mov edi, [rbx + ROWS] ; edi - rows of c
    mov esi, [rcx + COLS] ; esi - columns of c
    push rbx
    push rcx

    allocateMemory

    pop rcx
    pop rbx

    ; mov edx, [rbx + ALIGN_COLS] ; edx - for k
    mov r11d, [rbx + ALIGN_COLS]
    shl r11, 2
    mov r12d, [rcx + ALIGN_COLS]
    shl r12, 2
    mov edi, [rbx + ALIGN_ROWS]
    ; mov esi, [rcx + ALIGN_COLS]
    xor r8, r8 ; i
    add rbx, VALUE
    roundTo16 rbx
    add rcx, VALUE
    roundTo16 rcx
    push rax
    add rax, VALUE
    roundTo16 rax

.loop_row:
    cmp r8, rdi
    jge .end_loop_row

    xor r9, r9 ; j
    mov r14, r8
    imul r14, r11
    add r14, rbx

.loop_column:
    cmp r9, r12
    jge .end_loop_column

    xor r10, r10 ; k
    xorps xmm0, xmm0
    mov rdx, r14

    mov r13, r12
    imul r13, r10
    add r13, r9
    add r13, rcx
.loop_k:
    cmp r10, r11
    jnl .end_loop_k

    movaps xmm1, [rdx]
    add rdx, 4*4

    ; movss xmm3, [r13]
    ; add r13, r12
    ; movss xmm2, xmm3
    ; pslldq xmm2, 4
    ; ; shufps xmm4, xmm4, 0x93
    ; movss xmm3, [r13]
    ; add r13, r12
    ; movss xmm2, xmm3
    ; pslldq xmm2, 4
    ; ; shufps xmm4, xmm4, 0x93
    ; movss xmm3, [r13]
    ; add r13, r12
    ; movss xmm2, xmm3
    ; pslldq xmm2, 4
    ; ; shufps xmm4, xmm4, 0x93
    ; movss xmm3, [r13]
    ; add r13, r12
    ; movss xmm2, xmm3
    ; shufps xmm2, xmm2, 0x1b

    movss xmm3, [r13]
    add r13, r12
    movss xmm2, [r13]
    add r13, r12
    movss xmm4, [r13]
    add r13, r12
    movss xmm5, [r13]
    add r13, r12
    pslldq xmm2, 4
    movss xmm2, xmm3
    pslldq xmm5, 4
    movss xmm5, xmm4
    ; shufps xmm2, xmm5, 01000100b
    movlhps xmm2, xmm5

    mulps xmm1, xmm2

    addps xmm0, xmm1

    ; movups xmm1, [r13]
    ; movups xmm2, [r13 + r12]
    ; movups xmm3, [r13 + 2 * r12]
    ; lea r13, [r13 + 2 * r12]
    ; movups xmm4, [r13 + r12]
    ; lea r13, [r13 + 2 * r12]
    ; shufps xmm5, xmm2, 00000000b
    ; psrldq xmm5, 8
    ; movss xmm5, xmm1
    ; pslldq xmm4, 4
    ; movss xmm4, xmm3
    ; shufps xmm5, xmm4, 01000100b

    ; mulps xmm5, [rdx]
    ; add rdx, 4*4

    ; addss xmm0, xmm5

    add r10, 16
    jmp .loop_k

.end_loop_k:
    haddps xmm0, xmm0
    haddps xmm0, xmm0
    movss [rax], xmm0
    add rax, 4
    add r9, 4
    jmp .loop_column
.end_loop_column:
    inc r8
    jmp .loop_row
.end_loop_row:
    sub rax, VALUE
    jmp .end_mul

.diff_size_mul:
    xor rax, rax
    push rax
.end_mul:
    pop rax
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret
    ; function is unused, but stable working
    ; scroll up to see correct mul
