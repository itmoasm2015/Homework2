section .text
; "Magic starts here" ;-)

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

;------------------------
; structure Matrix
; pointer to memory area
; in the first two dwords, real dimensions of the matrix is stored 
; in the second two dwords - aligned dimensions of the matrix
; values start from (pointer + 16) aligned by 16 bytes

; this macros allocates memory and saves dimensions of the matrix
; rdi - counter of the rows
; rsi - counter of the columns
; returns rax - pointer to the new Matrix

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

;-------------------------------
; creating the structure
; rdi - counter of the rows
; rsi - counter of the columns
matrixNew:
    push rsi
    allocateMemory
    ; rax - pointer to the Matrix's size

    mov esi, [rax + ALIGN_ROWS]
    imul esi, [rax + ALIGN_COLS]
    shl rsi, 2

    push rax
    add rax, VALUE
    roundTo16 rax
    ; zero
    xorps xmm0, xmm0    
    
    ; fills matrix with zeroes
.fill_zero:
    sub rsi, 16 
    jnge .end_fiil

    movaps [rax + rsi], xmm0
    jmp .fill_zero

.end_fiil:
    pop rax
    pop rsi
    ret

;-------------------------------------
; deleting the structure
; rdi - pointer to the Matrix-struct
matrixDelete:
    call free
    ret

;--------------------------------------
; getting the number of rows
; rdi - pointer to the Matrix-struct
matrixGetRows:
    mov eax, [rdi + ROWS]
    ret

;---------------------------------------
; getting the number of columns
; rdi - pointer to the Matrix-struct
matrixGetCols:
    mov eax, [rdi + COLS]
    ret

;---------------------------------------
; getting the cell's address
; rdi - pointer to the Matrix-struct
; rsi - rows number
; rdx - columns number
; returns rax - address
%macro getCellAddress 0
    imul esi, dword [rdi + ALIGN_COLS]
    add rsi, rdx
    lea rax, [rdi + VALUE]
    roundTo16 rax
    lea rax, [rax + rsi*4]
%endmacro

;---------------------------------------
; getting the value
; rdi - pointer to the Matrix-struct
; rsi - rows number
; rdx - columns number
; xmm0 - answer
matrixGet:
    getCellAddress
    movss xmm0, [rax]
    ret

; --------------------------------------
; setting the value
; rdi - pointer to the Matrix-struct
; rsi - rows number
; rdx - columns number
matrixSet:
    getCellAddress
    movss [rax], xmm0
    ret

;-----------------------------------------
; scaling of the matrix
; rdi - pointer to the Matrix-struct
; xmm0 - scalar
matrixScale:
    ; creates new matrix
    push rdi
    mov esi, [rdi + COLS] 
    mov edi, [rdi + ROWS]
    allocateMemory
    pop rdi

    ; esi - counter of the cells
    mov esi, [rdi + ALIGN_COLS]
    imul esi, [rdi + ROWS]
    shl rsi, 2

	unpcklps xmm0, xmm0	; xmm0 = 0:0:k:k
	unpcklps xmm0, xmm0	; xmm0 = k:k:k:k
    ; works quicker than shufps xmm0, xmm0, 0x00

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

;-----------------------------------------
; two matrices' addition
; rdi - the first matrix
; rsi - the second matrix
; rax - pointer to the new matrix 
matrixAdd:
    push rsi
    push rdi
    push rbx

    ; checks equal rows
    mov ebx, [rsi + ROWS]
    cmp [rdi + ROWS], ebx
    jnz .diff_size

    ; checks equal columns
    mov ebx, [rsi + COLS]
    cmp [rdi + COLS], ebx
    jnz .diff_size

    ; creates new matrix
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

;-----------------------------------------
; multiplication of the two matrices
; rdi - the first matrix, a(n, k)
; rsi - the second matrix, b(k, m)
; returns rax - pointer to the new matrix, c(n, m)
matrixMul:
    push rbx
    push r10
    push r11
    push r12
    push r13
    push r14

    ; checks dimensions
    mov ebx, [rsi + ROWS]
    cmp [rdi + COLS], ebx
    jnz .diff_size_mul

    ; creates transposed matrix, bT(m, l)
    mov rbx, rdi
    mov rcx, rsi
    ; rbx - the first matrix, a
    ; rcx - the second matrix, b
    mov edi, [rcx + COLS]
    mov esi, [rcx + ROWS]
    push rcx
    push rbx
    allocateMemory
    pop rbx
    pop rcx
    ; rdx - pointer to the transposed matrix, bT
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
    ; r10 - aligned rows of bT (transposed matrix)
    ; r11 - aligned columns of bT (transposed matrix)
    ; r12 - aligned columns of b (the second matrix)

.loop_i:
    cmp r8, r10
    jge .end_loop_i

    xor r9, r9
    lea rsi, [rcx + r8 * 4]

.loop_j:
    cmp r9, r11
    jge .end_loop_j

    ; bT[i][j] <- b[j][i]
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
    ; transposed matrix is stored in rdx
    ; the first matrix is in rbx
    ; the second matrix is in rcx

    ; creates resulting matrix, c(n, m)
    mov edi, [rbx + ROWS]
    mov esi, [rcx + COLS]
    push rbx
    push rcx
    push rdx
    allocateMemory
    pop rdx
    pop rcx
    pop rbx
    ; rax - pointer to the resulting matrix

    push rax
    xor r8, r8
    mov r11d, [rbx + ALIGN_ROWS]
    mov r12d, [rcx + ALIGN_COLS]
    mov r14d, [rbx + ALIGN_COLS]
    shl r14, 2

    push rdx
    ; rbx - pointes to the values
    add rbx, VALUE
    roundTo16 rbx
    ; rdx - pointes to the values
    add rdx, VALUE
    roundTo16 rdx
    ; rax - pointes to the values
    add rax, VALUE
    roundTo16 rax
    mov rdi, rbx

    ; r8 - i
    ; r9 - j
    ; r10 - k
    ; r11 - aligned rows of a
    ; r12 - aligned columns of b
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
    ; stores result in xmm0
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
    ; sums four sums in one
    haddps xmm0, xmm0
    haddps xmm0, xmm0
    ; saves result in the matrix
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
    ; the pointer to transposed matrix is stored in rdx
    ; no need to store it
    ; deleting transposed matrix
    mov rdi, rdx
    call matrixDelete
    jmp .end_mul
   
.diff_size_mul:
    xor rax, rax
    push rax

.end_mul:
    pop rax
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbx
    ret

;----------------------------------
; "Magic ends here"
;
; @author Aydar Gizatullin a.k.a. lightning95 (aydar.gizatullin@gmail.com)
;  
; Bye-bye ;-)
