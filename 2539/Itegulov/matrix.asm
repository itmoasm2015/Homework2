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
global matrixTranspose

extern aligned_alloc
extern free

section .text

; Matrices are stored this way:
;		8 bytes - row count
;		8 bytes - column count
;		row * column + some more bytes - big array describing matrix itself
; Matrices are aligned by 16 bytes.

%macro roundToFour 1 ; rounds up to the nearest value, that divides by 4
	add %1, 3
	and %1, ~3
%endmacro

%macro matrixSize 1
  ; Gets matrix's real size (it can be different from specified initially, because
  ; it's aligned by 16)
  ; Argument shouldn't be rsi
  ; Result'll be written to rax
	push rsi

	mov rsi, [%1 + 8]
	roundToFour rsi

	mov rax, [%1]
	roundToFour rax

	mul rsi

	pop rsi
%endmacro

; matrixNew(unsigned int rows, unsigned int cols)
; Creates matrix with specified rows and cols, filled by zeros
matrixNew:
	enter 0, 0

	mov rax, rdi
	roundToFour rax

	mov rdx, rsi
	roundToFour rdx

	mul rdx ; calculates size of matrix
	mov rdx, rax ; stores it, because we'll spoil it in following lines
	sal rax, 2 ; mul by 4 (size of float)
	add rax, 16 ; 16 bytes for header (8 for count of rows and 8 for cols)

	push rdi
	push rsi
	push rdx

	mov rdi, 16 ; we need to align size by 16
	mov rsi, rax
	call aligned_alloc
	test rax, rax ; if couldn't allocate memory
	jz .return
	mov r8, rax

	pop rdx
	pop rsi
	pop rdi

	mov [rax], rdi ; write count of rows
	mov [rax + 8], rsi ; write count of cols

	mov rcx, rdx ; rcx now contains size of matrix, which we stored in rdx before
	lea rdi, [rax + 16]
	xor rax, rax

	rep stosd

	mov rax, r8 ; we've stored pointer to matrix in r8
.return
	leave
	ret

; void matrixDelete(Matrix m)
; Frees memory, which was allocated for storaging specified matrix
matrixDelete:
	call free
	ret

; unsigned long long matrixGetRows(Matrix m)
; Gets specified matrix's rows count
matrixGetRows:
	mov rax, [rdi]
	ret

; unsigned long long matrixGetCols(Matrix m)
; Gets specified matrix's cols count
matrixGetCols:
	mov rax, [rdi + 8]
	ret

; float matrixGet(Matrix m, unsigned long long row, unsigned long long col)
; Gets specified matrix's element, which is located at specified row and col
; Row and col must be valid for this matrix. UB will happen otherwise
matrixGet:
	enter 0, 0
	mov rcx, [rdi + 8]
	roundToFour rcx ; gets real number of columns

	mov r8, rdx

	mov rax, rsi
	mul rcx
	add rax, r8 ; calculates index

	movss xmm0, [rdi + 16 + rax * 4]
	leave
	ret

; void matrixSet(Matrix m, unsigned long long row, unsigned long long col, float
; value)
; Sets specified matrix's element, which is located at specified row and col to
; value. Row and col must be valid for this matrix. UB will happen otherwise
matrixSet:
	enter 0, 0
	mov rcx, [rdi + 8]
	roundToFour rcx ; gets real number of columns

	mov r8, rdx

	xor rdx, rdx
	mov rax, rsi
	mul rcx
	add rax, r8 ; calculates index

	movss [rdi + 16 + rax * 4], xmm0
	leave
	ret

; Matrix matrixCopy(Matrix)
; Creates and returns new matrix, which contains exactly the same data as
; specified matrix
matrixCopy:
	enter 0, 0

	push rdi
	matrixSize rdi
	pop rdi

	mov rcx, rax ; calculated initial matrix size

	push rdi
	push rcx

	mov rsi, [rdi + 8]
	mov rdi, [rdi]
	call matrixNew ; created zero-initialized matrix, with necessary dimensions

	pop rcx
	pop rdi

	lea rsi, [rdi + 16]
	lea rdi, [rax + 16]
	rep movsd ; copying data from initial matrix to created matrix

	leave ; rax is pointing to created matrix after calling matrixNew
	ret

; Matrix matrixScale(Matrix m, float scale)
; Creates and returns new matrix, which contains exactle the same data as
; specified matrix, but multiplied by scale
matrixScale:
	enter 0, 0
	push rbx

	sub rsp, 4
	and rsp, ~0xf ; align to 16 byte for pshufd
	movss [rsp], xmm0

	push rdi

	call matrixCopy

	push rax
	matrixSize rax
	mov rcx, rax
	pop rax

	pop rdi

	pshufd xmm0, [rsp], 0 ; load stored scale argument in all four cells

.loop
	sub rcx, 4
	movaps xmm1, [rax + rcx * 4 + 16]
	mulps xmm1, xmm0
	movaps [rax + rcx * 4 + 16], xmm1
	test rcx, rcx
	jnz .loop

	pop rbx
	leave
	ret

; Matrix matrixAdd(Matrix a, Matrix b)
; Creates and returns new matrix, which contains sum of specfied matrices.
; If dimensions of matrices don't coincide, then returns 0.
matrixAdd:
	enter 0, 0
	xor eax, eax

	mov rdx, [rsi] ; checking for matrices' dimension equality
	cmp rdx, [rdi]
	jne .return

	mov rdx, [rsi + 8]
	cmp rdx, [rdi + 8]
	jne .return

	push rsi ; here we just copying matrix and recalculating it's size

	call matrixCopy

	push rax
	matrixSize rax
	mov rcx, rax
	pop rax

	pop rsi

.loop
	sub rcx, 4
	movaps xmm0, [rax + rcx * 4 + 16]
	addps xmm0, [rsi + rcx * 4 + 16]
	movaps [rax + rcx * 4 + 16], xmm0
	test rcx, rcx
	jnz .loop

.return
	leave
	ret

; Matrix matrixTranspose(Matrix a)
; a - Matrix NxM
; Creates and returns new matrix: a^T - Matrix MxN
matrixTranspose:
	enter 0, 0

	push rdi
	mov rsi, [rdi]
	mov rdi, [rdi + 8]
	call matrixNew
	pop rdi

	mov r8, [rax + 8] ; cols count of new matrix - N
	roundToFour r8
	mov r9, [rax] ; rows count of matrix - M
	roundToFour r9
	lea r10, [rdi + 16] ; r10 points to cells of initial matrix

	xor rcx, rcx ; rcx - number of column (< N)
.loop_cols
	lea r11, [rax + rcx * 4 + 16]
	xor rdx, rdx
.loop_rows ; rdx - number of row (< M)

	movups xmm0, [r10]

	%macro store 0 ; writes one float xmm0 to [r11] and moves r11-pointer
								 ; at next row
		movss [r11], xmm0
		lea r11, [r11 + r8 * 4]
	%endmacro

	store ; we need to store 4 floats from 4 consecutive rows
	psrldq xmm0, 4
	store
	psrldq xmm0, 4
	store
	psrldq xmm0, 4
	store

	lea r10, [r10 + 16]
	lea rdx, [rdx + 4]
	cmp rdx, r9
	jb .loop_rows

	inc rcx
	cmp rcx, r8
	jb .loop_cols

	leave
	ret

; Matrix matrixMul(Matrix a, Matrix b)
; Creates and returns new matrix, containing multiplication of specified
; matrices. If dimensions of matrices don't allow to multiplicate them,
; then 0 will be returned.
; a - Matrix NxM
; b - Matrix MxK
; Returns 0 if couldn't allocate memory for new matrix
matrixMul:
	enter 0, 0
	xor eax, eax

	mov rdx, [rsi] ; checking for matrices' dimension on satisfiability
	cmp rdx, [rdi + 8]
	jne .return
	push rbx

	push rsi
	push rdi
	mov rdi, rsi
	call matrixTranspose ; transpose second matrix for easy multiplication
	pop rdi
	pop rsi
	push rdi
	push rax
	mov rdi, [rdi]
	mov rsi, [rsi + 8]
	call matrixNew ; creates result matrix
	test rax, rax
	jz .failure ; if couldn't allocate memory for new matrix
	lea rcx, [rax + 16]
	pop rsi
	pop rdi
	push rsi

	mov r8, [rdi]
	roundToFour r8
	mov r11, [rsi] ; temporary variable for storaging 'K'
	roundToFour r11
	mov r10, [rdi + 8]
	roundToFour r10
	lea rdi, [rdi + 16]
	lea rsi, [rsi + 16]
	mov rdx, rsi ; temporary variable for storaging cells of 'b'
	mov rbx, r10 ; temporary variable for storaging 'M * 4'
	sal rbx, 2
.loop_row
		mov rsi, rdx
		mov r9, r11
		.loop_col
			xor r10, r10 ; r10 is row offset
			xorps xmm0, xmm0 ; xmm0 - accumulator
			.loop_inner
				movups xmm1, [rdi + r10]
				movups xmm2, [rsi + r10]
				dpps xmm1, xmm2, 0xF1 ; calculates dot product
															; 0xF1 is full 4-bit-mask at high and 1 at low
				addss xmm0, xmm1
				add r10, 16
				cmp r10, rbx
			jne .loop_inner
			add rsi, rbx ; goes to next row at second matrix
			movss [rcx], xmm0 ; write result to corresponding cell at result matrix
			add rcx, 4
			dec r9
		jnz .loop_col
		add rdi, rbx ; goes to next row at first matrix
		dec r8
	jnz .loop_row
	pop rdi
	push rax
	call matrixDelete ; delete transponated matrix
	pop rax

	pop rbx
.return
	leave
	ret
.failure
	pop rax
	pop rdi
	pop rbx
	leave
	ret
