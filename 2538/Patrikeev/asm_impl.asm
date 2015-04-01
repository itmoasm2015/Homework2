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
global matrixTranspose

section .text

;Matrix settles in memory as continuous block with appropriate offsets for information
;Its rows and columns are aligned to the nearest greater 4-divisible number
;to make it possible to use SSE instructions set
    struc Matrix_t
data:       resq    1   ;content of matrix
cols:       resq    1   ;number of columns
rows:       resq    1   ;number of rows
al_cols:    resq    1   ;aligned number of columns
al_rows     resq    1   ;aligned number of rows
    endstruc

;Round given number to the nearest greater 4-divisible number
%macro align4 1
    add     %1, 3
    shr     %1, 2
    shl     %1, 2 
%endmacro 

;;Matrix matrixNew(unsigned int rows, unsigned int cols);
;
; Parameters:
;   1) RDI - unsigned int rows 
;   2) RSI - unsigned int cols
; Returns:
;   RAX - address of new matrix matrix
matrixNew:
    push    rdi
    push    rsi

    mov     rdi, 1              ;allocate 1 element
    mov     rsi, Matrix_t_size  ;of size Matrix_t_size 
    call    calloc
    mov     rcx, rax            ;rcx - address of allocated memory for matrix

    pop     rsi
    pop     rdi

    mov     [rcx + rows], rdi   ;write number of rows
    mov     [rcx + cols], rsi   ;write number of columns

    align4  rdi                 ;align rows
    align4  rsi                 ;align columns

    mov     [rcx + al_rows], rdi ;write aligned number of rows
    mov     [rcx + al_cols], rsi ;write aligned number of columns

    push    rcx                  ;caller-save register
    
    imul    rdi, rsi             ;allocate (rows * columns) elements
    mov     rsi, 4               ;with size of 4 bytes (i.e. floats)
    call    calloc              

    pop     rcx                  ;restore address
    mov     [rcx + data], rax    ;write pointer to allocated content
    mov     rax, rcx             ;rax holds address of resulting matrtix

    ret

;;void matrixDelete(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   Nothing(void)
matrixDelete:
    push    rdi                  ;caller-save register
    mov     rdi, [rdi + data]    ;pointer to allocated memory
    call    free                 ;deallocate content of matrix
    pop     rdi
    call    free                 ;deallocate matrix structure
    ret

;;unsigned int matrixGetRows(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   RAX - number of rows (initial, i.e. not aligned)
matrixGetRows:
    mov     rax, [rdi + rows]
    ret

;;unsigned int matrixGetCols(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   RAX - number of cols (initial, i.e. not aligned)
matrixGetCols:
    mov     rax, [rdi + cols]    
    ret

;;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;;
; Parameters:
;   1) RDI - matrix address 
;   2) RSI - row number
;   3) RDX - column number
; Returns:
;   xmm0 - value of matrix[row][col] 
matrixGet:
    imul    rsi, [rdi + al_cols]    ;rsi = row * aligned_columns
    add     rsi, rdx                ;rsi = column + row * aligned_columns
    imul    rsi, 4                  ;rsi *= sizeof(float) 
    add     rsi, [rdi + data]       ;rsi points to cell matrix[row][col]
    movss   xmm0, [rsi]             ;xmm0 holds float value
    ret

;;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;;
; Parameters:
;   1) RDI - matrix address 
;   2) RSI - row number
;   3) RDX - column number
;   4) xmm0[0..31] - value to be set
; Returns:
;   Nothing(void)
matrixSet:
    imul    rsi, [rdi + al_cols]    ;rsi = row * aligned_columns
    add     rsi, rdx                ;rsi = column + row * aligned_columns
    imul    rsi, 4                  ;rsi *= sizeof(float) 
    add     rsi, [rdi + data]       ;rsi points to cell matrix[row][col]
    movss  [rsi], xmm0              ;set given value
    ret

;;Matrix matrixCopy(Matrix matrix)
;;
; Parameters:
;   1) RDI - address of matrix to be copied
; Returns:
;   RAX - address of copied matrix
matrixCopy:
    mov     rdx, rdi                ;save address

    mov     rdi, [rdx + rows]       ;rdi = number of rows
    mov     rsi, [rdx + cols]       ;rsi = numbre of columns

    push    rsi                     ;caller-save registers
    push    rdx
    call    matrixNew
    pop     rdx
    pop     rsi
    
    ;rax - address of copied matrix
    ;let's copy content too

    mov     rcx, [rax + al_rows]    ;rcx = aligned_columns
    imul    rcx, [rax + al_cols]    ;rcx = aligned_columns * aligned_rows
                                    ;rcx - number of cells to be copied
    
    cld
    mov     rdi, [rax + data]       ;set destination
    mov     rsi, [rdx + data]       ;set source
    rep     movsd                   ;repeat copying of float for RCX times

    ret


;;Matrix matrixScale(Matrix matrix, float k);
;;
; Parameters:
;   1) RDI - matrix address 
;   2) xmm0[0..31] - float multiplier
; Returns:
;   RAX - address of matrix which is multiplication of initial one by given multiplier
matrixScale:
    sub     rsp, 16         ;save xmm0 as it's caller-save registers
    movups  [rsp], xmm0
    push    rdi             ;rdi is also caller-save register

    call    matrixCopy
    
    pop     rdi             ;restore rdi
    movups  xmm0, [rsp]     ;restore xmm0
    add     rsp, 16         ;restore stack
    
    ;rax - address of copied matrix
    mov     rdi, [rax + data]       ;start of content
    mov     rcx, [rax + al_cols]    ;rcx - counter of multiplications
    imul    rcx, [rax + al_rows]    ;rcx = aligned_columns * aligned_rows
    shr     rcx, 2                  ;rcx /= 4, as far as we will multiply packages of 4 floats at a time
    shufps  xmm0, xmm0, 0           ; xmm0 = (k;k;k;k)
.loop_scale:
    cmp     rcx, 0
    je      .end_loop_scale
    movups  xmm1, [rdi]             ;xmm1 - loaded next 4 floats
    mulps   xmm1, xmm0              ;multiply by (k;k;k;k)
    movups  [rdi], xmm1             ;and move back
    lea     rdi, [rdi + 16]         ;go to next 4 floats
    dec     rcx                     ;is done???
    jmp     .loop_scale

.end_loop_scale:
    ret

;;Matrix matrixAdd(Matrix a, Matrix b);
;;
; Parameters:
;   1) RDI - address of matrix a
;   2) RSI - address of matrix b
; Returns:
;   RAX - address of matrix which is sum of given matrices a and b
matrixAdd:
    mov     r8, [rdi + rows]        ;r8 = a->rows
    mov     r9, [rsi + rows]        ;r9 = b->rows
    cmp     r8, r9
    jne     .incorrect              ;check if incorrect sizes
    mov     r8, [rdi + cols]        ;r8 = a->columns
    mov     r9, [rsi + cols]        ;r9 = b->columns
    cmp     r8, r9
    jne     .incorrect              ;check if incorrect sizes

    push    rdi         ;caller-save registers
    push    rsi
    call    matrixCopy  ;rdi is already set to copy the first matrix 
    pop     rsi
    pop     rdi

    ;rax - address of copied matrix a
    mov     rsi, [rsi + data]       ;set source (that is second matrix)
    mov     rdi, [rax + data]       ;set destination (that is copy of first matrix)
    mov     rcx, [rax + al_cols]    ;rcx - counter of iterations
    imul    rcx, [rax + al_rows]
    shr     rcx, 2                  ;rcx /= 4 as far as we will sum packages of 4 floats at a time
.loop_add:
    cmp     rcx, 0
    je      .end_loop_add
    movups  xmm0, [rdi]             ;load next 4 floats of 1-st matrix
    movups  xmm1, [rsi]             ;load next 4 floats of 2-d matrix
    addps   xmm0, xmm1              ;sum them up
    movups  [rdi], xmm0             ;move result back to destination
    add     rdi, 16                 ;move pointer of destination by 4 floats
    add     rsi, 16                 ;move pointer of source by 4 floats
    dec     rcx
    jmp     .loop_add
.end_loop_add:
    ret

.incorrect:
    xor     rax, rax
    ret

;;Matrix matrixTranspose(Matrix m)
; 
; Parameters:
;   1) RDI - address of matrix[N x M] to be transposed
; Returns:
;   RAX - address of matrix = m^T [M x N]
matrixTranspose:
    push    r12         ;caller-save registers
    push    r13

    mov     rdx, rdi            ;rdx - saved address
    mov     rdi, [rdx + cols]   ;rdi = number of columns(unaligned)
    mov     rsi, [rdx + rows]   ;rsi = number of rows(unaligned)
    push    rdx                 ;save rdx as caller-save register
    call    matrixNew
    pop     rdx
    
    ;rax - address of transposed matrix[M x N]
    mov     rsi, [rdx + data]       ;start of source
    mov     r10, [rdx + al_rows]    ;number of rows to be copied - N
    mov     r11, [rdx + al_cols]    ;number of columns to be copied - M
    mov     r9, [rax + data]        ;start of destination
    
    xor     rcx, rcx                ;rcx = 0 - current row number
.loop_rows:
    xor     r12, r12                ;r12 = 0 - number of already copied columns
    lea     rdi, [r9 + rcx * 4]     ;rdi - address of first cell to be copied, it will be increased by number of rows * 4
                                    ;i.e. copying is performing from the top to the bottom of current column
.loop_cols:
    movups  xmm0, [rsi]             ;load next 4 floats at a time
                                    ;xmm0 = (A:B:C:D)

    extractps [rdi], xmm0, 0        ;(A)
    lea     rdi, [rdi + r10 * 4]    ;move to next row, i.e. rdi += N

    extractps [rdi], xmm0, 1        ;(B)
    lea     rdi, [rdi + r10 * 4]    ;move to next row, i.e. rdi += N

    extractps [rdi], xmm0, 2        ;(C)
    lea     rdi, [rdi + r10 * 4]    ;move to next row, i.e. rdi += N

    extractps [rdi], xmm0, 3        ;(D)
    lea     rdi, [rdi + r10 * 4]    ;move to next row, i.e. rdi += N

    add     rsi, 16     ;move position in source to next 4 floats
    add     r12, 4      ;column += 4
    cmp     r12, r11    ;proceed the whole line???
    jne      .loop_cols

    inc     rcx         ;go to next row
    cmp     rcx, r10    ;proceed all lines???
    jne      .loop_rows

    pop     r13
    pop     r12
    ret

;;Matrix matrixMul(Matrix a, Matrix b);
;;
; Parameters:
;   1) RDI - adrress of matrix a[N x M] 
;   2) RSI - adrress of matrix b[M x K]
; Returns:
;   Address of matrix c[N x K] = a * b
matrixMul:
    mov     r8, [rdi + cols] ;r8 = M1
    mov     r9, [rsi + rows] ;r9 = M2
    cmp     r8, r9
    jne     .incorrect       ;M1 != M2 => cannot be multiplied

    ;transposition of 2d matrix
    push    rdi              ;save rdi (a)
    mov     rdi, rsi         ;1-st arg (b)
    call    matrixTranspose
    mov     rsi, rax         ;rsi = b^T[K x M]
    pop     rdi              ;restore rdi

    ;create room for result
    push    rdi              ;save addresses
    push    rsi    
    mov     rdi, [rdi + rows] ;N
    mov     rsi, [rsi + rows] ;K
    call    matrixNew
    mov     rdx, rax    ;rdx - result matrix [N x K]
    pop     rsi         ;restore b^T[K x M]
    pop     rdi         ;restore a[N x M]

    mov     r8, [rdi + al_rows]  ;N
    mov     r9, [rdi + al_cols]  ;M
    mov     r10, [rsi + al_rows] ;K 

    mov     rdi, [rdi + data]   ;rdi - start of a.data[]
    mov     rsi, [rsi + data]   ;rsi - start of b^T.data[]
    
    mov     rax, rdx            ;rax - result matrix[N x K] address
    mov     rdx, [rax + data]   ;rdx - pointer to current cell in result

    push    r12     ;callee-save registers
    push    r13
    push    r14

    xor     r11, r11 ;i - row: a[i][...]
.loop_for_i:
    xor     r13, r13 ;j - column in b[...][j] (and row in b^T[j][...])

.loop_for_j:
    mov     r12, r11 ;r12 = i
    imul    r12, r9  ;r12 = i * M
    imul    r12, 4   ;r12 = i * M * sizeof(float)
    add     r12, rdi ;r12 = rdi + i * M * sizeof(float)
                     ;r12 - start of i-th row of 'a'

    mov     r14, r13 ;r14 = j
    imul    r14, r9  ;r14 = j * M
    imul    r14, 4   ;r14 = j * M * sizeof(float)
    add     r14, rsi ;r14 = rsi + j * M * sizeof(float)
                     ;r14 - start of j-th row in b^T (i.e. j-th column in b)

    xor     rcx, rcx    ;rcx - how much cells in one line are copied
    xorps   xmm0, xmm0  ;xmm0 - holds result of c[i][j]
.loop_for_k:
    movups  xmm1, [r12] ;A : B : C : D
    movups  xmm2, [r14] ;E : F : G : H
    mulps   xmm1, xmm2  ;A*E : B*F : C*G : D*H
    haddps  xmm1, xmm1  ;A*E+B*F : C*G+D*H : A*E+B*F : C*G+D*H 
    haddps  xmm1, xmm1  ;A*E+B*F+C*G+D*H : ... : ... : ...
    addss   xmm0, xmm1  ;add to result

    add     r12, 16     ;move to next 4 floats in i-th row of a[i][...]
    add     r14, 16     ;move to next 4 floats in j-th row of b^T[j][...] (i.e. j-th column of b[...][j])
    add     rcx, 4      ;+4 columns have been proceed
    cmp     rcx, r9     ;proceed the whole line???
    jne     .loop_for_k 

    movss   [rdx], xmm0
    add     rdx, 4      ;move to next result cell in the resulting matrix: c[i][j] -> c[i][j+1] or c[i][j] -> c[i+1][j] no matter

    inc     r13         ;go to next row in b^T[j][...] (i.e. column in b[...][j])
    cmp     r13, r10
    jne     .loop_for_j ;proceed the whole i-th row???

    inc     r11         ;go to next row
    cmp     r11, r8
    jne     .loop_for_i ;proceed all rows???

;end of multiplying
    pop     r14
    pop     r13
    pop     r12
    
    ;RAX - already holds adress of resulting matrix
    ret

.incorrect:
    xor     rax, rax    
    ret
