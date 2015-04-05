extern calloc
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
global matrixTranspose

section .text

struc Matrix
	.rows:		resq 1				; Rows count in matrix.
	.cols:		resq 1				; Columns count in matrix.
	.data:		resq 1				; Pointer to matrix elements.
	.rowsAligned:	resq 1				; Aligned to 4 (up) rows count.
	.colsAligned:	resq 1				; Aligned to 4 (up) columns count.
endstruc

%macro align_4 1
	add	%1, 3
	shr	%1, 2
	shl	%1, 2
%endmacro


;; Matrix matrixNew(unsigned int rows, unsigned int cols);
;;
;; Creates new matrix with A rows and B columns.
;; Takes:
;;	* RDI: number of rows A.
;;	* RSI: number of columns B.
;; Returns:
;;	* RAX: pointer to newly created matrix.
matrixNew:
	push	rdi
	push	rsi

	mov	rdi, 1
	mov	rsi, Matrix_size
	call	calloc
	mov	rdx, rax

	pop	rsi
	pop	rdi

	mov	[rdx + Matrix.rows], rdi
	mov	[rdx + Matrix.cols], rsi

	align_4	rdi
	align_4	rsi

	mov	[rdx + Matrix.rowsAligned], rdi
	mov	[rdx + Matrix.colsAligned], rsi

	push	rdx

	imul	rdi, rsi
	mov	rsi, 4
	call	calloc

	pop	rdx
	mov	[rdx + Matrix.data], rax
	mov	rax, rdx

	ret


;; void matrixDelete(Matrix matrix);
;;
;; Deletes matrix.
;; Takes:
;;	* RDI: pointer to matrix to be deleted.
matrixDelete:
	push	rdi
	mov	rdi, [rdi + Matrix.data]
	call	free						; Delete data.
	pop	rdi
	call	free						; Delete matrix struct.
	ret


;; unsigned int matrixGetRows(Matrix matrix);
;;
;; Returns number of rows in matrix A.
;; Takes:
;;	* RDI: pointer to matrix A.
;; Returns:
;;	* RAX: number of rows in matrix A.
matrixGetRows:
	mov	rax, [rdi + Matrix.rows]
	ret


;; unsigned int matrixGetCols(Matrix matrix);
;;
;; Returns number of columns in matrix A.
;; Takes:
;;	* RDI: pointer to matrix A.
;; Returns:
;;	* RAX: number of columns in matrix A.
matrixGetCols:
	mov	rax, [rdi + Matrix.cols]
	ret


;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;;
;; Returns element in A'th row B'th column in matrix M.
;; Takes:
;;	* RDI: pointer to matrix M.
;;	* RSI: number of row A.
;;	* RDX: number of column B.
;; Returns:
;;	* XMM0: element in M[A][B].
matrixGet:
	imul	rsi, [rdi + Matrix.colsAligned]
	add	rsi, rdx
	shl	rsi, 2
	add	rsi, [rdi + Matrix.data]
	movss	xmm0, [rsi]
	ret


;; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;;
;; Sets element in A'th row B'th column in matrix M with new value V.
;; Takes:
;;	* RDI: pointer to matrix M.
;;	* RSI: number of row A.
;;	* RDX: number of column B.
;;	* XMM0: new value V.
matrixSet:
	imul	rsi, [rdi + Matrix.colsAligned]
	add	rsi, rdx
	shl	rsi, 2
	add	rsi, [rdi + Matrix.data]
	movss	[rsi], xmm0
	ret


;; Matrix matrixScale(Matrix matrix, float k);
;;
;; Scales source matrix M by scalar K and returns pointer to new
;; matrix containing result.
;; Takes:
;;	* RDI: pointer to matrix M.
;;	* XMM0: scalar K.
;; Returns:
;;	* RAX: pointer to resulting matrix.
matrixScale:
	push	rdi

	mov	rsi, [rdi + Matrix.cols]
	mov	rdi, [rdi + Matrix.rows]
	call	matrixNew

	pop	rdi

	mov	rdx, [rdi + Matrix.rowsAligned]
	imul	rdx, [rdi + Matrix.colsAligned]

	unpcklps xmm0, xmm0					; Make xmm0 store vector of four K values.
	unpcklps xmm0, xmm0

	mov	rsi, [rdi + Matrix.data]
	mov	rdi, [rax + Matrix.data]
	xor	rcx, rcx

.loop:
	movups	xmm1, [rsi]
	mulps	xmm1, xmm0
	movups	[rdi], xmm1
	add	rsi, 4 * 4
	add	rdi, 4 * 4
	add	rcx, 4
	cmp	rcx, rdx
	je	.return

.return:
	ret


;; Matrix matrixAdd(Matrix a, Matrix b);
;;
;; Adds matrix B to matrix A and returns pointer to resulting
;; matrix C. If A's and B's dimensions are not equal, returns 0.
;; Takes:
;;	* RDI: pointer to matrix A.
;;	* RSI: pointer to matrix B.
;; Returns:
;;	* RAX: pointer to resulting matrix C.
matrixAdd:
	mov	rax, [rdi + Matrix.rows]
	cmp	rax, [rsi + Matrix.rows]
	jne	.bad_dims

	mov	rax, [rdi + Matrix.cols]
	cmp	rax, [rsi + Matrix.cols]
	jne	.bad_dims

	push	rdi
	push	rsi

	mov 	rsi, [rdi + Matrix.cols]
	mov 	rdi, [rdi + Matrix.rows]
	call	matrixNew

	pop	rsi
	pop	rdi

	mov	rcx, [rdi + Matrix.rowsAligned]
	imul	rcx, [rdi + Matrix.colsAligned]

	mov r8,	[rdi + Matrix.data]
	mov r9,	[rsi + Matrix.data]
	mov r10,[rax + Matrix.data]

	xor rdx, rdx

.loop_add:
	movups	xmm0, [r8]
	addps	xmm0, [r9]
	movups	[r10], xmm0
	add	rdx, 4
	add	r8,  4 * 4
	add	r9,  4 * 4
	add	r10, 4 * 4
	cmp	rdx, rcx
	jne	.loop_add
	
.end_loop_add:
	ret

.bad_dims:
	xor	rax, rax
	ret


;; Matrix matrixMul(Matrix a, Matrix b);
;;
;; Multplies matrix A by matrix B and returns pointer to resulting
;; matrix C. If A's and B's dimensions are bad for multiplying, return 0.
;; Takes:
;;	* RDI: pointer to matrix A.
;;	* RSI: pointer to matrix B.
;; Returns:
;;	* RAX: pointer to resulting matrix C.
matrixMul:
	mov	rax, [rdi + Matrix.cols]
	cmp	rax, [rsi + Matrix.rows]
	jne	.bad_dims

	push	rdi
	mov	rdi, rsi
	call	matrixTranspose
	mov	rsi, rax
	pop	rdi

	push	rdi
	push	rsi
	mov	rdi, [rdi + Matrix.rows]
	mov	rsi, [rsi + Matrix.rows]		; rows since it has been transposed
	call	matrixNew
	mov	rdx, rax
	pop	rsi
	pop	rdi

	mov	r8, [rdi + Matrix.rowsAligned]
	mov	r9, [rdi + Matrix.colsAligned]
	mov	r10, [rsi + Matrix.rowsAligned]

	mov	rdi, [rdi + Matrix.data]
	mov	rsi, [rsi + Matrix.data]

	mov	rax, rdx
	mov	rdx, [rax + Matrix.data]

	push	r12
	push	r13
	push	r14

	xor	r11, r11
.loop_i:
	xor	r13, r13
.loop_j:
	mov	r12, r11
	imul	r12, r9
	imul	r12, 4
	add	r12, rdi

	mov	r14, r13
	imul	r14, r9
	imul	r14, 4
	add	r14, rsi

	xor	rcx, rcx
	xorps	xmm0, xmm0
.loop_k:
	movups	xmm1, [r12]
	mulps	xmm1, [r14]
	haddps	xmm1, xmm1
	haddps	xmm1, xmm1
	addss	xmm0, xmm1

	add	r12, 4 * 4
	add	r14, 4 * 4
	add	rcx, 4
	cmp	rcx, r9
	jne	.loop_k

	movss	[rdx], xmm0
	add	rdx, 4

	inc	r13
	cmp	r13, r10
	jne	.loop_j

	inc	r11
	cmp	r11, r8
	jne	.loop_i

	pop r14
	pop r13
	pop r12

	ret

.bad_dims:
	xor rax, rax
	ret


;; Transposes matrix A and returns pointer to resulting matrix B.
;; Takes:
;;	* RDI: pointer to matrix A.
;; Returns:
;;	* RAX: pointer to resulting matrix B.
matrixTranspose:
	push rdi

	mov rbx, rdi
	mov rsi, [rbx + Matrix.rows]
	mov rdi, [rbx + Matrix.cols]

	push rbx
	push rsi
	push rdi

	call matrixNew

	pop rdi
	pop rsi
	pop rbx

	mov rbx, [rsp]
	mov rsi, [rbx + Matrix.rowsAligned]
	mov rdi, [rbx + Matrix.colsAligned]
	mov rbx, [rbx + Matrix.data]

	xor r8, r8
.loop_i:
	xor r9, r9
.loop_j:
	mov r10, r9
	imul r10, rsi
	add r10, r8
	shl r10, 2
	movss xmm0, [rbx]
	add r10, [rax + Matrix.data]
	movss [r10], xmm0
	add rbx, 4
	inc r9
	cmp r9, rdi
	jne .loop_j

	inc r8
	cmp r8, rsi
	jne .loop_i

	pop rdi
	ret
