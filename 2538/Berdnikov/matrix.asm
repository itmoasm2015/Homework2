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

; Matrix - array of 32 bit numbers:
;     matrix = array{N, M,
;          row(0)  : a[0][0]   , ..., a[0][M-1],
;          ...
;          row(N-1): a[N-1][0] , ..., a[N-1][M-1] }
;     where N       - number of rows
;           M       - number of columns rounded to the nearest 4-divisable
;                       number for using SSE
;           a[x][y] - cell of the matrix with 'row = x' and 'column = y'
;
; So:
;     array[0] = N
;     array[1] = M
;     array[2+x*M+y] = matrix[x][y] (where x=0..N-1 and y=0..M-1)


; =============== MACROSES ===============

; Round number to the nearest 4-divisable number,
; which is equal or grater than given number
%macro ROUND_4 1
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

%macro PUSHALL 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

%macro POPALL 1-*
    %rep %0
        %rotate -1
        pop %1
    %endrep
%endmacro

;; Macros for code simplifying purposes.
;; Get matrix element by row and column.
;; rdi, rsi and rdx must be saved by caller.
;;
;; input:
;;     %1 - address of the matrix
;;     %2 - row
;;     %3 - column
;; output:
;;     xmm0 - matrix[row][column]
;;
;; It's just a matrixGet function without comments and definitions.
%macro GET_ELEM 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    mov eax, [rdi+4]
    ROUND_4 rax
    PUSHALL rdx
    mul rsi
    POPALL rdx
    add rax, rdx
    add rax, 2
    movss xmm0, [rdi+4*rax]
%endmacro

;; Macros for code simplifying purposes.
;; Set matrix element by row and column.
;; rdi, rsi and rdx must be saved by caller.
;;
;; input:
;;     %1 - address of the matrix
;;     %2 - row
;;     %3 - column
;;     xmm0 - value
;;
;; It's just a matrixSet function without comments and definitions.
%macro SET_ELEM 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    mov eax, [rdi+4]
    ROUND_4 rax
    PUSHALL rdx
    mul rsi
    POPALL rdx
    add rax, rdx
    add rax, 2
    movss [rdi+4*rax], xmm0
%endmacro

; ================== END MACROSES ===============


;; Allocate memory for new matrix and fill it with zeros.
;; Return address of the matrix or 0 if out of memory.
;;
;; input:
;;     rdi - number of rows
;;     rsi - number of columns
;; output:
;;     rax - address of the matrix
%define rows rdi
%define cols rsi
%define cnt rax
%define matrix rax
matrixNew:
    mov rax, cols
    ROUND_4 rax
    mul rows        ; cnt = rax = rows*cols
    add cnt, 2
    ; now 'cnt' contains number cells for allocating

    ; allocate 'cnt' cells with size 4
    PUSHALL rows, cols
    mov rdi, cnt    ; number of cells 
    mov rsi, 4      ; cell size
    call calloc
    POPALL rows, cols

    mov [matrix], rows    ; array[0] = rows
    mov [matrix+4], cols  ; array[1] = cols

    ret

;; Destroy matrix previously allocated by matrixNew(), matrixScale(),
;; matrixAdd() or matrixMul()
;;
;; input:
;;     rdi - address of the matrix
matrixDelete:
    call free
    ret

;; Get number of rows in a matrix.
;;
;; input:
;;     rdi - address of the matrix
;; output:
;;     rax - number of rows
%define matrix rdi
%define rows eax
matrixGetRows:
    mov rows, [matrix]
    ret ; return rows

;; Get number of columns in a matrix.
;;
;; input:
;;     rdi - address of the matrix
;; output:
;;     rax - number of columns
%define matrix rdi
%define cols eax
matrixGetCols:
    mov cols, [matrix+4]
    ret ; return cols

;; Get matrix element by row and column.
;;
;; input:
;;     rdi - address of the matrix
;;     rsi - row
;;     rdx - column
;; output:
;;     xmm0 - matrix[row][column]
%define matrix rdi
%define row rsi
%define col rdx
%define size 4
%define cols rax
%define addr rax
%define value xmm0
matrixGet:
    ; matrix[row][col] = array[2 + row * cols + col]
    mov eax, [matrix+4]
    ROUND_4 cols   ; addr = cols
    PUSHALL rdx
    mul row        ; addr *= row, so addr == row * cols
    POPALL rdx
    add addr, col  ; addr += col, so addr == row * cols + col
    add addr, 2    ; addr += 2,   so addr == 2 + row * cols + col

    movss value, [matrix+size*addr] ; xmm0 = matrix[row][col]
    ret

;; Set matrix element by row and column
;;
;; input:
;;     rdi  - address of the matrix
;;     rsi  - row
;;     rdx  - column
;;     xmm0 - value
%define matrix rdi
%define row rsi
%define col rdx
%define size 4
%define cols rax
%define addr rax
%define value xmm0
matrixSet:
    ; matrix[row][col] = array[2 + row * cols + col]
    mov eax, [matrix+4]
    ROUND_4 cols   ; addr = cols
    PUSHALL rdx
    mul row        ; addr *= row, so addr == row * cols
    POPALL rdx
    add addr, col  ; addr += col, so addr == row * cols + col
    add addr, 2    ; addr += 2,   so addr == 2 + row * cols + col

    movss [matrix+size*addr], value ; matrix[row][col] = xmm0
    ret

;; Multiply matrix by a scalar.
;; Return resulted matrix.
;;
;; input:
;;     rdi  - address of the input matrix A
;;     xmm0 - scalar k
;; output:
;;     rax  - address of the resulted matrix C
%define matrixA rdi
%define vec4 xmm5
%define rows r8
%define cols r9
%define matrixC r10
matrixScale:
    movss vec4, xmm0      ; vec4 == 0:0:0:k
    movsldup vec4, vec4   ; vec4 == 0:0:k:k
    unpcklps vec4, vec4   ; vec4 == k:k:k:k

    mov eax, [matrixA]
    mov rows, rax         ; get rows
    mov eax, [matrixA+4]
    mov cols, rax         ; get cols

    ; initialise matrix C
    PUSHALL rows, cols, matrixA
    mov rdi, rows         ; parameter1: rows
    mov rsi, cols         ; parameter2: cols
    call matrixNew
    mov matrixC, rax      ; matrixC contains adress of initialised matrix
    POPALL rows, cols, matrixA

    ROUND_4 cols
    mov rax, cols
    mul rows
    mov rcx, rax ; now rcx == rows * cols

    ; multiply each element of the matrix by k
    ; 4 element at one iteration using SSE
    %define matrixA rdi+8  ; now matrixA points at A[0][0]
    %define matrixC r10+8  ; now matrixC points at C[0][0]
    %define size 4
    .loop:
        sub rcx, 4
        movups xmm1, [matrixA+rcx*size]  ; xmm1 contains 4 elements of matrix A
        mulps xmm1, vec4                 ; mul each element by k
        movups [matrixC+rcx*size], xmm1  ; put result in 4 elements of matrix C
        cmp rcx, 0
    jnz .loop

    mov rax, r10 ; return matrix C
    ret

;; Add two matrices.
;; Return new matrix or 0 if the sizes don't match.
;;
;; input:
;;     rdi - address of the input matrix A
;;     rsi - address of the input matrix B
;; output:
;;     rax - address of the resulted matrix C
%define matrixA rdi
%define matrixB rsi
%define matrixC r10
%define rowsA_addr matrixA
%define rowsB_addr matrixB
%define colsA_addr matrixA+4
%define colsB_addr matrixB+4
%define rows r8
%define cols r9
%define tmpRows rdx
%define tmpCols rdx
matrixAdd:
    mov eax, [rowsA_addr]
    mov rows, rax           ; get rows of matrix A
    mov eax, [rowsB_addr]
    mov tmpRows, rax        ; get rows of matrix B
    cmp tmpRows, rows
    jne .return0            ; if rows A and rows B are not equal, return 0

    mov eax, [colsA_addr]
    mov cols, rax           ; get cols of matrix A
    mov eax, [colsB_addr]
    mov tmpCols, rax        ; get cols of matrix B
    cmp tmpCols, cols
    jne .return0            ; if cols A and cols B are not equal, return 0

    PUSHALL matrixA, matrixB, rows, cols
    mov rdi, rows           ; parameter1: rows
    mov rsi, cols           ; parameter2: cols
    call matrixNew
    mov matrixC, rax        ; matrixC contains adress of initialised matrix
    POPALL matrixA, matrixB, rows, cols

    ROUND_4 cols

    mov rax, cols
    mul rows
    mov rcx, rax            ; now rcx == rows * cols

    ; sum each pair of elements of matrixA and of matrixB
    ; 4 element at one iteration using SSE
    %define matrixA rdi+8       ; now matrixA points to A[0][0]
    %define matrixB rsi+8       ; now matrixB points to B[0][0]
    %define matrixC r10+8       ; now matrixC points at C[0][0]
    %define size 4
    .loop:
        sub rcx, 4
        movups xmm0, [matrixA+rcx*4]  ; xmm0 contains 4 elements of matrix A
        movups xmm1, [matrixB+rcx*4]  ; xmm1 contains 4 elements of matrix B
        addps xmm0, xmm1              ; sum each pair of elements
        movups [matrixC+rcx*4], xmm0  ; put result in 4 elements of matrix C
        cmp rcx, 0
    jne .loop

    mov rax, r10 ; return matrix C
    ret

.return0:
    mov rax, 0
    ret

;; Multiply two matrices.
;; Return new matrix or 0 if the sizes don't match.
;;
;; input:
;;     rdi - address of the input matrix A
;;     rsi - address of the input matrix B
;; output:
;;     rax - address of the resulted matrix C
%define matrixA rdi
%define matrixB rsi
%define matrixC r9
%define rowsA_addr matrixA
%define rowsB_addr matrixB
%define colsA_addr matrixA+4
%define colsB_addr matrixB+4
%define rows r10
%define cols r11
%define tmpRows rdx
%define tmpCols rdx
matrixMul:
    mov eax, [colsA_addr]
    mov cols, rax

    mov eax, [rowsB_addr]
    mov tmpRows, rax
    cmp tmpRows, cols
    jne .return0

    mov eax, [rowsA_addr]
    mov rows, rax

    mov eax, [colsB_addr]
    mov cols, rax

    PUSHALL rows, cols, matrixA, matrixB
    mov rdi, rows
    mov rsi, cols
    call matrixNew
    mov matrixC, rax
    POPALL rows, cols, matrixA, matrixB

    PUSHALL r12, r13, r14, r15

    mov eax, [rowsB_addr]
    mov r12, rax

    %define rowsB r12
    %define I r13
    %define J r14
    %define K r15
    %define sum xmm2
    %define get_result xmm0
    %define tmp xmm1

    mov I, rows
    ; for I = rowsC-1 to 0
    .loopRows:
        dec I
        mov J, cols
        ; for J = colsC-1 to 0
        .loopCols:
            dec J
            xorps sum, sum ; sum = 0
            xor K, K       ; K = 0
            ; for K = 0 to rowsB-1
            .loop:
                ; get A[I][K]
                PUSHALL rdi, rsi
                GET_ELEM matrixA, I, K
                movss tmp, get_result
                POPALL rdi, rsi
                ; now tmp == A[I][K]

                ; get B[K][J]
                PUSHALL rdi, rsi
                GET_ELEM matrixB, K, J
                POPALL rdi, rsi
                ; now get_result == B[K][J]

                mulss tmp, get_result ; tmp *= get_result
                addss sum, tmp        ; sum += tmp

                inc K
                cmp K, rowsB
            jne .loop

            ; C[I][J] = sum
            PUSHALL rdi, rsi
            movss xmm0, sum
            SET_ELEM matrixC, I, J
            POPALL rdi, rsi

            cmp J, 0
        jnz .loopCols

        cmp I, 0
    jnz .loopRows

    POPALL r12, r13, r14, r15

    mov rax, matrixC
    ret

.return0:
    mov rax, 0
    ret
