section .text

extern calloc
extern calloc
extern free

global matrixNew        ;done
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

; auxillary functions
global matrixCopy       ;done
global matrixTranspose

SIZE_OF_FLOAT EQU 4

;macro for rounding to multiplier of 4
%macro round_to_four 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
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