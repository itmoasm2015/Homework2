; A simple library for working with matrices.
; Uses some AVX2 features, requiring an appropriate CPU.

; A matrix is a void*, pointing to an object having the following structure:
%define rows_offset          0 ; rows (4 bytes)
%define cols_offset          4 ; cols (4 bytes)
%define rows_aligned_offset  8 ; rows aligned to 8 bytes (4 bytes)
%define cols_aligned_offset 12 ; cols aligned to 8 bytes (4 bytes)
                               ; 16 bytes empty, to ensure 32-byte alignment (hope it’ll help to make it work under MacOS)
%define data_offset         32 ; float[rows_aligned * cols_aligned]

default rel                    ; use rip-relative addressing

extern aligned_alloc
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
    add          rcx, 7                       ; align rows and cols to 8
    and          rcx, ~7
    mov          rdx, rsi
    add          rdx, 7
    and          rdx, ~7
    mov          rax, rcx
    push         rdx
    mul          rdx
    shl          rax, 2                       ; rax := number of bytes in the storage
    add          rax, data_offset             ; we need memory for rows, cols and so on too
    push         rcx
    push         rdi
    push         rsi

    mov          rdi, 32
    mov          rsi, rax
    push         rax
    call         aligned_alloc                ; allocate the memory for the matrix
    pop          rcx
    test         rax, rax
    jz           .NULL                        ; don’t try to zero NULL!
    mov          rdi, rax
    mov          r8,  rax
    xor          eax, eax
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
    sub          rsp, 8                       ; stack alignment
    call         free
    add          rsp, 8
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
    mov          eax, [rdi + cols_aligned_offset]
    mov          rcx, rdx
    mul          rsi
    add          rax, rcx
    movss        xmm0, [rax*4 + rdi + data_offset]
    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
    mov          eax, [rdi + cols_aligned_offset]
    mov          rcx, rdx
    mul          rsi
    add          rax, rcx
    movss        [rax*4 + rdi + data_offset], xmm0
    ret

; Matrix matrixScale(Matrix matrix, float k)
matrixScale:
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
    sub          rsp, 24                      ; subtract 16 + 8 to provide the 16-byte alignment
    movdqa       [rsp], xmm0                  ; save xmm0 to the stack
    call         matrixNew                    ; create a new matrix with the corresponding size
    movdqa       xmm0, [rsp]                  ; pop xmm0 back
    add          rsp, 24
    pop          r8
    pop          rcx
    add          rcx,  data_offset
    mov          rdx,  data_offset
    vbroadcastss ymm1, xmm0                   ; populate the float argument to the whole AVX register
    .loop                                     ; unrolled the loop for better performance
      vmovaps    ymm0, [r8 + rdx]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx], ymm0
      vmovaps    ymm0, [r8 + rdx + 32]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 32], ymm0
      vmovaps    ymm0, [r8 + rdx + 64]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 64], ymm0
      vmovaps    ymm0, [r8 + rdx + 96]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 96], ymm0
      vmovaps    ymm0, [r8 + rdx + 128]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 128], ymm0
      vmovaps    ymm0, [r8 + rdx + 160]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 160], ymm0
      vmovaps    ymm0, [r8 + rdx + 192]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 192], ymm0
      vmovaps    ymm0, [r8 + rdx + 224]
      vmulps     ymm0, ymm1
      vmovaps    [rax + rdx + 224], ymm0
      add        rdx, 256
      cmp        rdx, rcx
      jl         .loop
    ret

; Matrix matrixAdd(Matrix a, Matrix b)
matrixAdd:
    xor          rax,  rax
    mov          r8,   [rdi + rows_offset]   ; rows and cols numbers must match, return NULL otherwise
    cmp          r8,   [rsi + rows_offset]
    jne          .return
    mov          r8,   [rdi + cols_offset]
    cmp          r8,   [rsi + cols_offset]
    jne          .return

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
    sub          rsp, 16                      ; subtract 16 bytes for xmm0
    movdqa       [rsp], xmm0                  ; save xmm0 to the stack
    call         matrixNew                    ; create a new matrix with the corresponding size
    movdqa       xmm0, [rsp]                  ; pop xmm0 back
    add          rsp, 16
    pop          r9
    pop          r8
    pop          rcx
    test         rax, rax
    jz           .return                      ; return NULL if couldn’t create the result matrix
    add          rcx,  data_offset
    mov          rdx,  data_offset
    .loop                                     ; unrolled the loop for better performance
      vmovaps    ymm0, [r8 + rdx]
      vmovaps    ymm1, [r9 + rdx]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx], ymm0
      vmovaps    ymm0, [r8 + rdx + 32]
      vmovaps    ymm1, [r9 + rdx + 32]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 32], ymm0
      vmovaps    ymm0, [r8 + rdx + 64]
      vmovaps    ymm1, [r9 + rdx + 64]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 64], ymm0
      vmovaps    ymm0, [r8 + rdx + 96]
      vmovaps    ymm1, [r9 + rdx + 96]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 96], ymm0
      vmovaps    ymm0, [r8 + rdx + 128]
      vmovaps    ymm1, [r9 + rdx + 128]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 128], ymm0
      vmovaps    ymm0, [r8 + rdx + 160]
      vmovaps    ymm1, [r9 + rdx + 160]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 160], ymm0
      vmovaps    ymm0, [r8 + rdx + 192]
      vmovaps    ymm1, [r9 + rdx + 192]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 192], ymm0
      vmovaps    ymm0, [r8 + rdx + 224]
      vmovaps    ymm1, [r9 + rdx + 224]
      vaddps     ymm0, ymm1
      vmovaps    [rax + rdx + 224], ymm0
      add        rdx, 256
      cmp        rdx, rcx
      jl         .loop
    .return
    ret

; An inner function, used for multiplying. Takes a matrix and creates the transposed one.
; Matrix matrixTranspose(const Matrix a)
matrixTranspose:
    mov          r8, rdi
    mov          edi, [r8 + cols_offset]
    mov          esi, [r8 + rows_offset]
    push         r8
    call         matrixNew
    pop          r8
    test         rax, rax
    jz           .return                      ; return NULL if couldn’t create the result matrix

    push         rbx
    mov          ecx, [r8 + rows_offset]
    mov          rdi, rax
    mov          r9, [r8 + rows_offset]
    .loop_rows
      dec        ecx
      mov        ebx, [r8 + cols_offset]
      ; I guess the cache is clever enough not to be slow when I go backwards
      .loop_cols
        dec      ebx                          ; matrixGet and matrixSet inlined
        mov      eax, [r8 + cols_aligned_offset]
        mul      ecx
        add      eax, ebx
        mov      esi, [rax*4 + r8 + data_offset]

        mov      eax, [rdi + cols_aligned_offset]
        mul      ebx
        add      eax, ecx
        mov      [rax*4 + rdi + data_offset], esi

        test ebx, ebx
        jnz .loop_cols
      test ecx, ecx
      jnz .loop_rows
    pop rbx
    mov rax, rdi
    .return
    ret

; Matrix matrixMul(Matrix a, Matrix b)
matrixMul:
    mov          r8, rdi
    mov          r9, rsi
    xor          rax, rax
    mov          ecx, [r8 + cols_offset]
    cmp          ecx, [r9 + rows_offset]
    jne          .return                      ; return NULL if the sizes don’t match
    mov          rdi, r9
    push         r8
    call         matrixTranspose
    pop          r8
    test         rax, rax
    jz           .return                      ; return NULL if couldn’t create the transposed matrix
    mov          r9, rax
    mov          edi, [r8 + rows_offset]
    mov          esi, [r9 + rows_offset]
    push         r8
    push         r9
    sub          rsp, 8                       ; align stack by 16 bytes
    call         matrixNew
    add          rsp, 8
    pop          r9
    pop          r8
    test         rax, rax
    jz           .return                      ; return NULL if couldn’t create the result matrix
    push         rbx
    push         rbp
    xor          ebx, ebx
    xor          ebp, ebp
    xor          ecx, ecx
    .loop_rows
      xor        ebx, ebx
      .loop_cols
        xor      ebp, ebp          ; not sure if using ebp as a counter is a good idea, but why not?
        xorps   xmm1, xmm1         ; the accumulator
        .loop_sum
          push   rax
          push   rcx               ; matrixGet inlined twice, modified for getting 4 values at once
          mov    eax, [r8 + cols_aligned_offset]
          mul    rbx
          add    rax, rbp
          movaps xmm2, [rax*4 + r8 + data_offset]
          mov    rcx, [rsp]        ; get rcx from the stack
          mov    eax, [r9 + cols_aligned_offset]
          mul    rcx
          add    rax, rbp
          movaps xmm0, [rax*4 + r9 + data_offset]
          pop    rcx
          pop    rax
          dpps   xmm0, xmm2, 0xF1  ; calculate the dot product...
                                   ;; there’s no AVX instruction to calculate the dot product
                                   ;; of 8 floats, so SSE is probably the best choise here
          addps  xmm1, xmm0        ; ...and add it to the accumulator

          add    ebp, 4
          cmp    ebp, [r9 + cols_offset]
          jl     .loop_sum
        mov      rdi, rax
        push     rax
        mov      eax, [rdi + cols_aligned_offset]  ; put the result into the matrix (matrixSet inlined)
        mul      rbx
        add      rax, rcx
        movss    [rax*4 + rdi + data_offset], xmm1
        pop      rax

        inc      ebx
        cmp      ebx, [rax + cols_offset]
        jl       .loop_cols
      inc        ecx
      cmp        ecx, [rax + rows_offset]
      jl         .loop_rows

    pop          rbp
    pop          rbx

    push rax
    mov          rdi, r9
    call         free               ; delete the transposed matrix
    pop rax
    .return
    ret
