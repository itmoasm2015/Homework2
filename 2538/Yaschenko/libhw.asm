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

;; Matrix is stored in struct with 5 members: ROWS, COLS, DATA, ROWS_ALIGNED and COLS_ALIGNED.
;; ROWS and COLS store real rows and cols count.
;; ROWS_ALIGNED and COLS_ALIGNED store aligned to next 4-divisible number to make it easy to
;; work with SSE instructions, which process by 4 numbers at once.
;; DATA stores pointer to memory, allocated with calloc.
;; Elements in DATA are stored as in 2-dimensional array, so element in i'th row j'th column
;; has index i * COLS + j in DATA array.
struc Matrix
	.rows:		resq 1				; Rows count in matrix.
	.cols:		resq 1				; Columns count in matrix.
	.data:		resq 1				; Pointer to matrix elements.
	.rowsAligned:	resq 1				; Aligned to 4 (up) rows count.
	.colsAligned:	resq 1				; Aligned to 4 (up) columns count.
endstruc

;; Performs x = ((x + 3) / 4) * 4.
;; Finds next divisible by 4 number.
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

; Allocate memory for Matrix struct.
	mov	rdi, 1					; count = 1
	mov	rsi, Matrix_size			; sizeof(Matrix)
	call	calloc
	mov	rdx, rax

	pop	rsi
	pop	rdi

; Fill matrix struct's ROWS and COLS members.
	mov	[rdx + Matrix.rows], rdi
	mov	[rdx + Matrix.cols], rsi

; Calc aligned to 4 matrix dimensions.
	align_4	rdi
	align_4	rsi

; Fill matrix struct's ROWS_ALIGNED and COLS_ALIGNED members.
	mov	[rdx + Matrix.rowsAligned], rdi
	mov	[rdx + Matrix.colsAligned], rsi

	push	rdx

; Allocate memory for elements of matrix.
	imul	rdi, rsi				; ROWS_ALIGNED * COLS_ALIGNED elements.
	mov	rsi, 4					; sizeof(float) - size of one element of matrix.
	call	calloc

; Fill matrix struct's DATA member with newly allocated memory (from RAX).
	pop	rdx
	mov	[rdx + Matrix.data], rax

; Restore pointer to newly allocated matrix to RAX and return.
	mov	rax, rdx

	ret


;; void matrixDelete(Matrix matrix);
;;
;; Deletes matrix.
;; Takes:
;;	* RDI: pointer to matrix to be deleted.
matrixDelete:
; Free Matrix.data memory.
	push	rdi
	mov	rdi, [rdi + Matrix.data]
	call	free
; Free matrix struct memory.
	pop	rdi
	call	free
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
;; Returns element in i'th row j'th column in matrix M.
;; Takes:
;;	* RDI: pointer to matrix M.
;;	* RSI: number of row i.
;;	* RDX: number of column j.
;; Returns:
;;	* XMM0: element in M[i][j].
matrixGet:
; Calculate index of [i][j] element as Matrix.cols * i + j.
	imul	rsi, [rdi + Matrix.colsAligned]
	add	rsi, rdx
; Multiply by sizeof(float) to get [i][j] element's offset.
	shl	rsi, 2
; Calculate real address of [i][j] element.
	add	rsi, [rdi + Matrix.data]
; Fill return value.
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
; Calculate index of [i][j] element as Matrix.cols * i + j.
	imul	rsi, [rdi + Matrix.colsAligned]
	add	rsi, rdx
; Multiply by sizeof(float) to get [i][j] element's offset.
	shl	rsi, 2
; Calculate real address of [i][j] element.
	add	rsi, [rdi + Matrix.data]
; Fill return value.
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

; Allocate new matrix with same dimensions.
	mov	rsi, [rdi + Matrix.cols]
	mov	rdi, [rdi + Matrix.rows]
	call	matrixNew

	pop	rdi

; Make RDX hold total number of elements.
	mov	rdx, [rdi + Matrix.rowsAligned]
	imul	rdx, [rdi + Matrix.colsAligned]

; Make XMM0 be a vector of 4 values K (K:K:K:K).
	unpcklps xmm0, xmm0
	unpcklps xmm0, xmm0

; RSI holds address of source matrix to be scaled.
; RDI holds address of dest matrix. 
	mov	rsi, [rdi + Matrix.data]
	mov	rdi, [rax + Matrix.data]
; RCX holds number of already scaled elements.
	xor	rcx, rcx

.loop:
	movups	xmm1, [rsi]
	mulps	xmm1, xmm0
	movups	[rdi], xmm1
	add	rsi, 4 * 4				; Move RSI to next 4 elements.
	add	rdi, 4 * 4				; Move RDI to next 4 elements.
	add	rcx, 4
	cmp	rcx, rdx
	jne	.loop

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
; Check if matrix A and matrix B have equal number of rows to perform addition.
	mov	rax, [rdi + Matrix.rows]
	cmp	rax, [rsi + Matrix.rows]
	jne	.bad_dims

; Check if matrix A and matrix B have equal number of columns to perform addition.
	mov	rax, [rdi + Matrix.cols]
	cmp	rax, [rsi + Matrix.cols]
	jne	.bad_dims

	push	rdi
	push	rsi

; Allocate matrix for result.
	mov 	rsi, [rdi + Matrix.cols]
	mov 	rdi, [rdi + Matrix.rows]
	call	matrixNew

	pop	rsi
	pop	rdi

; RCX holds total number of elements in matrix C. 
	mov	rcx, [rdi + Matrix.rowsAligned]
	imul	rcx, [rdi + Matrix.colsAligned]

	mov r8,	[rdi + Matrix.data]			; R8  points to current 4 elements in matrix A.
	mov r9,	[rsi + Matrix.data]			; R9  points to current 4 elements in matrix B.
	mov r10,[rax + Matrix.data]			; R10 points to current 4 elements in matrix C.

	xor rdx, rdx					; Number of already processed elements.

.loop_add:
; Sum up next 4 elements from matrix A and B and store them to C.
	movups	xmm0, [r8]
	addps	xmm0, [r9]
	movups	[r10], xmm0

	add	rdx, 4
; Move pointers to current elements by 4.
	add	r8,  4 * 4
	add	r9,  4 * 4
	add	r10, 4 * 4

	cmp	rdx, rcx
	jne	.loop_add
	
.end_loop_add:
	ret

.bad_dims:
; Since matrices A and B can't be sumed, return 0. 
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
; Check if matrix A and matrix B have valid dimensions to perform multiplication.
	mov	rax, [rdi + Matrix.cols]
	cmp	rax, [rsi + Matrix.rows]
	jne	.bad_dims

; Transpose matrix B to make multiplication easier and faster (linear memory access).
	push	rdi
	mov	rdi, rsi
	call	matrixTranspose
	mov	rsi, rax
	pop	rdi

	push	rax					; Save pointer to transposed matrix to delete it later.

; Allocate matrix C to store result of multiplication.
	push	rdi
	push	rsi
	mov	rdi, [rdi + Matrix.rows]
	mov	rsi, [rsi + Matrix.rows]		; Rows instead of cols since matrix has been transposed.
	call	matrixNew
	mov	rdx, rax
	pop	rsi
	pop	rdi

; R8, R9 and R10 hold borders for multiplication cycles.
	mov	r8, [rdi + Matrix.rowsAligned]
	mov	r9, [rdi + Matrix.colsAligned]
	mov	r10, [rsi + Matrix.rowsAligned]

; RDI, RSI and RDX hold pointers to current elements of matrices A, B and C respectively.
	mov	rdi, [rdi + Matrix.data]
	mov	rsi, [rsi + Matrix.data]

	mov	rax, rdx
	mov	rdx, [rax + Matrix.data]

; Save callee-saved registers.
	push	r12
	push	r13
	push	r14

	xor	r11, r11				; R11 holds i loop counter.
.loop_i:
	xor	r13, r13				; R12 holds j loop counter.
.loop_j:
; R12 holds address of next 4 elements from matrix A. 
	mov	r12, r11
	imul	r12, r9
	imul	r12, 4
	add	r12, rdi

; R14 holds address of next 4 elements from matrix B.
	mov	r14, r13
	imul	r14, r9
	imul	r14, 4
	add	r14, rsi

	xor	rcx, rcx				; RCX holds k loop counter.
	xorps	xmm0, xmm0				; XMM0 accumulates sum of elements' multiplications. 
.loop_k:
; Multiply next 4 elements from matrix A and matrix B.
	movups	xmm1, [r12]
	mulps	xmm1, [r14]
; Sum them up.
	haddps	xmm1, xmm1
	haddps	xmm1, xmm1
; And add to accumulator XMM0.
	addss	xmm0, xmm1

; Move pointers to next 4 elements.
	add	r12, 4 * 4
	add	r14, 4 * 4
	add	rcx, 4
	cmp	rcx, r9
	jne	.loop_k

; Store accumulated sum to current element of matrix C.
	movss	[rdx], xmm0
	add	rdx, 4

; Check if we processed current column.
	inc	r13
	cmp	r13, r10
	jne	.loop_j

; Check if we processed current row.
	inc	r11
	cmp	r11, r8
	jne	.loop_i

; Restore callee-saved registers.
	pop	r14
	pop	r13
	pop	r12

; Delete transposed matrix B.
	pop	rdi
	push	rax
	call	matrixDelete
	pop	rax

	ret

.bad_dims:
; Since matrices can't be multiplied return 0.
	xor rax, rax
	ret


;; Transposes matrix A and returns pointer to resulting matrix B.
;; Takes:
;;	* RDI: pointer to matrix A.
;; Returns:
;;	* RAX: pointer to resulting matrix B.
matrixTranspose:
	push rdi

; Allocate new matrix with flipped dimensions.
	mov rdx, rdi
	mov rsi, [rdx + Matrix.rows]
	mov rdi, [rdx + Matrix.cols]

	push rdx
	push rsi
	push rdi

	call matrixNew

	pop rdi
	pop rsi
	pop rdx

	mov rdx, [rsp]
	mov rsi, [rdx + Matrix.rowsAligned]
	mov rdi, [rdx + Matrix.colsAligned]
	mov rdx, [rdx + Matrix.data]			; RDX holds pointer to transposed matrix's data.

	xor r8, r8					; R8 holds i loop counter.
.loop_i:
	xor r9, r9					; R9 holds j loop counter.
.loop_j:
; R10 holds index of next 4 elements from matrix A. 
	mov r10, r9
	imul r10, rsi
	add r10, r8
; Multiply by sizeof(float).
	shl r10, 2
; Calculate real memory address.
	add r10, [rax + Matrix.data]

; Transpose current elements.
	movss xmm0, [rdx]
	movss [r10], xmm0

; Move pointer to next elements.
	add rdx, 4
; Check if row processed.
	inc r9
	cmp r9, rdi
	jne .loop_j

; Check if column processed.
	inc r8
	cmp r8, rsi
	jne .loop_i

	pop rdi
	ret
