section .text

extern malloc
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

;cells are stored 'as is', but matrix rows are aligned by 4 to use cells in SSE instructions
;struct matrix_t {
;   const uint64_t rows, cols;   //real size of matrix
;   const uint64_t aligned_rows, aligned_cols; //aligned size
;   float data[rows * aligned_cols];
;}
;typdef matrix_t* Matrix;
;unused cells are filled with zeros
struc matrix_t
    rows:           resq    1
    cols:           resq    1
    aligned_rows:   resq    1
    aligned_cols:   resq    1
    data:           resq    1
endstruc

;in:
;   RDI - matrix
;   RSI - uint64_t rows
;   RDX - uint64_t cols
;out:
;   RAX - point to exact cell
%macro get_data_pointer 0
    imul rsi, [rdi + aligned_cols]
    add rsi, rdx 
    shl rsi, 2                  ; *= 4 
    mov rax, [rdi + data] 
    add rax, rsi 
%endmacro

;in:
;   %1 - matrix
;out:
;   RCX - matrix data length
%macro get_data_len 1
    mov     rcx, [%1 + aligned_rows]
    imul    rcx, [%1 + aligned_cols]
%endmacro

%macro align_by_4 1 ;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

;Matrix matrixNew(uint64_t rows, uint64_t cols);
;in:
;   RDI - uint64_t rows
;   RSI - uint64_t cols
;out:
;   RAX - Matrix
matrixNew:
    push    rdi
    push    rsi
    mov     rdi, matrix_t_size 
    call malloc                 ;malloc memory for structure
    pop     rsi
    pop     rdi
    mov     r8, rax
    ;save structure data
    mov     [r8 + rows], rdi       
    mov     [r8 + cols], rsi
    align_by_4  rdi
    align_by_4  rsi
    mov     [r8 + aligned_rows], rdi
    mov     [r8 + aligned_cols], rsi
    imul    rdi, rsi
    push    r8
    call calloc                 ;malloc memory for data and fill it with zeros
    pop     r8
    mov     [r8 + data], rax    ;save poiner to alocated memory
    mov     rax, r8
    ret

;void Matrix matrixDelete(Matrix matrix)
;in:
;   RDI - Matrix matrix
matrixDelete:
    push    rdi
    mov     rdi, [rdi + data]
    call free                   ;free cells
    pop     rdi
    call free                   ;free struct
    ret

;uint64_t matrxiGetRows(Matrix matrix)
;in:
;   RDI - Matrix matrix
;out:
;   RAX - matrix rows
matrixGetRows:
    mov     rax, [rdi + rows]
    ret

;uint64_t matrxiGetCols(Matrix matrix)
;in:
;   RDI - Matrix matrix
;out:
;   RAX - matrix cols
matrixGetCols:
    mov     rax, [rdi + cols]
    ret

;float matrixGet(Matrix matrix, uint64_t row, uint64_t col);
;in: 
;   RDI - Matrix matrix
;   RSI - uint64_t row
;   RDX - uint64_r col
;out:
;   XMM0 - cell value
matrixGet:
    get_data_pointer
    movss   xmm0, [rax]
    ret

;void matrixSet(Matrix matrix, uint64_t row, uint64_t col, float value);
;in:
;   RDI - Matrix matrix
;   RSI - uint64_t row
;   RDX - uint64_t col
;   xmm0 - value
;out:
;   nothing 
matrixSet:
    get_data_pointer
    movss   [rax], xmm0
    ret

;Matrix matrixCopy(Matrix matrix);
;in 
;   RDI - Matrix matrix
;out:
;   RAX - copy of input matrix
matrixCopy:
    push rbx
    mov rbx, rdi
    mov rdi, [rbx + rows]
    mov rsi, [rbx + cols]
    call matrixNew 

    get_data_len rax
    mov rdi, [rax + data]       ;dist data pointer
    mov rsi, [rbx + data]       ;src data pointer
    rep movsd                   ;copy memory (rcx - block length)
    mov rdi, rsi 
    
    pop rbx
    ret

;Matrix matrixScale(Matrix matrix, float value);
;in:
;   RDI - Matrix matrix
;   xmm0 - float value
;out:
;   RAX - matrix
matrixScale:
    pshufd  xmm0, xmm0, 0       ;there is four floats in xmm0 now
    call matrixCopy
    get_data_len rax
    mov     rdx, [rax + data]
.loop:                          ;rcx - loop (cells) counter
    movups  xmm1, [rdx]
    mulps   xmm1, xmm0
    movups  [rdx], xmm1
    add     rdx, 16             ;inc next cell poinet
    sub     rcx, 4              ;dec cells count
    jnz .loop

    ret

;Matrix matrixAdd(Matrix a, Matrix b);
;in:
;   RDI - Matrix a
;   RSI - Matrix b
;out:
;   RAX - Matrix result
matrixAdd:
    mov     r8, [rdi + rows]
    mov     r9, [rsi + rows]
    cmp     r8, r9              ;cols and rows should be equal
    jne .fail
    
    push    rsi
    call matrixCopy
    pop     rsi
    get_data_len rax
    mov     r8, [rax + data]    ;source
    mov     r9, [rsi + data]    ;dist
.loop:                          ;rcx - loop (cells) counter
    movaps xmm0, [r8]
    movaps xmm1, [r9]
    addps xmm0, xmm1
    movaps [r8], xmm0           ; A += B
    add     r8, 4*4             ;we've read 4*4 bytes
    add     r9, 4*4             ;we've read 4*4 bytes
    sub     rcx, 4              ;and proceed 4 floats
    jz .end
    jmp .loop
.fail:
    xor     rax, rax
.end:
    ret

;Matrix matrixTranspose(Matrix a);
;in:
;   RDI - Matrix a
;out:
;   RAX - transposed matrix
matrixTranspose:
    push    rdi
    mov     rsi, [rdi + rows]
    mov     rdi, [rdi + cols]
    call matrixNew
    pop     rdi
    mov     r8, [rdi + data]    ;source data
    mov     r9, [rax + data]    ;dist data 
    mov     r10, [rdi + aligned_rows]
    mov     r11, [rdi + aligned_cols]
    xor     rcx, rcx
.outer_loop:
    xor     rsi, rsi            ;inner_loop counter
    lea     rdi, [r9 + rcx * 4] ;first out cell

    .inner_loop:
        movups    xmm0, [r8]        ;xmm0 = A:B:C:D
        extractps [rdi], xmm0, 0    ;[rdi] = A

        lea       rdi, [rdi + r10 * 4] 
        extractps [rdi], xmm0, 1    ;[rdi] = B

        lea       rdi, [rdi + r10 * 4] 
        extractps [rdi], xmm0, 2    ;[rdi] = C

        lea       rdi, [rdi + r10 * 4] 
        extractps [rdi], xmm0, 3    ;[rdi] = D

        lea     rdi, [r13 + r10 * 4]
        add     r8, 4*4             ;we've read 4*4 bytes
        add     rsi, 4              ;and proceed 4 floats
        cmp     rsi, r11 
        jb .inner_loop

    inc     rcx
    cmp     rcx, r10
    jb .outer_loop

    ret

;Matrix matrixMul(Matrix a, Matrxi b);
;in:
;   RDI - Matrix a
;   RSI - Matrix b
;out:
;   EAX - Matrix c = a*b
matrixMul:
    push r14
    push r15
    push r13
    ;dimension check
    mov     r14, [rdi + cols]
    mov     r15, [rsi + rows]
    cmp     r14, r15
    jne .fail
 
    mov     r14, rdi
    mov     r15, rsi
    xchg    rdi, rsi 

    call matrixTranspose 
    mov     r13, rax 

    ;result matrix rows and cols
    mov     rdi, [r14 + rows]
    mov     rsi, [r15 + cols]

    call matrixNew 
    ;new matrix is stored in RAX
    mov     r8, [r14 + data] 
    mov     r11, [r14 + aligned_rows]

    ;calc len of one row
    mov     rdx, [r14 + aligned_cols]
    shl     rdx, 2 

    mov     r9, [r13 + data]    ;transposed matrix data 
    mov     r14, [rax + data]   ;result matrix data
    mov     r10, [r15 + aligned_cols]
    
    mov     rsi, r9
    mov     rdi, r10

.outer_loop:
    mov     r10, rdi
    mov     r9, rsi

    .inner_loop:
        xor     r15, r15        ;proceed elements counter
        xorps   xmm0, xmm0      ;sum will be stored here

        .sum_loop:
            movups  xmm1, [r8 + r15]    ;xmm1 = A:B:C:D
            movups  xmm2, [r9 + r15]    ;xmm2 = E:F:G:H
            mulps   xmm1, xmm2          ;xmm1 = A*E : B*F : C*G : D*H
            haddps  xmm1, xmm1          ;xmm1 = A*E+B*F : C*G+D*H : A*E+B*F : C*G+D*H
            haddps  xmm1, xmm1          ;xmm1 = A*E+B*F+C*G+D*H : ...
            addps   xmm0, xmm1          ;add to sum

            add     r15, 4*4    ;we've read 4*4 bytes
            cmp     r15, rdx    ;check if have readed all line
            jb .sum_loop

        add     r9, rdx 
        movss   [r14], xmm0     ;save new matrix' cell
        add     r14, 4
        dec     r10             ;check if have proceed all line
        jnz .inner_loop 

    add     r8, rdx 
    dec     r11
    jnz .outer_loop             ;WE'VE DONE IT! YAY!
    ;LETS HAVE A PARTY!
    ; (＾▽＾)

    push    rax
    mov     rdi, r13
    call matrixDelete           ;free transposed matrix memory
    pop     rax
.end:
    pop r13
    pop r15
    pop r14
    ret 

.fail
    xor     rax, rax            ;return zero
    jmp .end