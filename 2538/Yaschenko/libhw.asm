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
	mov rax, [rdi + Matrix.rows]
	ret

;; unsigned int matrixGetCols(Matrix matrix);
;;
;; Returns number of columns in matrix A.
;; Takes:
;;	* RDI: pointer to matrix A.
;; Returns:
;;	* RAX: number of columns in matrix A.
matrixGetCols:
	mov rax, [rdi + Matrix.cols]
	ret

;; Returns pointer element in A'th row B'th column in matrix M.
;; Takes:
;;	* RDI: pointer to matrix M.
;;	* RSI: number of row A.
;;	* RDX: number of column B.
;; Returns:
;;	* RAX: pointer to M[A][B].
loadAddress:
	imul rsi, [rdi + Matrix.colsAligned]				; Calculate index of [A][B]'th element as
	add rsi, rdx						; A * M.cols + B
	shl rsi, 2						; Multiply index by 4 (sizeof float) to get element's offset. 
	mov rax, [rdi + Matrix.data]				; Calculate element's actual address.
	add rax, rsi
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
	call loadAddress
	movss xmm0, [rax]
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
	call loadAddress
	movss [rax], xmm0
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
	push rdi

	mov rsi, [rdi + Matrix.cols]
	mov rdi, [rdi + Matrix.rows]
	call matrixNew
	pop rdi

	push rax

	mov rcx, [rdi + Matrix.rowsAligned]
	imul rcx, [rdi + Matrix.colsAligned]
	sub rcx, 4

	unpcklps xmm0, xmm0					; Make xmm0 store vector of four K values.
	unpcklps xmm0, xmm0

	mov rdi, [rdi + Matrix.data]
	mov rax, [rax + Matrix.data]

	.loop
		movups xmm1, [rdi + 4 * rcx]
		mulps xmm1, xmm0
		movups [rax + 4 * rcx], xmm1
		sub rcx, 4
		jns .loop

	pop rax
	ret

;; Matrix matrixAdd(Matrix a, Matrix b);
;;
;; Multiplies matrix A by matrix B and returns pointer to resulting
;; matrix C. If A's and B's dimensions are not equal, returns 0.
;; Takes:
;;	* RDI: pointer to matrix A.
;;	* RSI: pointer to matrix B.
;; Returns:
;;	* RAX: pointer to resulting matrix C.
matrixAdd:
	push rdi
	push rsi

	mov rax, [rdi + Matrix.rows]
	cmp rax, [rsi + Matrix.rows]
	jne .bad_dims

	mov rax, [rdi + Matrix.cols]
	cmp rax, [rsi + Matrix.cols]
	jne .bad_dims

	mov rsi, [rdi + Matrix.cols]
	mov rdi, [rdi + Matrix.rows]
	call matrixNew

	pop rsi
	pop rdi

	mov rcx, [rdi + Matrix.rowsAligned]
	imul rcx, [rdi + Matrix.colsAligned]
	sub rcx, 4

	mov r8, [rdi + Matrix.data]
	mov r9, [rsi + Matrix.data]
	mov r10, [rax + Matrix.data]

.loop_add:
	movups xmm0, [r8 + 4 * rcx]
	addps xmm0, [r9 + 4 * rcx]
	movups [r10 + 4 * rcx], xmm0
	sub rcx, 4
	jns .loop_add

	ret

.bad_dims:
	pop rsi
	pop rdi
	xor rax, rax
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
	mov rax, [rdi + Matrix.cols]
	cmp rax, [rsi + Matrix.rows]
	jne .bad_dims

	push rdi
	mov rdi, rsi
	call matrixTranspose
	mov rsi, rax
	pop rdi

	push rdi
	push rsi
	mov rdi, [rdi + Matrix.rows]
	mov rsi, [rsi + Matrix.rows]		; rows since it has been transposed
	call matrixNew
	mov rdx, rax
	pop rsi
	pop rdi

	mov r8, [rdi + Matrix.rowsAligned]
	mov r9, [rdi + Matrix.colsAligned]
	mov r10, [rsi + Matrix.rowsAligned]

	mov rdi, [rdi + Matrix.data]
	mov rsi, [rsi + Matrix.data]

	push r12
	push r13
	push r14

	xor r11, r11
.loop_i:
	xor r13, r13
.loop_j:
	mov r12, r11
	imul r12, r9
	imul r12, 4
	add r12, rdi

	mov r14, r13
	imul r14, r9
	imul r14, 4
	add r14, rsi

	xor rcx, rcx
	xorps xmm0, xmm0
.loop_k:
	movups xmm1, [r12]
	mulps xmm1, [r14]
	haddps xmm1, xmm1
	haddps xmm1, xmm1
	addss xmm0, xmm1

	add r12, 16
	add r14, 16
	add rcx, 4
	cmp rcx, r9
	jne .loop_k

	movss [rdx], xmm0
	add rdx, 4

	inc r13
	cmp r13, r10
	jne .loop_j

	inc r11
	cmp r11, r8
	jne .loop_i

	pop r14
	pop r13
	pop r12

	ret

.bad_dims:
	xor rax, rax
	ret


matrixMull:
	mov rax, [rdi + Matrix.cols]
	cmp rax, [rsi + Matrix.rows]
	jne .bad_dims

	push rdi
	push rsi				; stack: *B | *A | ...

	mov rdi, [rdi + Matrix.rows]
	mov rsi, [rsi + Matrix.cols]
	call matrixNew

	push rax				; stack: *C | *B | *A | ...

	mov rdi, [rsp + 16]
	mov rsi, [rsp + 8]
	xchg rsi, rdi
	call matrixTranspose
	mov rdi, [rsp + 16]
	mov rsi, [rsp + 8]

	push rax				; stack: *B^T | *C | *B | *A | ...

	mov rax, [rsp + 8]
	mov r11, [rax + Matrix.rowsAligned]
	mov r12, [rax + Matrix.colsAligned]
	mov rax, [rsp]

	mov rsi, rax				; RSI - B^T

	mov rdi, [rdi + Matrix.data]
	mov rsi, [rsi + Matrix.data]
	mov rax, [rsp + 8]
	mov rax, [rax + Matrix.data]

	xor r8, r8 				; i loop counter
.loop_i:
	xor r9, r9				; j loop counter
	mov r15, rsi
.loop_j:
	lea r14, [r8 * 4]
	imul r14, r12
	add r14, rdi				; r14 points to current row in matrix A
	xor r10, r10				; k loop conter

	xorps xmm0, xmm0			; sum aggregator
.loop_k:
	movups xmm1, [r14]
	mulps xmm1, [r15]

	haddps xmm1, xmm1			; add four 
	haddps xmm1, xmm1

	addps xmm0, xmm1
	add r14, 16
	add r15, 16
	add r10, 4
	cmp r10, r12				; columns end
	jne .loop_k

	movss [rax], xmm0
	add rax, 4
	inc r9
	cmp r9, r12
	jne .loop_j

	inc r8
	cmp r8, r11				; rows end
	jne .loop_i

	mov rdi, [rsp]				; resotre matrix C pointer
	call matrixDelete 

	pop rax
	add rsp, 16				; remove pointers to matrix A and B on stack.
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



;; Transposes matrix A.
;; Takes:
;;	* RDI: pointer to matrix A.
matrixTransposeInplace:
	mov rcx, [rdi + Matrix.rowsAligned]
	imul rcx, [rdi + Matrix.colsAligned]		; RCX - number of elements in matrix.
	mov [count], rcx
	
	mov r8, [rdi + Matrix.data]			; R8 - beginning of elements array. 
	lea r9, [r8 + rcx]				; R9 - end of elements array
	mov [first], r8
	mov [last], r9

	mov rax, rcx					; MN1 = (last - first) / ROWS as RCX / ROWS
	xor rdx, rdx					; RDX:RAX / ROWS
	mov r11, [rdi + Matrix.rowsAligned]
	idiv r11
	mov [mn1], rax

	mov rax, [count]				; N = (last - first - 1)
	dec rax
	mov [n], rax
;; Allocate bitset to store already swapped elements.
	push rdi					; Store registers before calloc
	push rcx
	push r8
	push r9
	push r10

	mov rdi, rcx
	add rdi, 31
	shr rdi, 5
	mov rsi, 4
	call calloc

	pop r10						; Restore registers
	pop r9
	pop r8
	pop rcx
	pop rdi

	push rax					; Save pointer to bitset.
							; Stack: *BITSET | ...

	mov [cycle], r8					; R10 - curent element loop counter.

.loop_elem:
	add qword [cycle], 4

	mov r11, [cycle]
	sub r11, r8			; r11 - index of cell
	shl r11, 2			; div by 4 to calc index

	mov r12, r11			; r12 = r11 / 32
	shr r12, 5

	mov r13, r11			; r13 = r11 % 32
	and r13, 0x1f			; r13 - index of bit in cell at r12
	bts [rax + r12], r13		; test and set visited bit
	mov r12, 0
	adc r12, 0			; get bit from CF

	cmp r12, 1
	je .loop_elem			; already visited, continue with next element.

	mov r11, [cycle]		; r11 - a
	sub r11, [first]
	shl r11, 2			; div by sizeof float to calc real index
	mov [a], r11

.loop_swap:
	cmp r11, [rsp]
	je .calc_a_done

	imul r11, [n]

	push rax
	xor rdx, rdx
	mov rax, r11
	mov r13, [mn1]
	idiv r13
	mov r11, rdx			; r11 = (a * n) % mn
	mov [a], r11

.calc_a_done:
	mov eax, dword [first + r11]		; swap
	mov edx, dword [cycle]
	mov [first + r11], edx
	mov [cycle], eax

	mov rax, [first]
	add rax, [a]
	cmp [cycle], rax
	jne .loop_swap

	;pop rax

	mov rax, [last]
	cmp [cycle], rax
	jne .loop_elem

	push rdi
	mov rdi, [esp]
	call free
	pop rdi

	add esp, 8
	ret



