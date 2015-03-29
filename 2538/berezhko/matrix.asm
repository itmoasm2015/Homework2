extern calloc, free
extern printf

; Matrix is an array of 32bit numbers where first number is row count, second number is column count
; Cols rounded to the nearest multiply of 4 for using XMM vector registers (non-scalar) if it's possible
; indexes from 3 to 3+cols-1 is 1st row
;         from 3+cols to 3+2*cols-1 is 2nd row, etc.
;
; So, reg+2 in some places in the code means that first and second numbers are for the column and row count

; From matrix to array index:
; (row, col) -> row * col_cnt + col + 2

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

;; Round reg %1 to the next multiply of 4
;; This macros useful for simple getting four component vector
%macro roundToFour 1
        sub %1, 1  ; if %1 is multiply of 4
        and %1, ~3 ; zero last two bits
        add %1, 4
%endmacro

;; Allocate memory for the new matrix and fillt it with zeros
;;
;; Input:
;;      rdi - row count
;;      rsi - column count
;; Output:
;;      rax - adress of the memory block allocated by the function.
matrixNew:
    mov rax, rsi
    roundToFour rax
    mul rdi     ; rax = rdi*rsi (rows*cols)
    add rax, 2  ; rax = 2 + (rows*cols)

    ; allocating of rax numbers, size of one = 4
    push rdi
    push rsi
    mov rdi, rax    ; number count
    mov rsi, 4      ; number size
    call calloc     ; rax = 2 + (rows*cols)
    pop rsi
    pop rdi

    mov [rax], rdi      ; values[0] = rows
    mov [rax+4], rsi    ; values[1] = cols
    ret

;; Free memory that was allocated by matrixNew
;;
;; Input:
;;      rdi - adress of the matrix
matrixDelete:
    call free
    ret

;; Return matrix's row count
;;
;; Input:
;;      rdi - adress of the matrix
;; Output:
;;      rax - row count
matrixGetRows:
    ; rows = matrix.values[0] = [rdi]
    mov eax, [rdi]
    ret

;; Return matrix's column count
;;
;; Input:
;;      rdi - adress of the matrix
;; Output:
;;      rax - column count
matrixGetCols:
    ; rows = matrix.values[1] = [rdi+4]
    mov eax, [rdi+4]
    ret

;; Return element of matrix by the index of row and column
;;
;; Input:
;;      rdi - adress of the matrix
;;      rsi - number of row
;;      rdx - number of column
;; Output:
;;      xmm0 - matrix[row][column]
matrixGet:
    ; (row, col) -> row * col_cnt + col + 2
    call matrixGetCols
    roundToFour rax
    ; save rdx because of mul writes bad data in it
    push rdx
    mul rsi
    pop rdx

    ; rax = (row, col)
    add rax, rdx
    add rax, 2

    movss xmm0, [rdi+4*rax] ; xmm0 = values[rax]
    ret

;; Set element of the matrix to the value by the index of row and column
;;
;; Input:
;;      rdi - adress of the matrix
;;      rsi - number of row
;;      rdx - number of column
;;      xmm0 - value for setting
matrixSet:
    ; (row, col) -> row * col_cnt + col + 2
    call matrixGetCols ; rax = col_cnt
    roundToFour rax
    ; save rdx because of mul writes bad data in it
    push rdx
    mul rsi
    pop rdx

    ; rax = (row, col)
    add rax, rdx
    add rax, 2

    movss [rdi+4*rax], xmm0 ; values[rax] = xmm0 (value)
    ret

;; Multiply matrix by the scalar and return result of this multiplying
;;
;; Input:
;;      rdi - adress of the first matrix A
;;      xmm0 - scalar k
;; Output:
;;      rax - adress of the new matrix C = A*k
matrixScale:
    movss xmm5, xmm0      ; xmm5 = 0:0:0:k
    movsldup xmm5, xmm5   ; xmm5 = 0:0:k:k
    unpcklps xmm5, xmm5   ; xmm5 = k:k:k:k

    call matrixGetRows
    mov r10, rax        ; r10 = rows
    call matrixGetCols
    mov r11, rax        ; r11 = cols

    push r11         ; save not rounded cols
    roundToFour r11

    push r10         ;
    push r11         ; save registers
    push rdi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = newMatrix.values
    mov r9, rax      ; r9 = newMatrix.values
    pop rdi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded cols

    mov [r9], r10    ; newRows = rows
    mov [r9+4], r11  ; newCols = cols

    roundToFour r11

    ; rcx = rax = cols*rows
    mov rax, r11
    mul r10
    mov rcx, rax

    ; for each element of matrix multiply it by k
    ; (we can multiply 4 numbers at once using vector SSE)
.looptop:
    sub rcx, 4
    movups xmm1, [rdi+(rcx+2)*4] ; +2 for dimensions
    mulps xmm1, xmm5
    movups [r9+(rcx+2)*4], xmm1  ; +2 for dimensions
.overit:
    cmp rcx, 0
    jnz .looptop

    mov rax, r9 ; rax = newMatrix.values
    ret

;; Sum two matrixes and return result of this sum
;;
;; Input:
;;      rdi - adress of the first matrix A
;;      rsi - adress of the first matrix B
;; Output:
;;      rax - adress of the new matrix C = A + B
;;              (rax = 0 if sizes of A and B are not equal)
matrixAdd:
    ; rdi = A.values
    ; rsi = B.values

    call matrixGetRows
    mov r10, rax        ; r10 = A.rows

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetRows
    mov rdx, rax        ; rdx = B.rows
    pop rdi             ; load rdi
    cmp rdx, r10        ; compare A.rows, B.rows
    jnz .badSizes       ; if not equal, return NULL

    call matrixGetCols
    mov r11, rax        ; r11 = A.cols

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetCols
    mov rdx, rax        ; rdx = B.cols
    pop rdi             ; load rdi
    cmp rdx, r11        ; compare A.cols, B.cols
    jnz .badSizes       ; if not equal, return NULL

    push r11         ; save not rounded cols
    roundToFour r11

    push r10         ;
    push r11         ;
    push rdi         ; save registers
    push rsi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = newMatrix.values
    mov r9, rax      ; r9 = newMatrix.values
    pop rdi          ;
    pop rsi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded rcx

    mov [r9], r10    ; newRows = rows
    mov [r9+4], r11  ; newCols = cols

    roundToFour r11

    ; rcx = rax = cols*rows
    mov rax, r11
    mul r10
    mov rcx, rax

    ; for each element of 2 matrix sum its
    ; (we can sum 4 numbers at once using vector SSE)
.looptop:
    sub rcx, 4
    movups xmm0, [rdi+(rcx+2)*4] ; +2 for dimensions
    movups xmm1, [rsi+(rcx+2)*4] ; +2 for dimensions
    addps xmm0, xmm1
    movups [r9+(rcx+2)*4], xmm0
.overit:
    cmp rcx, 0
    jnz .looptop

    mov rax, r9 ; rax = newMatrix.values
    ret

.badSizes:
    mov rax, 0
    ret

;; Multiply two matrixes and return result of this multiplying
;;
;; Input:
;;      rdi - adress of the first matrix A
;;      rsi - adress of the first matrix B
;; Output:
;;      rax - adress of the new matrix C = A * B
;;              (rax = 0 if column count of A is not equal to row count of B)
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
    roundToFour r11

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
    mov [r9+4], r11  ; newCols = B.cols

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
            mov eax, [r9+4]
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
