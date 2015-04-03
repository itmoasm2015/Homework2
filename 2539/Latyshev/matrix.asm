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

	mov		rcx, r12	;copy data
	mov		rdi, rax
	mov		rsi, r13
	rep		movsb	
	
	pop		r13			;load state
	pop		r12
	leave
	ret

matrixScale:
	enter	0, 0

	sub		rsp, 4
	and		rsp, ~0xf
	movss	[rsp], xmm0
	
	call	matrixCopy
	push	rax
	matrixSize rax
	
	mov		rcx, rax
	pop		rax	
	pshufd	xmm0, [rsp], 0
.scale_loop
	movaps	xmm1, [rax + rcx * 4]
	mulps	xmm1, xmm0
	movaps	[rax + rcx * 4], xmm1
	sub		rcx, 4
	test	rcx, rcx
	jnz		.scale_loop
	
	leave
	ret

matrixAdd:
	enter	0, 0

	push	rsi
	call	matrixCopy
	pop		rsi
	mov		rdi, rax
	matrixSize rax
	mov		rcx, rax
	mov		rax, rdi

.add_loop
	movaps	xmm0, [rax + rcx * 4]
	addps	xmm0, [rsi + rcx * 4]
	movaps	[rax + rcx * 4], xmm0

	sub		rcx, 4
	test	rcx, rcx
	jnz		.add_loop

	leave
	ret

matrixMul:
	enter	0, 0
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx

	xor		rax, rax
	mov		r9, [rdi + 8]
	mov		r10, [rsi]
	cmp		r9, r10
	jne		.failure

	mov		r12, rdi				;matrix a
	mov		r13, rsi				;matrix b
	


	;alloc memory for one column
	mov		rdi, 16
	mov		rsi, [r13]
	fourCeil rsi
	sal		rsi, 2
	call	aligned_alloc
	test	rax, rax
	jz		.failure
	mov		rbx, rax
	
	;create room for result
	mov		rdi, [r12]
	mov		rsi, [r13 + 8]
	mov		r15, rsi
	call	matrixNew
	mov		r14, rax
	
	
.main_loop
	mov		rcx, [r13]
	xor		rdx, rdx
	mov		r8, [r13 + 8]
	fourCeil r8
	sal		r8, 2
	mov		r9, r13

	.copy_column
		mov		eax, [r9 + r15 * 4 + 12]
		mov		[rbx + rdx * 4], eax
		add		r9, r8
		inc		rdx
		cmp		rdx, rcx
		jl		.copy_column
	
	mov		rcx, [r12]
	
	mov		r9,	r14
	lea		rdx, [r15 * 4]
	push	r12
	push	r13
	push	r14	
	mov		r13, [r12 + 8]
	fourCeil r13
	sal		r13, 2

	.loop1
		xorps	xmm0, xmm0
		mov		r14, r13
		.loop2
			movaps	xmm1, [r12 + r14]
			movaps	xmm2, [rbx + r14 - 16]
			dpps	xmm1, xmm2, 0xF1
			addss	xmm0, xmm1

			sub		r14, 16			
			test	r14, r14
			jnz		.loop2
		
		movss	[r9 + r15 * 4 + 12], xmm0
		add		r9, r8
		add		r12, r13
		loop	.loop1
	
	pop		r14
	pop		r13
	pop		r12

	dec		r15
	test	r15, r15
	jnz		.main_loop
	
	mov		rax, r14
.failure
	pop		rbx
	pop		r15
	pop		r14
	pop		r13
	pop		r12
	leave
	ret
