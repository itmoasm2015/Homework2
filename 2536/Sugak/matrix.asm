section .text

extern calloc
extern free
extern malloc

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul
global matrixClone
global matrixTranspose

;rounds number to the nearest greater 4-divisible value
%macro round_to4 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

;get argument to point to matrix cell at row RSI column RDX with the matrix being held in RDI
%macro get_cell_pointer 0
;first we calculate the number of cell in the matrix which is (row * Matrix.aligned_columns + column)
    imul rsi, [rdi + aligned_columns]
    add rsi, rdx  ; RSI = number of cell
    shl rsi, 2    ; RSI * 4 = number of byte where cell begins

    mov rax, [rdi + cells] ; RAX = pointer to first cell
    add rax, rsi ; RAX = adress of the beginning of specified cell
%endmacro

;Matrix dimensions are stored aligned by 4, so that we can use them in vector instructions.
struc Matrix
    cells:              resq 1 ; pointer to array of float values stored
    rows:               resq 1 ; unaligned amount of rows
    columns:            resq 1 ; unaligned amount of columns
    aligned_rows        resq 1 ; aligned amount of rows
    aligned_columns     resq 1 ; aligned amount of columns
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int columns)
;creates new Matrix instance
;takes:     RDI - amount of rows
;           RSI - amount of columns
;returns:   RAX - pointer to created Matrix or null if failed
matrixNew:
    push rdi ; save registers
    push rsi

    mov rdi, Matrix_size ; allocate memory for Matrix structure
    call malloc

    mov rcx, rax ; RAX has the result of calloc, save it to RCX
    pop rsi
    pop rdi

    mov [rax + rows], rdi  ; initialize matrix dimensions
    mov [rax + columns], rsi

    round_to4 rdi  ; align matrix dimensions
    round_to4 rsi
    mov [rax + aligned_rows], rdi ; initialize corresponding fields in struct
    mov [rax + aligned_columns], rsi

    imul rdi, rsi ; calculate aligned matrix size
    mov rsi, 4    ; sizeof float
    push rcx

    call calloc

    pop rcx

    mov [rcx + cells], rax ; RAX - pointer to allocated space or null if allocation failed

    mov rax, rcx ; move pointer to Matrix to RAX and return

    ret

;Matrix matrixClone(Matrix m)
;Copies the existing matrix to a new one.
;takes:     RDI - initial matrix pointer
;returns:   RAX - new matrix pointer
matrixClone:
    mov rbx, rdi
    push rbx

    mov rdi, [rbx + rows]
    mov rsi, [rbx + columns]

    call matrixNew ; RAX - pointer to newly initialized matrix

    mov rcx, [rax + aligned_columns]
    imul rcx, [rax + aligned_rows]


    pop rbx
    mov rdi, [rax + cells] ; cloned matrix pointer
    mov rsi, [rbx + cells] ; initial matrix pointer

    rep movsd
    mov rdi, rbx   ; move cell values from initial matrix to cloned.

    ret

;void matrixDelete(Matrix m)
;Deletes matrix and deallocates the space taken by it's cells.
;takes:     RDI - matrix pointer
matrixDelete:
    push rdi
    mov rdi, [rdi + cells]
    call free ; delete matrix cells

    pop rdi
    call free ; delete matrix
    ret

;unsigned int matrixGetRows(Matrix m)
;Returns the amount of rows in the given matrix
;takes:     RDI - matrix pointer
;returns:   RAX - amount of rows
matrixGetRows:
    mov rax, [rdi + rows]
    ret

;unsigned int matrixGetCols(Matrix m)
;Returns the amount of columns in the given matrix
;takes:     RDI - matxi
;returns:   RAX - amount of columns
matrixGetCols:
    mov rax, [rdi + columns]
    ret

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;Get value in specified matrix cell.
;takes:     RDI - matrix pointer
;           RSI - number of row
;           RDX - number of column
;returns:   RAX - values strored in the cell
matrixGet:
    get_cell_pointer
    movss xmm0, [rax] ; return specified cell in RAX
    ret

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
;Sets the specified cell of the matrix to hold value.
;takes:     RDI - matrix pointer
;           RSI - number of row
;           RDX - number of column
;           XMM0 - float value
matrixSet:
    get_cell_pointer
    movss [rax], xmm0 ; move provided value to specified cell
    ret

;Matrix matrixAdd(Matrix a, Matrix b)
;Returns new matrix which is a result of matrix addition a + b
;takes:     RDI - first matrix
;           RSI - second matrix
;returns:   RAX - result of addition
matrixAdd:
    push rdi
    push rsi
    ;check if matrices can be added
    mov r8, [rdi + columns]
    mov r9, [rsi + columns]
    cmp r8, r9
    jne .bad_dimensions

    mov r8, [rdi + rows]
    mov r9, [rsi + rows]
    cmp r8, r9
    jne .bad_dimensions

    call matrixClone ; copy the first matrix to put result to

    pop rsi
    pop rdi

    mov rcx, [rax + aligned_columns] ; get the amount of cells
    imul rcx, [rax + aligned_rows]

    mov r8, [rax + cells] ; R8 - pointer to resulting matrix cells
    mov r9, [rsi + cells] ; R9 - pointer to second matrix cells

.add_loop:
    ; load 4 cells of each matrix into XMM0 and XMM1 respectively and add them
    movups xmm0, [r8]
    movups xmm1, [r9]
    addps xmm0, xmm1
    movups [r8], xmm0 ; put the result of addition into resulting matrix cells

    ;move pointers 4 * sizeof float
    add r8, 16
    add r9, 16
    sub rcx, 4
    jnz .add_loop
    jmp .finish

.bad_dimensions: ; matrices have uneven dimension and can not be added
    mov rax, 0

.finish:
    ret

;Matrix matrixScale(Matrix m, float k)
;Returns new matrix which is a result of multiplying given matrix by given float value. Initial matrix is unaffected.
;takes:     RDI - matrix pointer
;           XMM0 - float value
;returns:   RAX - pointer to scaled matrix
matrixScale:
    punpckldq xmm0, xmm0
    punpckldq xmm0, xmm0 ; populate XMM0 with float 4 instances of float previously stored in XMM0 (XMM0 = K : K : K : K)

    call matrixClone

    mov rcx, [rax + aligned_columns]
    imul rcx, [rax + aligned_rows] ; get the amount of cells
    mov r8, [rax + cells] ; get new matrix cells pointer

.mul_loop:
    movups xmm1, [r8] ; load 4 of the cells to XMM1 register
    mulps xmm1, xmm0  ; multiply them by XMM0 vector
    movups [r8], xmm1 ; and put them back to the matrix
    add r8, 16        ; move output pointer 4 * sizeof float bytes
    sub rcx, 4
    jnz .mul_loop

    ret

;Matrix matrixTranspose(Matrix m)
;Returns new matrix which is a result of initial matrix transposition, doesnt change initial matrix.
;takes:     RDI - matrix to be transposed
;returns:   RAX - transposed matrix
matrixTranspose:
    push r12
    push r13
    mov r8, rdi

    mov rdi, [r8 + columns]
    mov rsi, [r8 + rows]
    push r8
    call matrixNew
    pop r8
    mov rdi, r8

    mov r8, [rdi + cells] ; initial matrix cells
    mov r9, [rax + cells] ; new matrix cells
    mov r10, [rdi + aligned_rows]
    mov r11, [rdi + aligned_columns]

    xor rcx, rcx ; loop iterations
.outer:
    xor r12, r12 ; amount of elements moved in inner loop
    lea r13, [r9 + rcx * 4] ; adress of first output cell
.inner:
    movups xmm0, [r8] ; XMM0 = A : B : C : D
    extractps [r13], xmm0, 0 ; [R13]  <- A

    lea r13, [r13 + r10 * 4] ; update adress to the next output cell
    extractps [r13], xmm0, 1 ; [R13]  <- B

    lea r13, [r13 + r10 * 4]
    extractps [r13], xmm0, 2 ; [R13] <- C

    lea r13, [r13 + r10 * 4]
    extractps [r13], xmm0, 3 ; [R13] <- D

    lea r13, [r13 + r10 * 4]
    add r8, 16 ; move pointer by 4 * sizeof float bytes
    add r12, 4 ; increase moved elements counter
    cmp r12, r11 ; if R12 == R11 we have transposed one whole line, proceed to the next one
    jb .inner
    inc rcx
    cmp rcx, r10
    jb .outer

    pop r13
    pop r12
    ret

;Matrix matrixMul(Matrix a, Matrix b)
;Returns new matrix which is a result of multiplying matrices a and b.
;takes:     RDI - first matrix
;           RSI - second matrix
;returns:   RAX - result of multiplication
matrixMul:
    push r14
    push r15
    push rbp

    ;check if matrices are of kind x*y y*z and can be multiplied.
    mov r8, [rdi + columns]
    mov r9, [rsi + rows]
    cmp r8, r9
    jne .bad_dimensions

    mov r8, rdi
    mov r9, rsi

    xchg rdi, rsi ; place RSI to RDI to be able to transpose second matrix

    push r8
    push r9

    call matrixTranspose ; transposed RSI in RAX

    mov rbp, rax ; transposed matrix saved to RBP
    pop r9
    pop r8
    mov rdi, [r8 + rows] ; get the dimensions of resulting matrix to call matrixNew
    mov rsi, [r9 + columns]

    push r9
    push r8

    call matrixNew ; RAX - x*z - resulting matrix

    pop r8
    pop r9
    mov rdi, r8
    mov rsi, r9
    mov r8, [rdi + cells] ; first initial matrix cells
    mov r9, [rbp + cells] ; transposed second matrix cells
    mov r14, [rax + cells] ; resulting matrix cells
    mov r10, [rsi + aligned_columns]
    mov r11, [rdi + aligned_rows]

    mov rdx, [rdi + aligned_columns]
    shl rdx, 2 ; size of one row in bytes

    mov rsi, r9
    mov rdi, r10

.loop1:
    mov r10, rdi
    mov r9, rsi

.loop2:
    xor r15, r15 ; R15 - amount of elements moved in current iteration
    xorps xmm0, xmm0 ; temporary variable for summing up results

.loop3:
    movups xmm1, [r8 + r15] ; XMM1 = A : B : C : D
    movups xmm2, [r9 + r15] ; XMM2 = E : F : G : H
    mulps xmm1, xmm2        ; XMM1 = A*E : B*F : C*G : D*H
    haddps xmm1, xmm1       ; XMM1 = A*E+B*F : C*G+D*H : A*E+B*F : C*G+D*H
    haddps xmm1, xmm1       ; XMM1 = (A*E+B*F)+(C*G+D*H) : ...
    addss xmm0, xmm1        ; add current result to xmm0
    add r15, 16             ; move pointer 4 * sizeof float bytes
    cmp r15, rdx            ; check if we have processed whole line
    jb .loop3

    add r9, rdx
    movss [r14], xmm0 ; move result to new matrix cell
    add r14, 4
    dec r10
    jnz .loop2    ; if we have filled whole line in resulting matrix (r10 == 0) move to next line in first operand matrix

    add r8, rdx
    dec r11
    jnz .loop1    ; if we have processed all lines (r11 == 0) in first operand we have found the result

    push rax

    mov rdi, rbp
    call matrixDelete ; deallocate transposed second matrix

    pop rax
    pop rbp
    pop r15     ; restore callee saved registers
    pop r14
    ret

.bad_dimensions: ; matrices can not be multiplied, return 0
    mov rax, 0
    pop rbp
    pop r15
    pop r14
    ret