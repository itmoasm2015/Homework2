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
; allocate memory for a brand new matrix struct and fills it with zeros
; same as matrixAlloc but keep r9 and r10 intact (cdecl)
;
; @param rdi number of rows
; @param rsi number of cols
; @return rax pointer to the matrix or null if we're out of memory
matrixNew:
        push r9
        push r10
        call matrixAlloc
        pop r10
        pop r9
        ret

; allocate memory for a brand new matrix struct and fills it with zeros
;
; @param rdi number of rows
; @param rsi number of cols
; @return rax pointer to the matrix or null if we're out of memory
; @return r9 real width (capacity)
; @return r10 real height (capacity)
matrixAlloc:
        push r8
        push rdi
        push rsi

        ; align sizes
        mov r8, rdi                     ; allocate width and height such that
        call alignToFour                ; width % 16 == 0 and width >= cols
        mov rdi, r8                     ; height % 16 == 0 and height >= rows
        mov r9, r8                      ; return value
        mov r8, rsi                     ; needed for convinient sse operations
        call alignToFour
        mov rsi, r8
        mov r10, r8                     ; return value

        ; allocate memory
        mov rax, rdi
        mul rsi
        mov rdi, 4
        mul rdi
        lea rax, [rax + 16]             ; rax = (width * height * 4 + 16)
        push rax                        ; size of data in bytes
        mov rdi, rax                    ; malloc param: size = rax bytes
        push r9
        push r10
        call malloc                     ; sets pointer to allocated memory in eax
        pop r10
        pop r9
        pop r11                         ; size of data in bytes
        pop rsi
        pop rdi
        cmp rax, 0
        je .fail                        ; malloc returns null when out of memory

        ; init brand new matrix
        .loop:                          ; init with zeros, needed for see operations
                mov qword [rax + r11], 0
                sub r11, 8
                jnz .loop
        mov [rax], rdi                  ; the first number in struct is number of rows
        mov [rax + 8], rsi              ; the second is number of columns
        .fail:
        pop r8
        ret

; perform ceil(r8 / 4) * 4
;
; @param r8 number to be proceed
; @return r8 ceil(r8 / 4) * 4
alignToFour:
        test r8, 3                      ; if two least bits are 0, r8 % 4 == 0 already
        jz .done                        ; r8 % 4 != 0
        add r8, 4                       ; ceil: (r8 + 4) / 4 == r8 / 4 + 1
        and r8, 0xfffffffffffffffc      ; flush least two bits, now r8 % 4 == 0
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
        call alignToFour
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
        push r8

        call getAddress
        movss xmm0, [rax]

        pop r8
        ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;
; @param rdi pointer to the matrix
; @param rsi number of a row
; @param rdx number of a column
; @param xmm0 value to be set
; @return void
matrixSet:
        push r8

        call getAddress
        movss [rax], xmm0

        pop r8
        ret

; returns size of cells + 8
; actually matrix + rax is the last element in the matrix
;
; corrupts rdi
; corrupts rdx
;
; @param rdi number of rows
; @param rsi number of cols
; @return rax size of cells + 8
getAlmostSize:
        push r8
        mov r8, rdi
        call alignToFour
        mov rdi, r8
        mov r8, rsi
        call alignToFour
        mov rax, r8
        mul rdi
        lea rax, [rax * 4 + 8]
        pop r8
        ret

; copies specified matrix
;
; corrupts r8
; corrupts rdi
; corrupts rdx
;
; @param rdi pointer to the source matrix
; @return rax pointer to the copy
; @return rdx almost size of the matrix
matrixCopy:
        push rsi
        push rdi

        ; get source size and create similar
        call matrixGetRows
        mov r8, rax
        call matrixGetCols
        mov rsi, rax
        mov rdi, r8
        call matrixNew

        ; copy data
        mov r8, rax                         ; let r8 be pointer to the copy for awhile
        call getAlmostSize
        pop rdi                             ; rdi + rax is now the last element of the source
        push rax
        .loop:                              ; r8  + rax is now the last element of the copy
                mov rdx, [rdi + rax]
                mov [r8 + rax], rdx
                sub rax, 8
                jnz .loop
        mov rax, r8
        pop rdx

        pop rsi
        ret

; Matrix matrixScale(Matrix matrix, float k);
;
; corrupts rdx
;
; @param rdi pointer to the source matrix
; @param xmm0 scalar factor
; @return rax pointer to the result matrix
matrixScale:
        push r8
        push rdi

        call matrixCopy
        lea rdx, [rdx + rax + 8]            ; end of data
        push rax
        add rax, 16                         ; start of data
        shufps xmm0, xmm0, 0                ; xmm0 = (k:k:k:k)
        .loop:
                movups xmm1, [rax]
                mulps xmm1, xmm0
                movups [rax], xmm1
                add rax, 16
                cmp rdx, rax
                jne .loop
        pop rax

        pop rdi
        pop r8
        xorps xmm1, xmm1
        ret

; Matrix matrixAdd(Matrix a, Matrix b);
;
; corrupts rdx
;
; @param rdi pointer to the matrix a
; @param rsi pointer to the matrix b
; @return rax pointer to the result matrix
matrixAdd:
        push r8

        ; check if sizes are equal
        call matrixGetRows
        mov r8, rax
        xchg rdi, rsi
        call matrixGetRows
        mov rdx, rax
        cmp r8, rdx
        jne .fail                           ; make sure sizes of matrices are equal
        call matrixGetCols
        mov r8, rax
        xchg rdi, rsi                       ; after two swaps rdi and rsi are set as in @param
        call matrixGetCols
        mov rdx, rax
        cmp r8, rdx
        jne .fail
        push rsi

        ; create a new copy and write sum into it pack by pack
        call matrixCopy
        push rax
        add rax, 16                         ; start of data
        add rsi, 16
        sub rdx, 8                          ; size of data
        .loop:
                movups xmm0, [rax + rdx - 16]
                addps xmm0, [rsi + rdx - 16]
                movups [rax + rdx - 16], xmm0
                sub rdx, 16
                jnz .loop
        pop rax
        pop rsi
        pop r8
        ret
    .fail:
        xor rax, rax

        pop r8
        ret

; transposes given matrix
; needed for matrixMul:
;        after transposition we can easily grab next four float using single address
;
; corrupts r8
; corrupts r9
; corrupts r10
; corrupts rbx
; corrupts rcx
; corrupts rdx
;
; @param rdi source matrix (n * m)
; @param rax transposed matrix
matrixTranspose:
        ; create a new matrix to store the result
        push rsi
        mov r9, rdi                         ; A = r9: source matrix
        call matrixGetRows
        mov r8, rax
        call matrixGetCols
        mov rsi, r8
        mov rdi, rax
        push r9
        call matrixAlloc                    ; create a new matrix, width and height are swapped
        mov rsi, r9                         ; m = rsi: real width of transposed in words
        mov rdi, r10                        ; n = rdi: real height of transposed in words
        pop r9

        ; copy data in right order
        mov r8, rax                         ; B = r8: result matrix
        mov rax, rsi
        mul rdi                             ; n * m = rax: real size of data in dwords
        xor r10, r10                        ; cnt = r10: counter
        xor rdx, rdx                        ; j = rdx: offset in B (dwords)
        xor rcx, rcx                        ; i = rcx: offset in A (dwords)
        .loop1:                                     ; We'll iterate through A. In each cycle j points to a new row, but same column (j += n).
                mov ebx, dword [r9 + rcx * 4 + 16]  ; If we're out out rows (j >= n * m), use next column (j = ++cnt)
                mov dword [r8 + rdx * 4 + 16], ebx  ; B[j] = A[i]
                add rdx, rdi                        ; j += n
                cmp rdx, rax
                jl .next                            ; if (j >= n * m) {
                inc r10                             ;     cnt++;
                mov rdx, r10                        ;     j = cnt;
            .next:                                  ; }
                inc rcx
                cmp rcx, rax
                jne .loop1
        mov rdi, r9
        pop rsi
        mov rax, r8
        ret

; Matrix matrixMul(Matrix a, Matrix b);
;
; @param rdi pointer to the matrix a
; @param rsi pointer to the matrix b
; @return rax pointer to the result
matrixMul:
        ; check if sizes are suitable
        push r8
        call matrixGetCols
        mov r8, rax                         ; a: p*q
        xchg rdi, rsi
        call matrixGetRows
        mov rdx, rax                        ; b: n*m
        xchg rdi, rsi
        cmp r8, rdx
        jne .fail                           ; make sure q == n
        call alignToFour                     ; n = r8

        ; cdecl routine
        push r9
        push r10
        push rbx

        ; get transposed matrix
        xchg rsi, rdi
        push r8                             ; stack: routine, n
        call matrixTranspose                ; b^T (m * n): transpose matrix b
        pop r8                              ; stack: routine
        xchg rsi, rdi
        push rsi                            ; original matrix b is in stack
        mov rsi, rax                        ; b^T = rsi: transposed matrix

        ; create a new matrix for the result
        push rsi                            ; stack: routine, b, b^T
        push rdi                            ; stack: routine, b, b^T, a
        mov rdi, rsi                        ; b^T = rdi
        call matrixGetRows
        mov rsi, rax                        ; m = rsi
        mov rdi, [rsp + 8]                  ; matrix a = rdi
        call matrixGetRows
        mov rdi, rax                        ; p = rdi
        call matrixAlloc                    ; create result matrix c, p = r9, m = r10
        mov rbx, rax                        ; matrix c (p * m) = rbx
        pop rdi                             ; a = rdi, stack: b, b^t
        pop rsi                             ; b^T = rsi, stack: b
        push rbx                            ; stack: routine, b, c
        mov rax, r9
        mul r8
        lea rcx, [rdi + rax * 4 + 16]       ; a.end = rcx
        mov rax, r10
        mul r8
        lea rdx, [rsi + rax * 4 + 16]       ; b^T.end = rdx

        ; multiply matrix a and b transposed, write result into matrix c
        push rsi                            ; stack: routine, b, c, b^T
        add rdi, 16                         ; start of data, matrix a
        add rbx, 16                         ; start of data, matrix c
        lea r8, [r8 * 4]                    ; row size is now in bytes
        .loop1:
                mov rsi, [rsp]
                add rsi, 16                 ; start of data, matrix b^T
                .loop2:
                        xor r9, r9
                        xorps xmm0, xmm0    ; sum = xmm0
                        .loop3:             ; iterate through elements in rows
                                movups xmm1, [rsi + r9]
                                movups xmm2, [rdi + r9]
                                dpps xmm1, xmm2, 0xF1
                                addss xmm0, xmm1
                                add r9, 16
                                cmp r9, r8
                                jne .loop3
                        movss [rbx], xmm0
                        add rbx, 4
                        add rsi, r8         ; next row in matrix b^T
                        cmp rsi, rdx
                        jne .loop2
                add rdi, r8                 ; next row in matrix a
                cmp rdi, rcx
                jne .loop1
        pop rdi                             ; stack: routine, b, c
        call matrixDelete                   ; don't need transposed matrix anymore
        pop rax                             ; stack: routine, b
        pop rsi                             ; stack: routine

        ; cdecl routine
        pop rbx
        pop r10
        pop r9
        pop r8
        xorps xmm1, xmm1
        xorps xmm2, xmm2
        ret
    .fail:
        xor rax, rax
        pop r8
        ret
