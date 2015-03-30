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

section .text

;matrix structure
    struc Matrix_t
data:       resq    1
cols:       resq    1
rows:       resq    1
al_cols:    resq    1
al_rows     resq    1
    endstruc

%macro align4 1
    add     %1, 3
    shr     %1, 2
    shl     %1, 2 
%endmacro 

;;Matrix matrixNew(unsigned int rows, unsigned int cols);
;; 
; Parameters:
;   1) RDI - unsigned int rows 
;   2) RSI - unsigned int cols
; Returns:
;   RAX - Matrix
matrixNew:
    push    rdi
    push    rsi

    mov     rdi, 1
    mov     rsi, Matrix_t_size 
    call    calloc
    mov     rcx, rax

    pop     rsi
    pop     rdi

    mov     [rcx + rows], rdi 
    mov     [rcx + cols], rsi

    align4  rdi
    align4  rsi

    mov     [rcx + al_rows], rdi
    mov     [rcx + al_cols], rsi

    push    rcx
    
    imul    rdi, rsi
    mov     rsi, 4
    call    calloc 

    pop     rcx

    mov     [rcx + data], rax

    mov     rax, rcx

    ret

;;void matrixDelete(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   Nothing(void)
matrixDelete:
    push    rdi
    mov     rdi, [rdi + data]
    call    free 
    pop     rdi
    call    free
    ret

;;unsigned int matrixGetRows(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   RAX - unsigned int = number of rows (not aligned)
matrixGetRows:
    mov     rax, [rdi + rows]
    ret

;;unsigned int matrixGetCols(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   RAX - unsigned int = number of cols (not aligned)
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
;   xmm0 - value at matrix[rsi][rdi] 
matrixGet:
    imul    rsi, [rdi + al_cols]
    add     rsi, rdx 
    imul    rsi, 4
    add     rsi, [rdi + data]
    movss   xmm0, [rsi]
    ret

;;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;;
; Parameters:
;   1) RDI - matrix address 
;   2) RSI - row number
;   3) RDX - column number
;   4) xmm0 - value to be set
; Returns:
;   Nothing(void)
matrixSet:
    imul    rsi, [rdi + al_cols]
    add     rsi, rdx
    imul    rsi, 4
    add     rsi, [rdi + data]
    movups  [rsi], xmm0
    ret

;;Matrix matrixCopy(Matrix matrix)
;;
; Parameters:
;   1) RDI - matrix address
; Returns:
;   RAX - address of new_matrix == old_matrix
matrixCopy:
    mov     rdx, rdi

    mov     rdi, [rdx + rows]
    mov     rsi, [rdx + cols]

    push    rdx
    call    matrixNew
    pop     rdx
    ;;rax = new address

    mov     rcx, [rax + al_rows]
    imul    rcx, [rax + al_cols]
    imul    rcx, 4

    cld
    mov     rdi, [rax + data]
    mov     rsi, [rdx + data]
    rep     movsd

    ret


;;Matrix matrixScale(Matrix matrix, float k);
;;
; Parameters:
;   1) RDI - matrix address 
;   2) xmm0 - float multiplier
; Returns:
;   RAX - new_matrix == k * old_matrix
matrixScale:
    sub     rsp, 16
    movups  [rsp], xmm0

    push    rdi
    call    matrixCopy
    pop     rdi

    movups  xmm0, [rsp]
    add     rsp, 16
    ;;rax == copied matrix

    mov     rdi, [rax + data]
    mov     rcx, [rax + al_cols]
    imul    rcx, [rax + al_rows]
    shr     rcx, 2
    shufps  xmm0, xmm0, 0   ; xmm0 = (k;k;k;k)
.loop_scale:
    cmp     rcx, 0
    je      .end_loop_scale
    movups  xmm1, [rdi]
    mulps   xmm1, xmm0
    movups  [rdi], xmm1
    lea     rdi, [rdi + 16]
    dec     rcx
    jmp     .loop_scale

.end_loop_scale:
    ret

;;Matrix matrixAdd(Matrix a, Matrix b);
;;
; Parameters:
;   1) RDI - address of matrix a
;   2) RSI - address of matrix b
; Returns:
;   address of matrix = a + b
matrixAdd:
    mov     r8, [rdi + rows]
    mov     r9, [rsi + rows]
    cmp     r8, r9
    jne     .incorrect
    mov     r8, [rdi + cols]
    mov     r9, [rsi + cols]
    cmp     r8, r9
    jne     .incorrect

    push    rdi
    push    rsi
    ;;rdi = matrix a
    call    matrixCopy
    pop     rsi
    pop     rdi
    ;;rax = copied matrix a
    
    mov     rsi, [rsi + data]
    mov     rdi, [rax + data]
    mov     rcx, [rax + al_cols]
    imul    rcx, [rax + al_rows]
    shr     rcx, 2
.loop_add:
    cmp     rcx, 0
    je      .end_loop_add
    movups  xmm0, [rdi]
    movups  xmm1, [rsi]
    addps   xmm0, xmm1
    movups  [rdi], xmm0
    add     rdi, 16
    add     rsi, 16
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
;   1) RDI - address of matrix to be transposed
; Returns:
;   RAX - address of matrix = m^T
matrixTranspose:
    push    r12
    push    r13

    mov     rdx, rdi
    mov     rdi, [rdx + cols]
    mov     rsi, [rdx + rows]
    push    rdx
    call    matrixNew
    pop     rdx

    mov     rsi, [rdx + data]       ;start of source
    mov     r10, [rdx + al_rows]    
    mov     r11, [rdx + al_cols]
    mov     r9, [rax + data]        ;start of destination
    
    xor     rcx, rcx    ;row number
.loop_rows:
    xor     r12, r12    ;column number
    lea     rdi, [r9 + rcx * 4]
.loop_cols:
    movups  xmm0, [rsi] ;(A:B:C:D)

    extractps [rdi], xmm0, 0 ;(A)
    lea     rdi, [rdi + r10 * 4]

    extractps [rdi], xmm0, 1 ;(B)
    lea     rdi, [rdi + r10 * 4]

    extractps [rdi], xmm0, 2 ;(C)
    lea     rdi, [rdi + r10 * 4]

    extractps [rdi], xmm0, 3 ;(D)
    lea     rdi, [rdi + r10 * 4]

    add     rsi, 16     ;move position in source
    add     r12, 4      ;column += 4
    cmp     r12, r11    ;if reach => next row
    jne      .loop_cols

    inc     rcx
    cmp     rcx, r10
    jne      .loop_rows

    pop     r13
    pop     r12
    ret

;;Matrix matrixMul(Matrix a, Matrix b);
;;
; Parameters:
;   1) RDI - matrix a [N x M] address 
;   2) RSI - matrix b [M x K] address
; Returns:
;   Address of matrix c[N x K] = a * b
matrixMul:
    mov     r8, [rdi + cols] ;r8 = M1
    mov     r9, [rsi + rows] ;r9 = M2
    cmp     r8, r9
    jne     .incorrect       ;M1 != M2 => no multiply

    ;transposition of 2d matrix
    push    rdi              ;save rdi (a)
    mov     rdi, rsi         ;1-st arg (b)
    call    matrixTranspose
    mov     rsi, rax         ;rsi = b^T [K x M]
    pop     rdi

    ;create room for result
    push    rdi
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

    mov     rax, rdx            ;rax - result matrix[N x K]
    mov     rdx, [rax + data]   ;rdx - start of c.data[]

    push    r12     ;callee-save registers
    push    r13
    push    r14

    xor     r11, r11 ;i - row: a[i][...]
.loop_for_i:
    xor     r13, r13 ;j - column in b[...][j] and row in b^T[j][...]

.loop_for_j:
    mov     r12, r11 ;r12 = i
    imul    r12, r9  ;r12 = i * M
    add     r12, rdi ;r12 += rdi
                     ;r12 - start of i-th row

    mov     r14, r13 ;r14 = j
    imul    r14, r10 ;r14 = j * K
    add     r14, rsi ;r14 = rsi + j * K
                     ;r14 - start of j-th row in b^T (and j-th column in b)

    xor     rcx, rcx    ;iterator of one line
    xorps   xmm0, xmm0  ;holds result of c[i][j]
.loop_for_k:
    movups  xmm1, [r12] ;A : B : C : D
    movups  xmm2, [r14] ;E : F : G : H
    mulps   xmm1, xmm2  ;A*E : B*F : C*G : D*H
    haddps  xmm1, xmm1  ;A*E+B*F : C*G+D*H : A*E+B*F : C*G+D*H 
    haddps  xmm1, xmm1  ;A*E+B*F+C*G+D*H : ... : ... : ...
    addss   xmm0, xmm1  ;add to result

    ;temp debug
    push    rdx
    push    rax
    movss   [rdx], xmm0
    mov     rax, [rdx]
    pop     rax
    pop     rdx

    add     r12, 16     ;move to next 4 floats in i-th row of a[i][...]
    add     r14, 16     ;move to next 4 floats in j-th column of b[...][j]
    add     rcx, 4      ;+4 columns have been proceed
    cmp     rcx, r9     ;proceed the whole line???
    jne     .loop_for_k 

    movss   [rdx], xmm0
    add     rdx, 4      ;move to next result cell: c[i][j] -> c[i][j+1] or c[i][j]->c[i+1][0] no matter

    inc     r13         ;go to next column
    cmp     r13, r10
    jne     .loop_for_j ;proceed the whole i-th row???

    inc     r11         ;go to next row
    cmp     r11, r8
    jne     .loop_for_i ;proceed all rows???

;end of multiplying
    pop     r14
    pop     r13
    pop     r12

    ;result is in rax already
    ret

.incorrect:
    xor     rax, rax    
    ret
