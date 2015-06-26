section .text

extern calloc, free
extern printf

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul

;; CONSTANTS

SZ      equ 4
COLS    equ 4
DATA    equ 8

;; MACRO

%macro align_to_four 1
        sub %1, 1  ; if %1 is multiply of SZ
        and %1, ~3 ; zero last two bits
        add %1, 4
%endmacro

%macro if 4
    cmp %1, %3
    j%+2 %4
%endmacro

%macro mpush 1-*
    %rep %0
        push %1
		%rotate 1
    %endrep
%endmacro

%macro mpop 1-*
    %rep %0
        %rotate -1
    	pop %1
    %endrep
%endmacro

%macro call_calloc 2
    mpush rdi, rsi
        mov rdi, %1
        mov rsi, %2
        call calloc
    mpop rdi, rsi
%endmacro

;; MAIN FUNCTIONS

; matrixNew(unsigned int rows, unsigned int cols)
; Input:
;   rdi - rows
;   rsi - cols
; Output:
;   rax - matrix address or null if bad parameters
; Complexity: O(1)
matrixNew:
    mpush rcx, rbx
    ; check input parameters that each one > 0
    if rdi, le, 0, .bad_input
    if rsi, le, 0, .bad_input

    ; count how many bytes need to store matrix

    mov rax, rsi            ; rax = cols
    align_to_four rax       ; rax = cols - cols % 4 + 4 -> rax % 4 == 0
    mul rdi                 ; rax *= rows
    add rax, 2              ; +2 bytes for storing rows, cols values

    call_calloc rax, SZ     ; allocate memory for new matrix [rdi][rsi]

    mov [rax], edi          ; save rows
    mov [rax + COLS], esi   ; save cols

    mpop rcx, rbx
    ret
.bad_input:
    mov rax, 0
    mpop rcx
    ret

; matrixDelete(Matrix matrix)
; Input:
;   rdi - matrix address
; Complexity: O(1)
matrixDelete:
    ;if rdi, ne, 0, .success
    ;ret
.success:
    call free
    ret

; matrixGetRows(Matrix matrix)
; Input:
;   rdi - matrix address
; Output:
;   rax - rows
; Complexity: O(1)
matrixGetRows:
    mov eax, [rdi]
    ret

; matrixGetCols(Matrix matrix)
; Input:
;   rdi - matrix address
; Output:
;   rax - cols
; Complexity: O(1)
matrixGetCols:
    mov eax, [rdi + COLS]
    ret

; matrixGet(Matrix matrix, unsigned int row, unsigned int col)
; Input:
;   rdi - matrix address
;   rsi - row
;   rdx - col
; Output:
;   xmm0 - matrix[row][col]
; Complexity: O(1)
matrixGet:
    call matrixGetCols  ; rax = cols
    align_to_four rax   ; rax = cols - cols % 4 + 4

    mpush rdx
        mul rsi         ; save rdx, rax *= row
    mpop rdx

    add rax, rdx        ; rax += col
    movss xmm0, [rdi + SZ * (2 + rax)]
    ret

; matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
; Input:
;   rdi - matrix address
;   rsi - row
;   rdx - col
;   xmm0 - value
; Complexity: O(1)
matrixSet:
    call matrixGetCols  ; rax = cols
    align_to_four rax   ; rax = cols - cols % 4 + 4

    push rdx
        mul rsi         ; save rdx, rax *= row
    pop rdx

    add rax, rdx        ; rax += col
    movss [rdi + SZ * (2 + rax)], xmm0
    ret

; matrixScale(Matrix matrix, float k)
; Input:
;   rdi - matrix address
;   xmmo - k
; Output:
;   rax - address of scaled matrix
; Complexity: O(rows*cols)
matrixScale:
    mov r10, rdi             ; save matrix address

    movss xmm5, xmm0        ; xmm5 = 0:0:0:k
    movsldup xmm5, xmm5     ; xmm5 = 0:0:k:k
    unpcklps xmm5, xmm5     ; xmm5 = k:k:k:k

    mpush r10
    call matrixGetCols      ; rax = cols
    mpop r10

    mov rcx, rax            ; rcx = cols
    mov rsi, rax            ; rsi = cols, for matrixNew
    align_to_four rcx

    mpush r10, rsi
    call matrixGetRows      ; rax = rows
    mpop r10, rsi

    mov rdi, rax            ; rsi = rows, for matrixNew
    mul rcx                 ; rax *= cols
    mov rcx, rax            ; rcx = rows * cols

    mpush r10, rcx
    call matrixNew          ; rax = address of new matrix [rdi]x[rsi]
    mpop r10, rcx

.loop:
    sub rcx, 4

    movups xmm1, [(r10+DATA) + rcx * SZ]
    mulps xmm1, xmm5
    movups [(rax+DATA) + rcx * SZ], xmm1

    if rcx, ne, 0, .loop
.finish:
    ret

; Return rows*cols production for given matrix
; Input:
;   %1 - matrix address
; Output:
;   rax - matrix.rows * matrix.cols
; Complexity: O(1)
%macro get_rowsxcols 1
    mpush rcx, rdx, rdi

    mov rdi, %1

    call matrixGetCols
    align_to_four rax
    mov rcx, rax            ; rcx = cols

    call matrixGetRows
    mul rcx                 ; rax = rows * cols

    mpop rcx, rdx, rdi
%endmacro

%macro is_equal_rows 2
    mpush rax, r8, r9, rcx, rdx, rdi

    mov rdi, %1
    call matrixGetRows
    mov r8, rax
    mov rdi, %2
    call matrixGetRows
    mov r9, rax

    cmp r8, r9
    mpop rax, r8, r9, rcx, rdx, rdi
%endmacro

%macro is_equal_cols 2
    mpush rax, r8, r9, rcx, rdx, rdi

    mov rdi, %1
    call matrixGetCols
    mov r8, rax
    mov rdi, %2
    call matrixGetCols
    mov r9, rax

    cmp r8, r9
    mpop rax, r8, r9, rcx, rdx, rdi
%endmacro

; matrixAdd(Matrix a, Matrix b);
; Input:
;   rdi - matrix a address
;   rsi - matrix b address
; Output:
;   rax - address of matrix of the sum a and b
; Complexity: O(rows*cols)
matrixAdd:
    mov r10, rdi
    mov r11, rsi

    mpush r10, r11
        is_equal_cols r10, r11  ; if incompatible cols
    mpop r10, r11
    jne .bad_input

    mpush r10, r11
        is_equal_rows r10, r11  ; if incompatible rows
    mpop r10, r11
    jne .bad_input

    mov rdi, r10            ; rax = first matrix
    mpush r10, r11
        call matrixGetRows
    mpop r10, r11
    mov r12, rax            ; r12 = rows

    mov rdi, r10            ; rax = first matrix
    mpush r10, r11, r12
        call matrixGetCols
    mpop r10, r11, r12
    mov rsi, rax            ; rsi = cols
    mov rdi, r12            ; rdi = rows

    mpush r10, r11, rsi, rdi
        get_rowsxcols r10       ; rax = rows * cols
    mpop r10, r11, rsi, rdi

    mov rcx, rax

    mpush rcx, r10, r11
        call matrixNew          ; rax = address of new matrix[rdi][rsi]
    mpop rcx, r10, r11
.loop:
    sub rcx, 4

    mpush rcx
        movups xmm0, [(r10+DATA) + rcx * SZ]
        movups xmm1, [(r11+DATA) + rcx * SZ]
        addps xmm0, xmm1
        movups [(rax+DATA) + rcx * SZ], xmm0
    mpop rcx

    if rcx, ne, 0, .loop
.finish:
    ret
.bad_input:
    mov rax, 0
    ret

; matrixTranspose(Matrix matrix);
; Input:
;   rdi - matrix address
; Output:
;   rax - address of transposed matrix
; Complexity: O(rows*cols)
matrixTranspose:
        mpush r12, r13, r14, r15, rbx

    ;mov r15, rdi

    mpush rdi
        call matrixGetRows
        mov r8, rax         ; r8 = rows
        mov r10, r8         ; r10 = rows

        call matrixGetCols
        mov r9, rax         ; r9 = cols
        mov r13, r9         ; r13 = cols

        mov rdi, r9        ; *** rdi = cols
        mov rsi, r8         ; *** rsi = rows

        mpush r8, r9, r10, r13
            call matrixNew  ; new matrix[cols][rows]
        mpop r8, r9, r13, r10

        mov r14, rax
    mpop rdi

    mov rax, r8
    align_to_four rax
    mov rcx, rax            ; rcx = ceil(rows)

    mov rax, r9
    align_to_four rax
    mov rdx, rax            ; rdx = ceil(cols)

    mov r8, 0
.outer_loop:
    mov r9, 0
    .inner_loop:
        mpush rcx, rdx, r8, r9
            mov r11, rdx                    ; calc index in first matrix
            mpush rdx, rcx
                imul r11, r8
                add r11, r9
            mpop rdx, rcx

            mov r12, rcx                    ; calc index in second matrix
            mpush rdx, rcx
                imul r12, r9
                add r12, r8
            mpop rdx, rcx
        mpop rcx, rdx, r8, r9

        mov eax, [rdi+DATA + r11*SZ]        ; swap items
        mov [r14+DATA + r12*SZ], eax

        add r9, 1
        if r9, l, r13, .inner_loop     ; if r9 == cols -> .outer_loop

    add r8, 1
    if r8, l, r10, .outer_loop    ; if r8 == rows -> finish
.finish:
    mov rax, r14
    mpop r12, r13, r14, r15, rbx
    ret

; Multiply two matrixes and return result of this multiplying
; Input:
;   rdi - address of the first matrix A
;   rsi - address of the first matrix B
; Output:
;   rax - address of the new matrix C = A * B
;   (rax = 0 if column count of A is not equal to row count of B)
; Complexity: O(A.rows * A.cols * B.cols)
matrixMul:
    ; rdi = A.values
    ; rsi = B.values
    call matrixGetCols
    mov r10, rax        ; r10 = A.cols

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetRows
    mov rdx, rax        ; rdx = B.rows
    pop rdi             ; load rdi
    cmp rdx, r10        ; compare A.cols, B.rows
    jnz .badSizes       ; if not equal, return NULL

    call matrixGetRows
    mov r10, rax        ; r10 = A.rows = C.rows

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetCols
    mov r11, rax        ; r11 = B.cols = C.cols
    pop rdi             ; load rdi

    push r11         ; save not rounded cols
    align_to_four r11

    push r10         ;
    push r11         ;
    push rdi         ; save registers
    push rsi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = C.values
    mov r9, rax      ; r9 = C.values
    pop rsi          ;
    pop rdi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded rcx

    mov [r9], r10    ; newRows = A.rows
    mov [r9 + COLS], r11  ; newCols = B.cols

    push r13
    push r14
    push r15

    ; for each row of C
    xor r13, r13 ; r13 = 0
    .loopRows:
        ; for each col of C
        xor r14, r14 ; r14 = 0
        .loopCols:
            ; (row, col) -> row * col_cnt + col + 2
            xorps xmm2, xmm2 ; xmm2 = 0
            ; for each col of A
            xor r15, r15     ; r15 = 0
            .loopInner:
                ; get A[r13][r15]:
                push rdi
                push rsi
                mov rsi, r13
                mov rdx, r15
                call matrixGet
                movss xmm1, xmm0 ; xmm1 = A[r13][r15]
                pop rsi
                pop rdi

                ; get B[r15][r14]:
                push rdi
                push rsi
                mov rdi, rsi
                mov rsi, r15
                mov rdx, r14
                call matrixGet ; xmm0 = B[r15][r14]
                pop rsi
                pop rdi

                mulss xmm1, xmm0 ; xmm1 = A[r13][r15] * B[r15][r14]
                addss xmm2, xmm1 ; xmm2 += xmm1

                inc r15
                mov eax, [rsi]
                cmp r15, rax
                jnz .loopInner

            ; set sum of multiples to C[r13][r14]
            push rdi
            push rsi
            mov rdi, r9
            mov rsi, r13
            mov rdx, r14
            movss xmm0, xmm2
            call matrixSet    ; C[r13][r14] = xmm0
            pop rsi
            pop rdi

            inc r14
            mov eax, [r9 + SZ]
            cmp r14, rax
            jnz .loopCols

        inc r13
        mov eax, [r9]
        cmp r13, rax
        jnz .loopRows

    pop r15
    pop r14
    pop r13

    mov rax, r9 ; rax = C.values
    ret

.badSizes:
    mov rax, 0
    ret
