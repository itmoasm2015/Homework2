section .text

extern malloc
extern free

global matrixNew
global matrixClone
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul

; Matrix matrixNew(unsigned int rows, unsigned int cols);
; allocate memory for a brand new matrix struct
;
; @param rdi - number of rows
; @param rsi - number of cols
; @return rax pointer to the matrix or null if we're out of memory
matrixNew:
        push r8
        push rdi
        push rsi

        mov r8, rdi                     ; allocate width and height such that
        call ceilToFour                 ; width % 4 == 0 and width >= cols
        mov rdi, r8                     ; height % 4 == 0 and height >= rows
        mov r8, rsi                     ; needed for convinient sse operations
        call ceilToFour
        mov rsi, r8

        mov rax, rdi
        mul rsi
        mov rdi, 4
        mul rdi
        lea rax, [rax + 16]             ; rax = (width * height * 4 + 16)
        mov rdi, rax                    ; malloc param: size = rax bytes
        call malloc                     ; sets pointer to allocated memory in eax
        pop rsi
        pop rdi
        cmp rax, 0
        je .done                        ; malloc returns null when out of memory
        mov [rax], rdi                  ; the first number in struct is number of rows
        mov [rax + 8], rsi              ; the second is number of columns
    .done:
        pop r8
        ret

; perform ceil(r8 / 4) * 4
;
; @param r8 number to be proceed
; @return r8 ceil(r8 / 4) * 4
ceilToFour:
        test r8, 3                      ; if both least bits are 0, r8 % 4 == 0 already
        jz .done                        ; r8 % 4 != 0 (condition 1)
        add r8, 4                       ; (floor((r8 + 4) / 4) * 4 == ceil(r8 / 4) * 4) if (condition 1)
        shr r8, 2                       ; floor((r8 + 4) / 4)
        shl r8, 2                       ; floor((r8 + 4) / 4) * 4
    .done:
        ret

; void matrixDelete(Matrix matrix);
; frees memory allocated for the matrix
;
; @param rdi pointer to the matrix
; @return void
matrixDelete:
        call free                       ; takes rdi as a pointer to data
        ret

; unsigned int matrixGetRows(Matrix matrix);
;
; @param rdi poiter to the matrix
; @return rax number of rows in the matrix
matrixGetRows:
        mov rax, [rdi]                  ; number of rows is the first number in the struct
        ret

; unsigned int matrixGetRows(Matrix matrix);
;
; @param rdi poiter to the matrix
; @return rax number of columns in the matrix
matrixGetCols:
        mov rax, [rdi + 8]              ; number of columns is the second number in the struct
        ret

; returns address for specified matrix, row and column
;
; corrupts r8
;
; @param rdi matrix address
; @param rsi row
; @param rdx col
; @return rax matrix[row][col]
getAddress:
        call matrixGetCols
        mov r8, rax
        call ceilToFour
        mov rax, r8                     ; rax == width
        mov r8, rdx
        mul rsi                         ; rax == width * row
        add rax, r8                     ; rax == width * row + col
        lea rax, [rax * 4 + rdi + 16]   ; rax == matrix + (width * row + col) * 4 + 16
        ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;
; corrupts r8
; corrupts rax
;
; @param rdi pointer to the matrix
; @param rsi number of a row
; @param rdx number of a column
; @return xmm0 matrix[row][col]
matrixGet:
        call getAddress
        movss xmm0, [rax]
        ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;
; @param rdi pointer to the matrix
; @param rsi number of a row
; @param rdx number of a column
; @param xmm0 value to be set
; @return void
matrixSet:
        call getAddress
        movss [rax], xmm0
        ret
