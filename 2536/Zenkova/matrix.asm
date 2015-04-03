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
;at first, we calculate the number of cell in matrix (row*Matrix.aligned_colums+column)
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
;	rsi - number of columns
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
	align_by_4 rsi ;align colums

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
;	rsi - value of row
;	rdx - value of col 
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
;	rsi - value of row
;	rdx - value of col
;	xmm0 - value
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
;	xmm0 - k
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
;	rsi - pointer to Matrix b
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
;	rsi - pointer to Matrix b
;
;returns: rax - pointer to new matrix
matrixMul:

;Matrix matrixClone(Matrix matrix)
;
;description: creates new matrix, which is a copy of given matrix
;
;takes: rdi - pointer to source matrix
;
;returns: rax - pointer to new matrix
matrixClone:

;Matrix matrixTranspose(Matrix matrix) 
;
;description: creates new matrix, which is a result of transposition of given matrix
;
;takes: rdi - pointer to source matrix
;
;returns; rax - pointer to new matrix
matrixTranspose:

