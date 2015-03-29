extern calloc
extern free
extern printf

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

section .data
FORMAT:     db      "%u %u", 10, 0

section .bss

section .text

;1) matrix structure
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
; Uses:
;   R8 - Matrix;
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
; Uses:
;   R8 - Matrix;
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
; Uses:
;   R8 - Matrix;
matrixGetRows:
    mov     rax, [rdi + rows]
    ret

;;unsigned int matrixGetCols(Matrix matrix);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   RAX - unsigned int = number of cols (not aligned)
; Uses:
;   R8 - Matrix;
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
    mov     [rsi], xmm0
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

    cld
    mov     rcx, [rax + al_rows]
    imul    rcx, [rax + al_cols]
    imul    rcx, 4

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
    push    rdi
    push    xmm0
    call    matrixCopy
    pop     xmm0
    pop     rdi

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
    movups  [rdi], xmm0
    dec     rcx
    lea     rdi, [rdi + 16]
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
    mov     r9, [rdi + cols]
    cmp     r8, r9
    jne     .incorrect

    push    rdi
    push    rsi
    call    matrixCopy
    pop     rsi
    pop     rdi
    ;;rax = copied matrix a
    
    mov     rdi, [rax + data]
    mov     rcx, [rax + al_cols]
    mov     rcx, [rax + al_rows]
    shr     rcx, 2
.loop_add:
    cmp     rcx, 0
    je      .end_loop_add
    movups  xmm0, [rdi]
    addps   xmm0, [rsi]
    movups  [rdi], xmm0
    dec     rcx
    lea     rdi, [rdi + 16]
    lea     rsi, [rsi + 16]
    jmp     .loop_add
.end_loop_add:
    ret

.incorrect:
    xor     rax, rax
    ret

;;Matrix matrixMul(Matrix a, Matrix b);
;;
; Parameters:
;   1) RDI - matrix address 
; Returns:
;   Nothing(void)
; Uses:
;   R8 - Matrix;
matrixMul:

    ret
