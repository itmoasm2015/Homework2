extern aligned_alloc
extern free

; Side lengths of matrices are aligned by 4.
; By doing so, I am able to use SSE without need to handle
; their borders' positions.
%macro getAligned 1
        add %1, 3
        and %1, ~3
%endmacro

; Structure of the matrix:
;  * rows - 4 bytes
;  * cols - 4 bytes
;  * reserved space - 8 bytes
;  * matrix content row by row
%define getRows(r, m) mov r, [m]
%define getCols(r, m) mov r, [m + 4]

; void *matrixNew(unsigned rows, unsigned cols);
global matrixNew
matrixNew:
        push rbx
        push r12
        push r13
        push rbp
        mov rbp, rsp

        ; get aligned row and column counts
        mov eax, edi
        mov ebx, eax
        mov edx, esi
        mov ecx, edx
        getAligned eax ; aligned rows
        getAligned edx ; aligned columns

        mul edx ; edx:eax - content size in floats
        shl rdx, 32
        mov edx, eax
        lea r13, [rdx + 3 * rdx] ; r13 - content size in bytes
        lea rsi, [r13 + 16]      ; rsi - matrix size in bytes
        mov r12, rcx             ; height is going to be messed
        mov rdi, 16
        and rsp, ~15 ; align rsp (in case we are called by
                     ;            another matrix function)
        call aligned_alloc ; aligned_alloc(16, rsi)
        mov [rax], ebx
        mov rcx, r12
        mov [rax + 4], ecx

        ; initialize it with zeroes
        xorps xmm0, xmm0
.loop:
        movaps [rax + r13], xmm0
        sub r13, 16
        jnz .loop

        mov rsp, rbp
        pop rbp
        pop r13
        pop r12
        pop rbx
        ret

; void matrixDelete(void *matrix);
global matrixDelete
matrixDelete: jmp free

; unsigned matrixGetRows(void *matrix);
global matrixGetRows
matrixGetRows:
        getRows(eax, rdi)
        ret

; unsigned matrixGetCols(void *matrix);
global matrixGetCols
matrixGetCols:
        getCols(eax, rdi)
        ret

; Load the address of the specific cell in a matrix.
; Will need this in 2 functions.
%macro loadCellAddress 0
        ; rdi - matrix
        ; rsi - row
        ; rdx - column
        getCols(ecx, rdi)
        getAligned ecx
        lea rdi, [rdi + 4 * rdx + 16] ; column number set
        mov eax, esi
        mul ecx ; edx:eax - number of floats in esi rows
        shl rdx, 32
        mov edx, eax
        lea rdi, [rdi + 4 * rdx] ; row number set
%endmacro

; float matrixGet(void *matrix, unsigned row, unsigned col);
global matrixGet
matrixGet:
        loadCellAddress
        movss xmm0, dword [rdi]
        ret

; float matrixSet(void *matrix, unsigned row, unsigned col);
global matrixSet
matrixSet:
        loadCellAddress
        movss dword [rdi], xmm0
        ret

; void* matrixScale(void *matrix, float factor);
global matrixScale
matrixScale:
        push rbx
        push r12
        push r13

        mov rbx, rdi
        getRows(edi, rbx)
        getCols(esi, rbx)
        ; backup width and height
        mov r12, rdi
        mov r13, rsi
        movaps xmm1, xmm0 ; backup xmm0 (hope that
                          ; aligned_alloc does not alter xmm1)
        call matrixNew
        mov rdi, rax
        mov rax, r12
        mov rcx, r13
        getAligned eax
        getAligned ecx
        mul ecx ; edx:eax - matrix content size in floats
        shl rdx, 32
        mov edx, eax
        mov rax, rdi

        ; put the lowest float in xmm1 everywhere
        shufps xmm1, xmm1, 0
.loop:
        movaps xmm0, [rbx + 4 * rdx]
        mulps xmm0, xmm1
        movaps [rdi + 4 * rdx], xmm0
        sub rdx, 4
        jnz .loop

        pop r13
        pop r12
        pop rbx
        ret

; void *matrixAdd(void *matr1, void *matr2);
; The procedure is almost the same as above
global matrixAdd
matrixAdd:
        push rbx
        push r12
        push r13
        push r14

        mov r12, rdi
        mov r13, rsi
        getRows(edi, r12)
        getRows(ecx, r13)
        cmp edi, ecx
        jne .badSizes
        getCols(esi, r12)
        getCols(ecx, r13)
        cmp esi, ecx
        jne .badSizes
        mov ebx, edi
        mov r14, rsi
        call matrixNew
        mov rdi, rax
        mov rax, r14
        getAligned eax
        getAligned ebx
        mul ebx
        shl rdx, 32
        mov edx, eax
        mov rax, rdi
.loop:
        movaps xmm0, [r12 + rdx * 4]
        addps xmm0, [r13 + rdx * 4]
        movaps [rdi + rdx * 4], xmm0
        sub rdx, 4
        jz .success
        jmp .loop
.badSizes:
        xor rax, rax
.success:
        pop r14
        pop r13
        pop r12
        pop rbx
        ret

; Load a 4x4 chunk at %1, transpose it and store in xmm4-xmm7
; %2 - matrix column count
%macro loadAndTranspose 2
        movaps xmm0, [%1]           ; xmm0 <- 1a 2a 3a 4a
        movaps xmm1, [%1 + 4 * %2]  ; xmm1 <- 1b 2b 3b 4b
        lea %1, [%1 + 8 * %2]
        movaps xmm2, [%1]           ; xmm2 <- 1c 2c 3c 4c
        movaps xmm3, [%1 + 4 * %2]  ; xmm3 <- 1d 2d 3d 4d
        shl %2, 3
        sub %1, %2
        shr %2, 3
        movaps xmm4, xmm0
        movlhps xmm4, xmm1          ; xmm4 <- 1a 2a 1b 2b
        movaps xmm6, xmm2
        movlhps xmm6, xmm3          ; xmm6 <- 1c 2c 1d 2d
        movaps xmm5, xmm4
        shufps xmm4, xmm6, EVEN_POS ; xmm4 <- 1a 1b 1c 1d
        shufps xmm5, xmm6, ODD_POS  ; xmm5 <- 2a 2b 2c 2d
        movaps xmm6, xmm1
        movhlps xmm6, xmm0          ; xmm6 <- 3a 4a 3b 4b
        movaps xmm8, xmm3
        movhlps xmm8, xmm2          ; xmm8 <- 3c 4c 3d 4d
        movaps xmm7, xmm6
        shufps xmm6, xmm8, EVEN_POS ; xmm6 <- 3a 3b 3c 3d
        shufps xmm7, xmm8, ODD_POS  ; xmm7 <- 4a 4b 4c 4d
%endmacro

; Load a 1x4 chunk of the (1st) matrix at %1, multiply it
; by xmm4-xmm7 and store the sum (to be added to the
; product matrix) at xmm0.
%macro loadAndMultiply 1
        movaps xmm3, [%1]
        movaps xmm0, xmm3
        mulps xmm0, xmm4  ; xmm0 <- 1a 2a 3a 4a
        movaps xmm1, xmm3
        mulps xmm1, xmm5  ; xmm1 <- 1b 2b 3b 4b
        movaps xmm2, xmm3
        mulps xmm2, xmm6  ; xmm2 <- 1c 2c 3c 4c
        mulps xmm3, xmm7  ; xmm3 <- 1d 2d 3d 4d
        haddps xmm0, xmm1
        haddps xmm2, xmm3
        haddps xmm0, xmm2 ; xmm0 <- (1a+2a+3a+4a) (1b+2b+3b+4b)
                          ;         (1c+2c+3c+4c) (1d+2d+3d+4d)
%endmacro

; void *matrixMul(void *matr1, void *matr2);
global matrixMul
matrixMul:
        push rbx
        push r12
        push r13
        push r14
        push r15

        ; Once again, the initial part is as usual
        mov r12, rdi
        mov r13, rsi
        xor rcx, rcx
        getCols(ecx, r12)
        mov r15, rcx
        getRows(edx, r13)
        cmp ecx, edx
        jne .badSizes
        xor rdi, rdi
        xor rsi, rsi
        getRows(edi, r12)
        getCols(esi, r13)
        mov r14, rdi
        mov rbx, rsi
        call matrixNew
        getAligned r14
        getAligned rbx
        getAligned r15
        add r12, 16
        add r13, 16
        ; r12 - 1st matrix content
        ; r13 - 2nd matrix content
        ; rax - result
        ; r14 - result rows
        ; rbx - result cols
        ; r15 - 1st matrix cols
        ;
        ; Temporary variables:
        ;  * c[r9][r8] = \sum_{r11=1}^n a[r9][r11] * b[r11][r8]
        ;  * r10 <-> a[r9][r11]
        ;  * r13 <-> b[r11][r8] (not needed to be backed up)
        ;  * rdi <-> c[0][r8]
        ;  * rdx <-> c[r9][r8]
        mov r11, r15
.r11loop:
        mov r8, rbx
        lea rdi, [rax + 16]
.r8loop:
        ; r13 points to the current chunk in the 2nd
        ; matrix; it will be increased further
        loadAndTranspose r13, rbx
        mov r9, r14
        mov r10, r12
        mov rdx, rdi
.r9loop:
        loadAndMultiply r10
        lea r10, [r10 + 4 * r15]
        addps xmm0, [rdx]
        movaps [rdx], xmm0
        lea rdx, [rdx + 4 * rbx]
        sub r9, 1
        jnz .r9loop

        add r13, 16
        add rdi, 16
        sub r8, 4
        jnz .r8loop

        add r12, 16
        lea r13, [r13 + 4 * rbx]
        lea r13, [r13 + 8 * rbx]
        sub r11, 4
        jnz .r11loop

        jmp .success
.badSizes:
        xor rax, rax
.success:
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        ret

ODD_POS equ (3 << 6) + (1 << 4) + (3 << 2) + 1
EVEN_POS equ (2 << 6) + (0 << 4) + (2 << 2) + 0
