section .text

extern malloc
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
global matrixClone
global matrixTranspose

;we need number to be rounded to the nearest greater 4-divisible
%macro align_by_4 1 ;((x + 3) / 4) * 4
	add %1, 3
	shr %1, 2
	shl %1, 2
%endmacro

;sometimes we will need to know the pointer to exact cell [row, col] in matrix
;row value is in rsi, column value is in rdx
;matrix' pointer is in rdi 
%macro get_cell_pointer 0
;at first, we calculate the number of cell in matrix (row*Matrix.aligned_columns+column)
	imul rsi, [rdi+aligned_columns]
	add rsi, rdx ;rsi - cell's number
	shl rsi, 2 ;rsi*4 - number of cell's beginning
	
	mov rax, [rdi+cells] ;rax - pointer to the first cell
	add rax, rsi ;rax - pointer to desired cell
%endmacro

;rows and columns are stored aligned by 4
;so we can use them in SSE (vector) instructions
struc Matrix
	cells:			resq 1 ;pointer to float array of values
	rows:			resq 1 ;number of rows
	columns:		resq 1 ;number of columns
	aligned_rows:		resq 1 ;aligned number of rows
	aligned_columns:	resq 1 ;aligned number of columns
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int columns)
;
;description: creates new instance of Matrix
;
;takes: rdi - number of rows
;	    rsi - number of columns
;
;returns: rax - pointer to created Matrix, if succeded, and null instead
matrixNew:
	push rdi ;save needed registers
	push rsi

	mov rdi, Matrix_size 
	call malloc ;allocate memory for new Matrix
	
	mov rcx, rax ;malloc saves pointer to allocated space in rax, let's store it in rcx
	pop rsi
	pop rdi
	
	mov [rax+rows], rdi ;initialize matrix parameters
	mov [rax+columns], rsi 
	
	align_by_4 rdi ;align rows
	align_by_4 rsi ;align columns

	mov [rax+aligned_rows], rdi ;initialize aligned matrix parameters
	mov [rax+aligned_columns], rsi
	
	imul rdi, rsi ;define aligned matrix size
	mov rsi, 4 ;sizeof float
	push rcx
	
	call calloc ;allocate exact memory space for matrix
	
	pop rcx
	
	mov [rcx+cells], rax ;calloc uses rax in the same way as malloc, so we have pointer to allocated space or null, if allocation failed, in rax

	mov rax, rcx ;in rcx we stored pointer to Matrix, so let's move it to rax and return as result
	
	ret

;void matrixDelete(Matrix matrix)
;
;description: deletes previously allocated matrix
;
;takes: rdi - pointer to instance of Matrix
;
;returns: nothing
matrixDelete:
	push rdi
	mov rdi, [rdi+cells]
	call free ;frees all memory space, where matrix' cells are located

	pop rdi
	call free ;frees memory off matrix at all
	ret
		 
;unsigned int matrixGetRows(Matrix matrix)
;
;description: returns number of given matrix' rows
;
;takes: rdi - pointer to instance of Matrix
;
;returns: rax - number of rows
matrixGetRows:
	mov rax, [rdi+rows]
	ret
	
;unsigned int matrixGetColumns(Matrix matrix)
;
;description: returns number of given matrix' columns
;
;takes: rdi - pointer to instance of Matrix
;
;returns: rax - number of columns
matrixGetColumns:
	mov rax, [rdi+columns]
	ret

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;
;description: returns exact [row, col] element of Matrix
;
;takes: rdi - pointer to instance of matrix
;	    rsi - value of row
;	    rdx - value of col 
;
;returns: xmm0 - value in [row, col]
matrixGet:
	get_cell_pointer
	movss xmm0, [rax]
	ret

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
;
;description: sets value to [row, col] in matrix
;
;takes: rdi - pointer to instance of matrix
;	    rsi - value of row
;	    rdx - value of col
;	    xmm0 - value
;
;returns: nothing
matrixSet:
	get_cell_pointer
	movss [rax], xmm0
	ret

;Matrix matrixScale(Matrix matrix, float k)
;
;description: creates new matrix, which is a result of scaling given matrix by k
;
;takes: rdi - pointer to instance of matrix
;	    xmm0 - k
;returns: rax - pointer to new matrix
matrixScale:
	punpckldq xmm0, xmm0
	punpckldq xmm0, xmm0 ;create 4 instances of float, previosly stored in xmm0

	call matrixClone

	mov rcx, [rax+aligned_columns]
	imul rcx, [rax+aligned_rows] ;get cells' number
	mov r8, [rax+cells] ;get new matrix' cells' pointer

.mul_loop:
	movups xmm1, [r8] ;loads 4 first cells to xmm1 
	mulps xmm1, xmm0 ;multiplies two vectors: vector1 - vector with 4 cells, vector2 - vector with 4 scale values
	movups [r8], xmm1 ;returns changed cells to matrix
	add r8, 16 ;move output pointer 4*sizeof float bytes
	sub rcx, 4
	jnx .mul_loop
	
	ret
	
;Matrix matrixAdd(Matrix a, Matrix b) 
;
;description: creates new matrix, which is a result of summation of matrices a and b
;
;takes: rdi - pointer to Matrix a
;	    rsi - pointer to Matrix b
;
;returns: rax - pointer to new matrix
matrixAdd:
	push rdi
	push rsi
	
	;we can sum two matrices only if they have same parameters
	mov r8, [rdi+columns]
	mov r9, [rsi+columns]
	cmp r8, r9 ;check columns
	jne .invalid_input

	mov r8, [rdi+rows]
	mov r9, [rsi+rows]
	cmp r8, r9 ;check rows
	jne .invalid_input

	call matrixClone
	
	pop rdi
	pop rsi
        
    mov rcx, [rax+aligned_columns]
    imul rcx, [rax+aligned_rows] ;get cells' number
    mov r8, [rax+cells] ;get new matrix' cells' pointer
    mov r9, [rsi+cells] ;pointer to matrix b's cells

.add_loop:
    ;loads 4 cells of both matrix and sum them
    movups xmm0, [r8]
    movups xmm1, [r9]
    addps xmm0, xmm1
    movups [r8], xmm0 ;the result stored in first matrix's copy

    ;move output pointer 4*sizeof float bytes
    add r8, 16
    add r9, 16
    sub rcx, 4
    jnz .add_loop
    jmp .finish

.invalid_input:
    pop rsi
    pop rdi
    mov rax, 0

.finish:
    ret

;Matrix matrixMul(Matrix a, Matrix b) 
;
;description: creates new matrix, which is a result of multiplication of matrices a and b
;
;takes: rdi - pointer to Matrix a
;       rsi - pointer to Matrix b
;
;returns: rax - pointer to new matrix
matrixMul:
    push r14
    push r15
    push rbp

    ;we should check if we're allowed to mul matrices (m*n and n*p)
    mov r8, [rdi+columns]
    mov r9, [rsi+rows]
    cmp r8, r9
    jne .invalid_input

    mov r8, rdi
    mov r9, rsi

    xchg rdi, rsi ;change their places, so we can transpose second matrix

    push r8
    push r9

    call matrixTranspose ;we need to transpose matrix in rsi, the result is in rax  

    mov rbp, rax ;let's store transposed matris in rbp

    pop r9
    pop r8

    ;calculates parameters of the result matrix
    mov rdi, [r8+rows]
    mov rsi, [r9+columns]

    push r9
    push r8

    call matrixNew ;creates new matrix in rax with parameters m and p

    pop r8
    pop r9
    mov rdi, r8
    mov rsi, r9
    mov r8, [rdi+cells] ;first matrix' cells
    mov r9, [rbp+cells] ;transposed second matrix' cells
    mov r14, [rax+cells] ;result matrix' cells
    mov r10, [rsi+aligned_columns]
    mov r11, [rdi+aligned_rows]

    mov rdx, [rdi+aligned_columns]
    shl rdx, 2 ;size of one row in bytes

    mov rsi, r9
    mov rdi, r10

.loop_first:
    mov r10, rdi
    mov r9, rsi

.loop_second:
    xor r15, r15 ;r15 - number of moved elements in one iteration
    xorps xmm0, xmm0 ;temp var for storing sum

.loop_third:
    movups xmm1, [r8+r15] ;xmm1 = a:b:c:d
    movups xmm2, [r9+r15] ;xmm2 = e:f:g:h
    mulps xmm1, xmm2 ;xmm1 = a*e : b*f : c*g : d*h
    haddps xmm1, xmm1 ;xmm1 = a*e + b*f : c*g + d*h : a*e + b*f : c*g + d*h
    haddps xmm1, xmm1 ;xmm1 = a*e + b*f + c*g + d*h : ...
    addps xmm0, xmm1 ;add current result to our temp variable

    add r15, 16 ;move pointer 4*sizeof float bytes
    cmp r15, rdx ;check if we get to the finish of the line
    jb .loop_third

    add r9, rdx 
    movss [r14], xmm0 ;move current result to new matrix
    add r14, 4
    dec r10
    jnz .loop_second ;if we've filled whole line, we can continue with next line

    add r8, rdx 
    dec r11
    jnz .loop_first ;if we've finished with all lines, so we've found the result

    push rax

    mov rdi, rbp
    call matrixDelete ;we no longer need transposed second matrix

    pop rax 
    pop rbp
    pop r15
    pop r14
    ret

.invalid_input:
    mov rax, 0
    pop rbp
    pop r15
    pop r14
    ret 



;Matrix matrixClone(Matrix matrix)
;
;description: creates new matrix, which is a copy of given matrix
;
;takes: rdi - pointer to source matrix
;
;returns: rax - pointer to new matrix
matrixClone:
    push rbx
    mov rbx, rdi

    mov rdi, [rbx+rows]
    mov rsi, [rbx+columns]

    call matrixNew ;rax - pointer to new matrix

    mov rcx, [rax+aligned_columns]
    imul rcx, [rax+aligned_rows]

    pop rbx
    mov rdi, [rax+cells] ;cloned matrix pointer
    mov rsi, [rbx+cells] ;source matrix pointer

    rep movsd
    mov rdi, rsi ;moves cell values from source matrix to cloned

    ret

;Matrix matrixTranspose(Matrix matrix) 
;
;description: creates new matrix, which is a result of transposition of given matrix
;
;takes: rdi - pointer to source matrix
;
;returns; rax - pointer to new matrix
matrixTranspose:
    push r12
    push r13
    mov r8, rdi

    mov rdi, [r8+columns]
    mov rsi, [r8+rows]
    push r8
    call matrixNew
    pop r8
    mov rdi, r8

    mov r8, [rdi+cells] ;source matrix' cells
    mov r9, [rax+cells] ;new matrix' cells
    mov r10, [rdi+aligned_rows]
    mov r11, [rdi+aligned_columns]

    xor rcx, rcx

.outer_loop:
    xor r12, r12 ;number of cells moved in .inner_loop
    lea r13, [r9+rcx*4] ;address of first output cell

.inner_loop:
    movups xmm0, [r8] ;xmm0=a:b:c:d
    extracps [r13], xmm0, 0 ;[r13] := a

    lea r13, [r13+r10*4] ;update address to the next output cell
    extracps [r13], xmm0, 1 ;[r13] := b

    lea r13, [r13+r10*4] ;update address to the next output cell
    extracps [r13], xmm0, 2 ;[r13] := c

    lea r13, [r13+r10*4] ;update address to the next output cell
    extracps [r13], xmm0, 3 ;[r13] := d

    lea r13, [r13+r10*4]
    add r8, 16 ;move pointer 4*sizeof float bytes
    add r12, 4 ;we've moved 4 elements
    cmp r12, r11 ; if they're equal, so we've transposed the whole line 
    jb .inner_loop

    inc rcx
    cmp rcx, r10
    jb .outer_loop

    pop r13
    pop r12
    ret
