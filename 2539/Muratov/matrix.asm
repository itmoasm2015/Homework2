global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul
extern malloc
extern free

%define FLOATSIZE dword 4

%macro align4 1
	add %1, 3
    and %1, ~3
%endmacro

section .text

;|rows(4 bytes)|cols(4 bytes)|alligned_rows(4 bytes)|alligned_cols(4 bytes)|
;matrix(alligned_cols*alligned_rows*FLOATSIZE bytes)|
;alligned_rows 
;
	
matrixNew:
	;allocating memory with void *malloc(size_t size)
	mov r8, rdi
	mov r9, rsi
	align4 r8
	align4 r9
	mov eax, r8d
	mul r9d
	mov ecx, FLOATSIZE
	mul ecx
	mov rcx, rax
	add rax, 16
	push r8
	push r9
	push rdi
	push rsi
	push rcx
	mov rdi, rax
	call malloc
	pop rcx
	pop rsi
	pop rdi
	pop r9
	pop r8
	
	cmp rax, 0
	je .error

	;putting in structure rows, cols, alligned_rows ans alligned_cols
	mov [rax], edi
	mov [rax + 4], esi
	mov [rax + 8], r8d
	mov [rax + 12], r9d

	;filling xmm0 with four positive zeroes
	xorps xmm0, xmm0 

	;filling matrix with zeroes
.fillzero 
	sub rcx, 16
	movups [rax + rcx], xmm0
	cmp rcx, 16
	jne .fillzero

	jmp .end
.error
	xor rax, rax
.end
	ret

matrixDelete:
	call free
	ret

matrixGetRows:
	xor rax, rax
	mov eax, [rdi]
	ret

matrixGetCols:
	xor rax, rax
	mov eax, [rdi + 4]
	ret

;returns pointer to element of matrix with coordinates [rsi, rdx]
;rdi - pointer to Matrix, rsi - row number, rdx - column number
;returning value contains in xmm0
; returns 16 + cols_alligned * 4 * numOfRow + num_of_col * 4
getAddress:
	mov eax, [rdi + 12]
	push rdx
	mul rsi
	pop rdx
	add rax, rdx;
	add rax, 4
	mov rdx, 4
	mul rdx
	add rax, rdi
	ret

matrixGet:
	call getAddress
	movd xmm0, [rax]
	ret

matrixSet:
	call getAddress
	movd [rax], xmm0
	ret

;rdi - pointer on matrix; xmm0 - number to scale
;rax - pointer on new scaled matrix
matrixScale:
	xor rax, rax
	mov eax, [rdi + 8]	
	mov edx, [rdi + 12]
	mul edx
	mov edx, 4
	mul edx

	;xmm0 = - - - k
	unpcklps xmm0, xmm0
	;xmm0 = - - k k
	unpcklps xmm0, xmm0
	;xmm0 = k k k k

	sub rsp, 16
	movups [rsp], xmm0
	push rax
	push rdi
	mov rsi, [rdi + 4]
	mov rdi, [rdi]
	call matrixNew
	pop rdi
	pop r8
	movups xmm0, [rsp]
	add rsp, 16

	mov rsi, rdi
	mov rdi, rax
	;rsi points on old matrix
	;rdi points on new matrix
	
	mov r9, 16

.scaling
	movups xmm1, [rsi + r9]
	mulps xmm1, xmm0
	movups [rdi + r9], xmm1
	add r9, 16
	cmp r8, r9
	jne .scaling
	
	ret

matrixAdd:
	;if matrix's sizes don't match return 0;
	mov eax, [rdi]
	cmp eax, dword [rsi]
	jne .adding_error
	mov eax, [rdi + 4]
	cmp eax, dword [rsi + 4]
	jne .adding_error


	xor rax, rax
	mov eax, [rdi + 8]	
	mov edx, [rdi + 12]
	mul edx
	mov edx, 4
	mul edx

	push rax
	push rdi
	push rsi
	mov rsi, [rdi + 4]
	mov rdi, [rdi]
	call matrixNew
	pop rsi
	pop rdi
	pop r8

	;rdi points on first matrix
	;rsi points on second matrix
	;rax points on new matrix

	mov r9, 16

.adding
	movups xmm0, [rsi + r9]
	addps xmm0, [rdi + r9]
	movups [rax + r9], xmm0
	add r9, 16
	cmp r8, r9
	jne .adding
	
	ret
.adding_error
	xor rax, rax
	ret

%macro mult 2
	push rax
	push rdx
	mov rax, %1
	mul %2
	mov %1, rax
	pop rdx
	pop rax
%endmacro

matrixMul:
	push r12
	push r13
	push r14
	push r15
	;if matrix's sizes don't match return 0;
	mov eax, [rdi + 4]
	cmp eax, dword [rsi]
	jne .multiply_error
	
	push rdi
	push rsi
	mov rsi, [rsi + 4]
	mov rdi, [rdi]
	call matrixNew
	pop rsi
	pop rdi
	push rax

	;rdi points on first matrix
	;rsi points on second matrix
	;rax points on new matrix
	push rax
	mov r8, rax
	xor rax, rax
	mov eax, [r8 + 8]
	xor rdx, rdx
	mov edx, [r8 + 12]
	mul rdx
	mov rdx, 4
	mul rdx
	mov r8, rax
	pop rax
	add r8, rax
	add r8, 16

	
	mov r12, 4
	xor r15, r15
	mov r15d, [rax + 8] ; r15 - number of rows in new matrix
	mult r15, r12
	xor r14, r14
	mov r14d, [rax + 12] ; r14 - number of columns in new matrix
	mult r14, r12
	xor r13, r13
	mov r13d, [rdi + 12] ; r13 - number of rows in first matrix and number of columns in second
	mult r13, r12

	add rax, 16

	add rdi, 16
	add rsi, 16


	; r10, r11 - current position in new array
	mov r10, 0
	mov r11, 0 

	;r9 - helps to recognize when we go to the new row
	mov r9, rax
	add r9, r14
.multiply
	xorps xmm0, xmm0

	mov rcx, r11

	mov r12, 0

.count
	xorps xmm1, xmm1
	movd xmm1, [rdi + r12]
	unpcklps xmm1, xmm1
	unpcklps xmm1, xmm1
	movups xmm2, [rsi + rcx]
	mulps xmm1, xmm2
	addps xmm0, xmm1	
	add rcx, r14
	add r12, 4
	cmp r12, r13
	jne .count 

	;counting new position
	add r11, 16
	cmp r11, r14
	jne .notnewrow
	mov r11, 0
	add rdi, r13
	inc r10
.notnewrow

	movups [rax], xmm0
	add rax, 16
	cmp r8, rax
	jne .multiply

	jmp .multiply_no_error
.multiply_error
	xor rax, rax
.multiply_no_error
	pop rax
	pop r15
	pop r14
	pop r13
	pop r12
	ret