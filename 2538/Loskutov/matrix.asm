; A simple library for working with matrices.
; Uses some AVX2 features, requiring an appropriate CPU.
; A matrix is a void*, pointing to an object having the following structure:
%define rows_offset          0 ; rows (4 bytes)
%define cols_offset          4 ; cols (4 bytes)
%define rows_aligned_offset  8 ; rows aligned to 8 bytes (4 bytes)
%define cols_aligned_offset 12 ; cols aligned to 8 bytes (4 bytes)
%define data_offset         16 ; float[rows_aligned * cols_aligned]

default rel

extern calloc
extern aligned_alloc
extern memset
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

section .text
; Matrix matrixNew(unsigned int rows, unsigned int cols)
matrixNew:
    mov          rcx, rdi
    test         rcx, 7                       ; check whether the number of rows is already aligned
    jz           .rows_aligned
    and          rcx, ~7
    add          rcx, 8
    .rows_aligned
    mov          rdx, rsi
    test         rdx, 7                       ; check whether the number of cols is already aligned
    jz           .cols_aligned
    and          rdx, ~7
    add          rdx, 8
    .cols_aligned
    mov          rax, rcx
    push         rdx
    mul          rdx
    shl          rax, 2                       ; rax == number of bytes in the storage
    add          rax, data_offset             ; we need memory for rows, cols and so on too
    mov          rdx, rax
    push         rcx
    push         rdi
    push         rsi

    mov          rdi, 16
    mov          rsi, rax
    push         rdx
    call         aligned_alloc
    pop          rdx
    test         rax, rax
    jz           .NULL                        ; don’t try to zero NULL!
    mov          rdi, rax
    mov          r8,  rax
    xor          eax, eax
    mov          rcx, rdx
    shr          rcx, 2
    rep          stosd                        ; fill the matrix with zeros
    mov          rax, r8
    .NULL
    pop          rsi
    pop          rdi
    pop          rcx
    pop          rdx
    test         rax, rax
    jz           .return                      ; if the result is NULL, simply return it
    mov          [rax + rows_offset], rdi     ; else, set the correct values
    mov          [rax + cols_offset], rsi
    mov          [rax + rows_aligned_offset], rcx
    mov          [rax + cols_aligned_offset], rdx
    .return
    ret

; void matrixDelete(Matrix matrix)
matrixDelete:
    call         free
    ret

; unsigned int matrixGetRows(Matrix matrix)
; saves all the registers except eax
matrixGetRows:
    mov          eax, [rdi + rows_offset]
    ret

; unsigned int matrixGetCols(Matrix matrix)
; saves all the registers except eax
matrixGetCols:
    mov          eax, [rdi + cols_offset]
    ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
matrixGet:
    xor          rax, rax
    mov          eax, [rdi + cols_aligned_offset]
    mov          rcx, rdx
    mul          rsi
    add          rax, rcx
    movsd        xmm0, [rax*4 + rdi + data_offset]
    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
    xor          rax, rax
    mov          eax, [rdi + cols_aligned_offset]
    mov          rcx, rdx
    mul          rsi
    add          rax, rcx
    movsd        [rax*4 + rdi + data_offset], xmm0
    ret

; Matrix matrixScale(Matrix matrix, float k)
matrixScale:
    vbroadcastss ymm1, xmm0
    mov          r8,   rdi
    xor          rdi,  rdi
    xor          rsi,  rsi
    xor          rax,  rax
    mov          eax,  [r8 + rows_aligned_offset]
    mul          dword [r8 + cols_aligned_offset]
    shl          rax,  2                      ; rax := number of bytes in the matrix
    push         rax
    push         r8
    mov          edi,  [r8 + rows_offset]
    mov          esi,  [r8 + cols_offset]
    call         matrixNew                    ; create a new matrix with the corresponding size
    pop          r8
    pop          rcx
    add          rcx,  data_offset
    mov          rdx,  data_offset
    .loop                                     ; unrolled the loop for better performance
        vmovaps  ymm0, [r8 + rdx]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx], ymm0
        vmovaps  ymm0, [r8 + rdx + 32]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 32], ymm0
        vmovaps  ymm0, [r8 + rdx + 64]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 64], ymm0
        vmovaps  ymm0, [r8 + rdx + 96]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 96], ymm0
        vmovaps  ymm0, [r8 + rdx + 128]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 128], ymm0
        vmovaps  ymm0, [r8 + rdx + 160]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 160], ymm0
        vmovaps  ymm0, [r8 + rdx + 192]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 192], ymm0
        vmovaps  ymm0, [r8 + rdx + 224]
        vmulps   ymm0, ymm1
        vmovaps  [rax + rdx + 224], ymm0
        add      rdx, 256
        cmp      rdx, rcx
        jl       .loop
    ret

; Matrix matrixAdd(Matrix a, Matrix b)
matrixAdd:
    xor          rax,  rax
    mov          r8,   [rdi + rows_offset]   ; rows and cols numbers must match, return NULL otherwise
    cmp          r8,   [rsi + rows_offset]
    jne          .exit
    mov          r8,   [rdi + cols_offset]
    cmp          r8,   [rsi + cols_offset]
    jne          .exit

    mov          r8,   rdi                    ; r8 := a
    mov          r9,   rsi                    ; r9 := b
    xor          rdi,  rdi
    xor          rsi,  rsi
    mov          eax,  [r8 + rows_aligned_offset]
    mul          dword [r8 + cols_aligned_offset]
    shl          rax,  2                      ; rax := number of bytes in the matrix
    push         rax
    push         r8
    push         r9
    mov          edi,  [r8 + rows_offset]
    mov          esi,  [r8 + cols_offset]
    call         matrixNew                    ; create a new matrix with the corresponding size
    pop          r9
    pop          r8
    pop          rcx
    add          rcx,  data_offset
    mov          rdx,  data_offset
    .loop                                     ; unrolled the loop for better performance
        vmovaps  ymm0, [r8 + rdx]
        vmovaps  ymm1, [r9 + rdx]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx], ymm0
        vmovaps  ymm0, [r8 + rdx + 32]
        vmovaps  ymm1, [r9 + rdx + 32]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 32], ymm0
        vmovaps  ymm0, [r8 + rdx + 64]
        vmovaps  ymm1, [r9 + rdx + 64]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 64], ymm0
        vmovaps  ymm0, [r8 + rdx + 96]
        vmovaps  ymm1, [r9 + rdx + 96]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 96], ymm0
        vmovaps  ymm0, [r8 + rdx + 128]
        vmovaps  ymm1, [r9 + rdx + 128]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 128], ymm0
        vmovaps  ymm0, [r8 + rdx + 160]
        vmovaps  ymm1, [r9 + rdx + 160]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 160], ymm0
        vmovaps  ymm0, [r8 + rdx + 192]
        vmovaps  ymm1, [r9 + rdx + 192]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 192], ymm0
        vmovaps  ymm0, [r8 + rdx + 224]
        vmovaps  ymm1, [r9 + rdx + 224]
        vaddps   ymm0, ymm1
        vmovaps  [rax + rdx + 224], ymm0
        add      rdx, 256
        cmp      rdx, rcx
        jl       .loop
    .exit
    ret

