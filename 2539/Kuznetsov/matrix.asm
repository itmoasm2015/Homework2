

; Matrices are stored as following in pseudo-C syntax, with (a $ b) denoting minimum number c such that a % d = 0, a <= c
; typedef struct matrix_t {
;    const uint64_t rows, cols;
;    float data[(rows $ 4) * (cols $ 4)];
; } matrix_t;
; typedef matrix_t* Matrix;
; Matrices should always be aligned on 16-byte boundary. The length of float array is such that operations can be carried out without much alignment hassle.
; Unused cells are filled with zeros

; There are alignment tricks everywhere in the code, consisting of adding 3 to a register, and then anding the register with ~3
; This lines round value in register up to the neares value that divides by 4
; It is used for alignment purposes, as described above

section .text
extern aligned_alloc
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

; uint64_t matrixSizeCalc(uint64_t rows, uint64_t cols)
; Calculates actual size of storage buffer backing a matrix with specified size, in units of floats
matrixSizeCalc:
	mov rax, rdi
	add rax, 3
	and rax, ~3
	
	add rsi, 3
	and rsi, ~3
	
	xor rdx, rdx
	mul rsi ; result is already in rax
	ret

; Matrix matrixNewUninitialized(uint64_t rows, uint64_t cols)
; Allocates new matrix of given size and returns a pointer to it, or NULL.
; Matrix is filled with uninitialized values.
matrixNewUninitialized:
	enter 0,0
	
	mov rax, rdi
	add rax, 3
	and rax, ~3
	
	mov rcx, rsi
	add rcx, 3
	and rcx, ~3
	
	xor rdx, rdx
	
	mul rcx
	sal rax, 2 ; multiply rax by four, size of float
	add rax, 16 ; and add 16 bytes for the header
	
	push rdi
	push rsi
	push rax
	
	mov rsi, rax
	mov rdi, 16
	call aligned_alloc
	
	pop r10
	pop r9
	pop r8
	
	test rax, rax ; return zero immediately
	jz .return
	
	mov [rax], r8 ; write rows and cols
	mov [rax + 8], r9
	
.return
	leave
	ret

; Matrix matrixNew(uint64_t rows, uint64_t cols)
; Allocates a new matrix and returns the pointer to it, or NULL if it can't be allocated
; Matrix is filled with zeros
matrixNew:
	enter 0,0
	
	call matrixNewUninitialized
	
	push rax
	mov rdi, [rax]
	mov rsi, [rax + 8]
	call matrixSizeCalc ; unfortunately, we need to recalculate this
	
	mov rcx, rax
	pop rsi ; this was return value of matrixNewUninitialized
	
	lea rdi, [rsi + 16] 
	xor rax, rax
	
	rep stosd ; zero out floats
	
	mov rax, rsi
	
.return
	leave
	ret

; Matrix matrixClone(Matrix)
; returns new matrix of same size with same data
matrixClone:
	enter 0, 0
	push r12
	
	mov r12, rdi ; save argument for after allocation
	
	mov rdi, [r12]
	mov rsi, [r12 + 8]
	call matrixNewUninitialized ; allocate new matrix of same size as old one
	
	test rax, rax
	jz .return ; return NULL immediately
	
	push rax ; also save resulting matrix for duration of the call
	
	mov rdi, [r12]
	mov rsi, [r12 + 8]
	call matrixSizeCalc
	
	mov rcx, rax
	
	pop rdi ; restore newly created matrix into rdi (was pushed as rax)
	
	add rcx, 4 ; add 4 dwords for size fields
	
	mov rax, rdi
	
	mov rsi, r12
	rep movsd ; copy all the bytes
	
.return
	pop r12
	leave
	ret

; void matrixDelete(Matrix)
matrixDelete:
	call free ; pointers that are allocated by aligned_alloc can be freed by free immediately
	ret

; uint64_t matrixGetRows(Matrix)
matrixGetRows:
	mov rax, [rdi] ; this doesn't even have enter/leave, just as the functions before and after it, because it's not worth it
	ret

; uint64_t matrixGetCols(Matrix)
matrixGetCols:
	mov rax, [rdi + 8]
	ret

; float matrixGet(Matrix, uint64_t row, uint64_t col)
matrixGet:
	enter 0, 0
	mov rax, [rdi + 8]
	add rax, 3
	and rax, ~3
	
	mov r8, rdx ; save rdx for multiplication
	
	xor rdx, rdx
	mul rsi
	add rax, r8 ; calculate offset into float table as (row * true_cols + col)
	
	movss xmm0, [rdi + rax * 4 + 16]
	
	leave
	ret

; void matrixSet(Matrix, uint64_t row, uint64_t col, float data)
matrixSet:
	enter 0, 0
	mov rax, [rdi + 8]
	add rax, 3
	and rax, ~3
	
	mov r8, rdx
	
	xor rdx, rdx
	mul rsi
	add rax, r8 ; identical to above function, except for the next line
	
	movss [rdi + rax * 4 + 16], xmm0
	
	leave
	ret

; void matrixAdd(Matrix a, Matrix b)
; Adds two matrices and returns the result, or returns NULL if sizes don't match
matrixAdd:
	enter 0, 0
	xor rax, rax ; set return value to zero before (maybe) returning
	
	mov rdx, [rsi]
	cmp rdx, [rdi]
	jne .return
	
	mov rdx, [rsi + 8]
	cmp rdx, [rdi + 8]
	jne .return ; these two comparions make sure we are adding matrices of equal sizes
	
	push rsi
	
	call matrixClone ; copy the first matrix
	
	push rax
	mov rdi, [rax]
	mov rsi, [rax + 8]
	call matrixSizeCalc
	
	mov rcx, rax
	pop rax
	pop rsi
	
	jrcxz .return ; if somehow we manage to get zero-sized matrix. stupid, but who knows.
.add_loop
	sub rcx, 4
	movaps xmm0, [rax + rcx * 4 + 16]
	addps xmm0, [rsi + rcx * 4 + 16]
	movaps [rax + rcx * 4 + 16], xmm0
	
	test rcx, rcx
	jnz .add_loop
	
.return
	leave
	ret

; Matrix matrixScale(Matrix, float)
matrixScale:
	enter 0, 0
	
	sub rsp, 4 ; guarantee 4 bytes of storage
	and rsp, ~0xf ; align to 16-byte boundary for pshufd
	
	movss [rsp], xmm0 ; store argument, because it might not be saved across calls to Clone/SizeCalc
	
	call matrixClone
	
	push rax
	
	mov rdi, [rax]
	mov rsi, [rax + 8]
	call matrixSizeCalc
	
	mov rcx, rax
	
	pop rax
	
	pshufd xmm1, [rsp], 0 ; load previously saved argument into all four of floats in xmm1
	
.mul_loop
	sub rcx, 4
	movaps xmm0, [rax + rcx * 4 + 16]
	mulps xmm0, xmm1
	movaps [rax + rcx * 4 + 16], xmm0
	
	test rcx, rcx
	jnz .mul_loop
	
	leave ; this leave restores rsp to where it was before stack alignment
	ret

; Matrix matrixMul(Matrix, Matrix)
matrixMul:
	enter 0, 0
	push r12
	push r13
	
	mov rdx, [rdi + 8]
	mov rcx, [rsi]
	
	xor rax, rax
	
	cmp rdx, rcx
	jne .return ; return 0 if sized don't allow multiplication
	
	mov r12, rdi
	mov r13, rsi
	
	mov rdi, [r12]
	mov rsi, [r13 + 8]
	
	call matrixNewUninitialized ; allocate a new matrix for the result
	
	test rax, rax
	jz .return ; if unable to allocate (out of memory), return immediately
	
	mov r10, rax ; r10: result matrix
	
	mov r8, [r12] ; r8 : target row
	add r8, 3
	and r8, ~3
	
	mov rsi, [r12 + 8] ; rsi: aligned cols of A
	add rsi, 3
	and rsi, ~3
	
	mov rcx, [r13 + 8] ; rcx: aligned cols of B
	add rcx, 3
	and rcx, ~3
	
	mov r9, [r13 + 8] ; r9: target column
	add r9, 3
	and r9, ~3
	
.outer_loop:
	sub r9, 4 ; loop counter is decreased in the beginning of loop due to reversed direction
	
	mov r8, [r12] ; r8 : target row
	add r8, 3
	and r8, ~3
	
.inner_loop:
	dec r8 ; see above regarding 'sub r9, 4'
	
	xor rdx, rdx
	
	mov rax, r8
	mul rcx
	add rax, r9
	
	mov rdi, rax ; rdi: target cell number
	
	xorps xmm0, xmm0 ; xmm0: accumulator
	
	mov r11, rsi ; r11: inner loop counter
	
.accumulator_loop:
	dec r11 ; again, see above remarks about direction of loop counters
	
	xor rdx, rdx
	mov rax, r8
	mul rsi
	add rax, r11 ; calculate offset into left matrix
	
	movss xmm1, [r12 + rax * 4 + 16] ; we can't use single pshufd here because the address is not actually aligned
	pshufd xmm1, xmm1, 0
	
	xor rdx, rdx
	mov rax, r11
	mul rcx
	add rax, r9 ; calculate offset into right matrix
	
	mulps xmm1, [r13 + rax * 4 + 16] ; this offset actually is aligned
	addps xmm0, xmm1
	
	test r11, r11
	jnz .accumulator_loop
	
	movaps [r10 + rdi * 4 + 16], xmm0 ; write out the result
	
	test r8, r8
	jnz .inner_loop
	
	test r9, r9
	jnz .outer_loop
	
	mov rax, r10
	
.return
	pop r13
	pop r12
	leave
	ret
