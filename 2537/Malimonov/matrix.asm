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
global matrixCopy

;multiples-of-4 alignment macro
%macro align_to_quad 1
;((x + 3) / 4) * 4
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

;macro to find the pointer to cell
;row = RSI, col = RDX, matrix_start = RDI
%macro get_cell_pointer 0
    imul rsi, [rdi + aligned_cols]
    add rsi, rdx    ; RSI =  cell number
    shl rsi, 2      ; RSI * 4 = cell start
    mov rax, [rdi + cells] ; RAX = pointer to first cell
    add rax, rsi
%endmacro

struc Matrix
    cells           resq 1 ; pointer to float array
    rows            resq 1 ;
    columns         resq 1 ;
    aligned_rows    resq 1 ;
    aligned_cols    resq 1 ;
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int cols)
;creates new Matrix instance
;input:     RDI: number of rows
;           RSI: number of cols
;return:    RAX: pointer to Matrix instance on success, null on fail
matrixNew:
    push rdi ; save the state of registers
    push rsi

    mov rdi, Matrix_size ; allocate memory for the new Matrix
    call malloc

    mov rcx, rax ; RAX contains the result of calloc, store it in RCX
    pop rsi
    pop rdi

    mov [rax + rows], rdi
    mov [rax + cols], rsi

    align_to_quad rdi
    align_to_quad rsi
    mov [rax + aligned_rows], rdi
    mov [rax + aligned_cols], rsi

    imul rdi, rsi   ; calculate matrix size considering alignment
    mov rsi, 4      ; sizeof float

    push rcx
    call calloc
    pop rcx

    mov [rcx + cells], rax ; 

    mov rax, rcx ; move pointer to Matrix instance to RAX
    
    ret

;Matrix matrixCopy
;creates an instance of Matrix copying an existing one
;(an auxiliary operation which simplifies matrixAdd, matrixScale, etc.)
;input:     RDI: pointer to the original matrix
;return:    RAX: pointer to copy
matrixCopy:
    push rbx
    mov rbx, rdi
    
    mov rdi, [rbx + rows]
    mov rsi, [rbx + cols]

    call matrixNew ; RAX now points to the new matrix

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols]

    pop rbx
    mov rdi, [rax + cells] ; cells of the copy
    mov rsi, [rbx + cells] ; cells of the original

    rep movsd ; move values cell-by-cell from the original to the copy
    mov rdi, rbx    

    ret

;void matrixDelete(Matrix matrix)
;deletes the Matrix and deallocates the memory it had been occupying
;input:     RDI: pointer to matrix
matrixDelete:
    push rdi
    mov rdi, [rdi + cells]
    call free ; delete cells

    pop rdi
    call free ; delete matrix
    ret

;unsigned int matrixGetRows(Matrix matrix)
;returns the number of rows in the Matrix
;input:     RDI: pointer to matrix
;return:    RAX: number of rows
matrixGetRows
    mov rax, [rdi + rows]
    ret

;unsigned int matrixGetCols(Matrix matrix)
;returns the number of cols in the Matrix
;input:     RDI: pointer to matrix
;return:    RAX: number of cols
matrixGetCols
    mov rax, [rdi + cols]
    ret

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;retrieves the value of a given cell
;input:     RDI: pointer to matrix
;           RSI: row number
;           RDX: col number
;return:    XMM0: value of the cell
matrixGet:
    get_cell_pointer
    movss xmm0, [rax]
    ret

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
;sets the value of a given cell
;input:     RDI: pointer to matrix
;           RSI: row number
;           RDX: col number
;           XMM0: value to be put into the cell
matrixSet:
    get_cell_pointer
    movss [rax], xmm0
    ret

;Matrix matrixScale(Matrix matrix, float k)
;returns a new Matrix c = matrix * k
;input:     RDI: pointer to matrix
;           XMM0: float coefficient
;return:    RAX: pointer to the new Matrix
matrixScale:
    punpckldq xmm0, xmm0 ; ?:?:k:k
    punpckldq xmm0, xmm0 ; k:k:k:k

    call matrixCopy

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols] ; calculate the number of cells
    mov r8, [rax + cells] ; pointer to the cells of the copy

.mul_loop:
    movups xmm1, [r8]   ; load a vector of cells to XMM1
    mulps xmm1, xmm0    ; multiply by XMM0
    movups [r8], xmm1   ; return the values to the corresponding cells
    add r8, 16          ; move the cell pointer by 4 * sizeof float
    sub rcx, 4          ; 4 cells processed, subtract until we've scaled the whole matrix
    jnz .mul_loop

    ret

;Matrix matrixAdd(Matrix a, Matrix b)
;returns a new Matrix c = a + b
;input:     RDI: pointer to the first matrix
;           RSI: pointer to the second matrix
;return:    RAX: pointer to the new Matrix
matrixAdd:
    push rdi
    push rsi

    ;dimension compatibility check
    mov r8, [rdi + cols]
    mov r9, [rsi + cols]
    cmp r8, r9
    jne .incompatible
    
    mov r8, [rdi + rows]
    mov r9, [rsi + rows]
    cmp r8, r9
    jne .incompatible

    call matrixCopy         ; copy the first matrix

    pop rsi
    pop rdi

    mov rcx, [rax + aligned_rows]
    imul rcx, [rax + aligned_cols] ; calculate the number of cells

    mov r8, [rax + cells]   ; pointer to the cells of the result/copy
    mov r9, [rsi + cells]   ; pointer to the cells of the second matrix

.add_loop:
    movups xmm0, [r8]       ; load 4 cells of the first matrix
    movups xmm1, [r9]       ; load 4 cells of the second matrix
    addps xmm0, xmm1        ; addition
    movups [r8], xmm0       ; move the result of the addition to
                            ;the corresponding cells of
                            ;the resulting matrix

    ;move the pointers by 4 * sizeof float forward
    add r8, 16
    add r9, 16
    sub rcx, 4              ; 4 more cells processed, repeat
    jnz .add_loop           ; until we've processed everything
    jmp .return

.incompatible:
    pop rsi
    pop rdi
    mov rax, 0

.return:
    ret

;Matrix matrixMul(Matrix a, Matrix b)

