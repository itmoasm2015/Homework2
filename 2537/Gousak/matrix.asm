section .text

extern calloc
extern calloc
extern free

global matrixNew        ;done
global matrixDelete     ;done
global matrixGetRows    ;done
global matrixGetCols    ;done
global matrixGet        ;done
global matrixSet        ;done
global matrixScale      ;done
global matrixAdd
global matrixMul

; auxillary functions
global matrixCopy       ;done
global matrixTranspose  ;done

SIZE_OF_FLOAT EQU 4

;macro for rounding to multiplier of 4
%macro round_to_four 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

;macro to find the pointer to cell
;row = RSI
;col = RDX
;matrix_start = RDI
%macro get_cell_pointer 0
    imul rsi, [rdi + aligned_cols]
    add rsi, rdx           ; RSI =  cell's number
    shl rsi, 2             ; RSI * 4 = cell's start
    mov rax, [rdi + cells] ; RAX = pointer to cell
    add rax, rsi
%endmacro

struc Matrix
    cells           resq 1 ; pointer to float array
    rows            resq 1 ; number of rows
    cols            resq 1 ; number of columns
    aligned_rows    resq 1 ; aligned number of rows
    aligned_cols    resq 1 ; aligned number of columnss
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int cols)
;Create new matrix and fill it with zeros.
;args:      RDI - number of rows
;           RSI - number of cols
;returns:   RAX - pointer to matrix instance/null
matrixNew:
    push rdi ; save the state of registers
    push rsi
    mov rdi, Matrix_size ; allocate memory for the new Matrix
    call malloc

    mov rcx, rax ; RAX contains the result of calloc, store it in RCX
    pop rsi      ; restore previously saved registers
    pop rdi

    mov [rax + rows], rdi
    mov [rax + cols], rsi

    round_to_four rdi ; align rows and columns
    round_to_four rsi

    mov [rax + aligned_rows], rdi ; initialize matrix parameters
    mov [rax + aligned_cols], rsi
    imul rdi, rsi ; calculate aligned matrix size
    mov rsi, SIZE_OF_FLOAT

    push rcx
    call calloc ; allocate memory for matrix
    pop rcx
    mov [rcx + cells], rax ; get pointer to allocated space
    mov rax, rcx ; move pointer to matrix instance
    
    ret

;Matrix matrixCopy(Matrix matrix)
;Copies existing matrix (auxillary fucntion)
;args:      RDI - pointer to the original matrix
;returns:   RAX - pointer to the new matrix
matrixCopy:
    push rbx        ; save register
    mov rbx, rdi    ; load pointer
    
    mov rdi, [rbx + rows]
    mov rsi, [rbx + cols]

    call matrixNew ; RAX now points to the new matrix

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols]
    
    mov rdi, [rax + cells] ; cells of the copy
    mov rsi, [rbx + cells] ; cells of the original

    rep movsd ; move values cell-by-cell from the original to the copy
    mov rdi, rbx    
    pop rbx

    ret

;Matrix matrixTranspose(Matrix matrix)
;creates a new matrix by transposing an existing one
;args:      RDI - pointer to the original matrix
;returns:   RAX - pointer to the new matrix
matrixTranspose:
    push r12        ; save registers
    push r13        
    mov r8, rdi

    mov rdi, [r8 + cols]
    mov rsi, [r8 + rows]
    push r8
    call matrixNew
    pop r8
    mov rdi, r8

    mov r8, [rdi + cells] ; original matrix cells
    mov r9, [rax + cells] ; new matrix cells
    mov r10, [rdi + aligned_rows]
    mov r11, [rdi + aligned_cols]

    xor rcx, rcx ; reset the loop counter

.outer_loop:
    xor r12, r12 ; processed cells counter
    lea r13, [r9 + rcx * 4] ; address of the first output cell

.inner_loop:
    movups xmm0, [r8] ; XMM0 = A:B:C:D

    ; i should probably make some macro for that, lol
    extractps [r13], xmm0, 0 ; [R13] := a
    lea r13, [r13 + r10 * 4]
    
    extractps [r13], xmm0, 1 ; [R13] := b
    lea r13, [r13 + r10 * 4]

    extractps [r13], xmm0, 2 ; [R13] := c
    lea r13, [r13 + r10 * 4]

    extractps [r13], xmm0, 3 ; [R13] := d
    lea r13, [r13 + r10 * 4]
    
    add r8, 4 * SIZE_OF_FLOAT   ; move the cell pointer
    add r12, 4                  ; increment the counter
    cmp r12, r11                ; if (R12 == R11) -> process next line
    jl .inner_loop

    inc rcx
    cmp rcx, r10
    jl .outer_loop

    pop r13     ; restore registers
    pop r12
    ret

;void matrixDelete(Matrix matrix)
;Deletes matrix
;args:      RDI - pointer to of matrix
;returns:   void
matrixDelete:
    push rdi
    mov rdi, [rdi + cells]
    call free ; deletes cells

    pop rdi
    call free ; deletes entire matrix
    ret

;unsigned int matrixGetRows(Matrix matrix)
;Gets the number of rows
;args:      RDI - pointer to matrix
;returns:   RAX - number of rows
matrixGetRows
    mov rax, [rdi + rows]
    ret

;unsigned int matrixGetCols(Matrix matrix)
;Gets the number of cols
;args:      RDI - pointer to matrix
;returns:   RAX - number of columns
matrixGetCols
    mov rax, [rdi + cols]
    ret

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;Gets the value of the cell
;args:      RDI  - pointer to matrix
;           RSI  - row index
;           RDX  - column index
;returns:   XMM0 - value of the cell
matrixGet:
    get_cell_pointer
    movss xmm0, [rax]
    ret

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
;Sets the value of the cell
;args:      RDI  - pointer to matrix
;           RSI  - row index
;           RDX  - column index
;           XMM0 - desired cell's value 
;returns:   void
matrixSet:
    get_cell_pointer
    movss [rax], xmm0
    ret

;Matrix matrixScale(Matrix matrix, float k)
;Multiplies matrix' cells by k
;args:      RDI  - pointer to matrix
;           XMM0 - coefficient
;returns:   RAX  - pointer to new matrix
matrixScale:
    ; boldly stolen this trick from my friend's code
    ; gets 4 instances of the coefficient in XMM0
    punpckldq xmm0, xmm0 ; ?:?:k:k
    punpckldq xmm0, xmm0 ; k:k:k:k

    call matrixCopy

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols] ; calculate the number of cells
    mov r8, [rax + cells]          ; pointer to the copy's cells

.mul_loop:
    movups xmm1, [r8]         ; load a vector of cells
    mulps xmm1, xmm0          ; multiply by XMM0
    movups [r8], xmm1         ; return the values to the respective cells
    add r8, 4 * SIZE_OF_FLOAT ; move the pointer
    sub rcx, 4                ; keep scaling by 4 cells
    jnz .mul_loop

    ret

;Matrix matrixAdd(Matrix a, Matrix b)
;Creates a new matrix c = a + b
;args:      RDI - pointer to the matrix a
;           RSI - pointer to the matrix b
;returns:   RAX - pointer to the new matrix
matrixAdd:
    push rdi
    push rsi

    ; check matrices' dimensions
    mov r8, [rdi + cols]
    mov r9, [rsi + cols]
    cmp r8, r9
    jne .incompatible
    
    mov r8, [rdi + rows]
    mov r9, [rsi + rows]
    cmp r8, r9
    jne .incompatible

    call matrixCopy         ; copy the matrix a

    pop rsi
    pop rdi

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols] ; calculate the number of cells

    mov r8, [rax + cells]   ; pointer to the cells of the result/copy
    mov r9, [rsi + cells]   ; pointer to the cells of the matrix b

.add_loop:
    movups xmm0, [r8]       ; load 4 cells of both matrix and sum them
    movups xmm1, [r9]
    addps xmm0, xmm1
    movups [r8], xmm0       ; store the result in first matrix's copy

    add r8, 4 * SIZE_OF_FLOAT
    add r9, 4 * SIZE_OF_FLOAT
    
    sub rcx, 4              ; keep processing by 4 cells
    jnz .add_loop 
    jmp .return

.incompatible:
    pop rsi
    pop rdi
    mov rax, 0

.return:
    ret
