global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixCopy
global matrixScale
global matrixAdd
global matrixMul


extern aligned_alloc
extern free

;struct matrix_t {
;	unsigned long long rows, cols;
;	float buffer[rows' * cols'];
;}
;rows and cols - real matrix size
;buf is align to 16 bytes, so I consider that rows and cols divide by 4.
; "'" means, that this number ceil to number dividable by 4.

;rounds argument to 4 for alignment
%macro fourCeil 1
	add		%1, 3
	and		%1, ~3
%endmacro

;put to rax size of matrix from first argument 
;argument can not be rdx
;save all registers almost rax and rdx
%macro matrixSize 1
	mov		rdx, [%1 + 8]
	fourCeil rdx
	mov		rax, [%1]
	fourCeil rax
	mul		rdx
%endmacro


section .text
;Matrix matrixNew(unsigned int rows, unsigned int cols)
;creates new matrix [rows*cols] and fill it with zeros
matrixNew:
	enter	 0, 0 ;save state
	push	r12
	push	r13
	push	r14
	
	mov		rax, rdi	;rows
	fourCeil rax		;rows'
	mov		rdx, rsi	;cols
	fourCeil rdx		;cols'
	mul		rdx			
	sal		rax, 2		;rax <- size of buffer, 4 bytes for every float
	mov		r14, rax	;r14 <- size of buffer
	add		rax, 16		;rax <- size of buffer with rows and cols, 
	
	mov		r12, rdi	;save rows and cols
	mov		r13, rsi
	
	mov		rdi, 16		;prepare arguments to aligned_alloc, first - is alignment, second - count of bytes for alloc
	mov		rsi, rax
	call	aligned_alloc	
		
	test	rax, rax	;if alloc fail return NULL
	jz		.failure

	mov		[rax], r12		;save cols and rows to Matrix
	mov		[rax + 8], r13
	mov		r12, rax		;save pointer

	mov		rcx, r14		;filling with zeros
	lea		rdi, [rax + 16]
	xor		rax, rax
	rep		stosb
	
	mov		rax, r12		;load pointer for ret
.failure
	pop		r14	;load state
	pop		r13
	pop		r12
	leave
	ret

;void matrixDelete(Matrix)
;delete matrix, use free()
matrixDelete:
	call	free			
	ret

;unsigned long long matrixGetRows(Matrix)
;return count of rows of matrix
matrixGetRows:
	mov		rax, [rdi]
	ret

;unsigned long long matrixGetCols(Matrix)
;return count of columns of matrix
matrixGetCols:
	mov		rax, [rdi + 8]
	ret

;float matrixGet(Matrix matrix, unsigned long long row, unsigned long long col)
;return (row, col) element from matrix
matrixGet:
	mov		rax, [rdi + 8]				
	fourCeil rax
	mov		rcx, rdx					;rdx bad after mul
	mul		rsi
	add		rax, rcx
	movss	xmm0, [rdi + 4 * rax + 16]
	ret

;void matrixSet(Matrix matrix, unsigned long long row, unsigned long long col, float value)
;set (row, col) element from matrix to value
matrixSet:
	mov		rax, [rdi + 8]
	fourCeil rax
	mov		rcx, rdx					;rdx bad after mul
	mul		rsi
	add		rax, rcx
	movss	[rdi + 4 * rax + 16], xmm0
	ret

;Matrix matrixCopy(Matrix matrix)
;return new Matrix with same sizes and elements as matrix
;or NULL if aligned_alloc fail
matrixCopy:
	enter	0, 0		;save state
	push	r12		
	push	r13
	
	mov		r13, rdi	;save Matrix 
	
	matrixSize rdi

	sal		rax, 2		
	add		rax, 16		;compute size of matrix in bytes
	mov		r12, rax	;save size

	mov		rdi, 16		
	mov		rsi, rax
	call	aligned_alloc	;alloc this memory, rax <- new Matrix
	test	rax, rax	;test that rax is not NULL
	jz		.failure

	mov		rcx, r12	;copy data
	mov		rdi, rax
	mov		rsi, r13
	rep		movsb	

.failure
	pop		r13			;load state
	pop		r12
	leave
	ret

;Martix matrixScale(Matrix, float)
;return Matrix, which has same elements as first matrix, but multiply on second argument
;or NULL if alligned_alloc fail
matrixScale:
	enter	0, 0		;save state

	sub		rsp, 4		;align stack on 16 bytes for calling matrixCopy
	and		rsp, ~0xf
	movss	[rsp], xmm0	;save xmm0
	
	call	matrixCopy
	test	rax, rax	;test that rax is not NULL
	jz		.failure	
	
	push	rax
	matrixSize rax	
	
	mov		rcx, rax	;rcx <- current index of last float
	pop		rax	
	pshufd	xmm0, [rsp], 0	;load xmm0
	
.scale_loop
	movaps	xmm1, [rax + rcx * 4]	;multiply group of four number on xmm0, and return back to the memory
	mulps	xmm1, xmm0
	movaps	[rax + rcx * 4], xmm1
	sub		rcx, 4
	test	rcx, rcx
	jnz		.scale_loop

.failure
	leave
	ret

;Matrix matrixAdd(Matrix matrix1, Matrix matrix2)
;return new Matrix with same size as matrix1 and matrix2
;with elements equals sum of appropriate ones from matrix1 and matrix2
;return NULL if matrix1 and matrix2 have different sizes or if alligned_alloc fails
matrixAdd:
	enter	0, 0
	
	xor		rax, rax	;clear rax in case NULL-return because of diferent sizes

	mov		rdx, [rdi]	;check rows
	mov		rcx, [rsi]
	cmp		rcx, rdx
	jne		.failure

	mov		rdx, [rdi + 8]	;check cols
	mov		rcx, [rsi + 8]
	cmp		rcx, rdx
	jne		.failure

	push	rsi		;copy matrix from rdi. save rsi, because it isn't callee-saved.
	call	matrixCopy
	pop		rsi
	
	test	rax, rax	;test that rax is not NULL
	jz		.failure

	mov		rdi, rax	;save address to rdi
	matrixSize rax		;compute size
	mov		rcx, rax	;prepare to circle
	mov		rax, rdi

.add_loop
	movaps	xmm0, [rax + rcx * 4]	;load four floats from first matrix
	addps	xmm0, [rsi + rcx * 4]	;sum they with four float from second matrix
	movaps	[rax + rcx * 4], xmm0	;save result to matrix-answer

	sub		rcx, 4
	test	rcx, rcx
	jnz		.add_loop

.failure
	leave
	ret

;Matrix matrixMul(Matrix matrix1, Matrix matrix2)
;return Matrix - product of matrix1 and matrix2 in that order (multiplication is not commutative)
;let matrix1 has sizes [a * b], and matrix2 has sizes [c * d]
;for multiplication b should be equal to c, if it is not, then matrixMul return NULL,
;also it may return NULL if aligned_alloc fail.
;undefine behavior if one of a, b, c or d is zero.
;
;size of new Matrix-product will be [a * d]
;
;Because of often cache-missing I use strange way to multiply matrixes.
;I take one column from second matrix, rotate it (alloc memory and copy it to this memory).
;after it, I multiply every first matrix row to this column and write it to answer column. 
;So I have two series of cache-misses: first - in copy column to extra memory, second - in writing floats to answer
;
matrixMul:
	enter	0, 0	;save state
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx

	xor		rax, rax	;clear rax for NULL-return situation
	mov		r9, [rdi + 8]	;check that b equals to c
	mov		r10, [rsi]
	cmp		r9, r10
	jne		.failure

	mov		r12, rdi				;r12 <- matrix1
	mov		r13, rsi				;r13 <- matrix2
	
	;alloc memory for one column
	mov		rdi, 16
	mov		rsi, [r13]
	fourCeil rsi
	sal		rsi, 2		;rsi <- size of one column
	call	aligned_alloc
	test	rax, rax	;check that rax isn't NULL 
	jz		.failure
	mov		rbx, rax
	
	;create room for result
	mov		rdi, [r12]
	mov		rsi, [r13 + 8]
	mov		r15, rsi	;r15 <- d, it will be counter for main_loop
	call	matrixNew
	test	rax, rax	;check that rax isn't NULL
	jz		.failure
	mov		r14, rax	;r14 <- address of answer
	
	
.main_loop
	mov		rcx, [r13]	;prepare to copying column rcx <- b(c)
	xor		rdx, rdx	;rdx will be variable of circle
	mov		r8, [r13 + 8]	;r8 <- d
	fourCeil r8		
	sal		r8, 2	;count of bytes in memory	
	mov		r9, r13	;it will be pointer to row in second matrix
	
	;copying - use eax for buffer
	.copy_column
		mov		eax, [r9 + r15 * 4 + 12]
		mov		[rbx + rdx * 4], eax
		add		r9, r8
		inc		rdx
		cmp		rdx, rcx
		jl		.copy_column
	
	mov		rcx, [r12]	;rcx <- a, it will be counter for loop1
	mov		r9,	r14	;it will be pointer to row in address
	
	push	r12		;save registers, because I need more 
	push	r13
	push	r14	

	mov		r13, [r12 + 8]
	fourCeil r13
	sal		r13, 2	;real size of row in first matrix

	.loop1
		xorps	xmm0, xmm0
		mov		r14, r13	;end of row in first matrix
		.loop2
			movaps	xmm1, [r12 + r14]	;compute dot product and add it to xmm0
			movaps	xmm2, [rbx + r14 - 16]
			dpps	xmm1, xmm2, 0xF1
			addss	xmm0, xmm1

			sub		r14, 16				;decrease counter
			test	r14, r14
			jnz		.loop2
		
		movss	[r9 + r15 * 4 + 12], xmm0	;save xmm0 to answer
		add		r9, r8	;go to next row in answer
		add		r12, r13	;go to next row in first matrix
		loop	.loop1
	
	pop		r14			;load registers
	pop		r13
	pop		r12

	dec		r15
	test	r15, r15
	jnz		.main_loop
	
	mov		rax, r14	;answer in r14
.failure
	pop		rbx			;load state
	pop		r15
	pop		r14
	pop		r13
	pop		r12
	leave
	ret
