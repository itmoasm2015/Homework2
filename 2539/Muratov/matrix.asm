global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul
extern calloc
extern free

%macro align4 1
	add %1, 3
    and %1, ~3
%endmacro

;returns pointer to element of matrix with coordinates [rsi, rdx]
;rdi - pointer to Matrix, rsi - row number, rdx - column number
;pointer stores in rax
%macro getAddress 0
	mov eax, [rdi + 12]
	imul rax, rsi
	add rax, rdx;
	add rax, 4
	imul rax, 4
	add rax, rdi
%endmacro


section .text

;Structure stores in memory:
;|rows|cols|alligned_rows|alligned_cols|matrix|
;Matrix real size is alligned_rows * alligned_cols bytes

	
;rdi - rows, rsi - columns
;returns pointer to the new matrix in rax
matrixNew:
	;allocating memory with void* calloc(size_t num, size_t size)
	mov r8, rdi
	mov r9, rsi
	align4 r8
	align4 r9
	imul r8, r9
	add r8, 4
	push rdi
	push rsi
	mov rdi, r8
	mov rsi, 4
	call calloc
	pop rsi
	pop rdi
	
	;if can't allocate memory, return 0
	cmp rax, 0
	je .error

	;putting in structure rows, cols, alligned_rows ans alligned_cols
	mov [rax], edi
	mov [rax + 4], esi
	align4 rdi
	align4 rsi
	mov [rax + 8], edi
	mov [rax + 12], esi

	jmp .end
.error
	xor rax, rax
.end
	ret

;rdi - pointer on matrix to delete
matrixDelete:
	call free
	ret

;rdi - pointer on matrix
;returns number of rows in given matrix
matrixGetRows:
	mov eax, [rdi]
	ret

;rdi - pointer on matrix
;returns number of columns in given matrix
matrixGetCols:
	mov eax, [rdi + 4]
	ret


;rdi - pointer on matrix; rsi, rdx - coordinates of element to get
;returns element of matrix in xmm0 
matrixGet:
	getAddress
	movd xmm0, [rax]
	ret

;rdi - pointer on matrix; rsi, rdx - coordinates of element to set
;xmm0 - number to put into the matrix
;sets element of matrix
matrixSet:
	getAddress
	movd [rax], xmm0
	ret

;rdi - pointer on matrix; xmm0 - number to scale
;rax - pointer on new scaled matrix
matrixScale:
	;xmm0 = - - - k
	unpcklps xmm0, xmm0
	;xmm0 = - - k k
	unpcklps xmm0, xmm0
	;xmm0 = k k k k

	;creating new matrix
	sub rsp, 16
	movups [rsp], xmm0
	push rdi
	mov esi, [rdi + 4]
	mov edi, [rdi]
	call matrixNew
	pop rdi
	movups xmm0, [rsp]
	add rsp, 16

	;rsi points on old matrix
	;rdi points on new matrix
	mov rsi, rdi
	mov rdi, rax
	
	;r8 - number of elements in matrix multiplied by 4, used in loop
	xor r8, r8
	mov r8d, [rsi + 8]
	imul r8d, dword [rsi + 12]
	imul r8d, 4

	;r9 - runs from 16 to r8 with step 16
	mov r9, 16

	;scaling, using vector functions
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

	;creating new matrix
	push rdi
	push rsi
	mov esi, [rdi + 4]
	mov edi, [rdi]
	call matrixNew
	pop rsi
	pop rdi

	;r8 - number of elements in matrix multiplied by 4, used in loop
	xor r8, r8
	mov r8d, [rsi + 12]
	imul r8d, dword [rsi + 8]
	imul r8d, 4

	;r9 - runs from 16 to r8 with step 16
	mov r9, 16

	;rdi points on first matrix
	;rsi points on second matrix
	;rax points on new matrix

	;addition, using vector functions
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

matrixMul:
	push r12
	push r13
	push r14
	
	;if matrix's sizes don't match return 0;
	mov eax, [rdi + 4]
	cmp eax, dword [rsi]
	jne .multiply_error
	

	;creating new matrix
	push rdi
	push rsi
	mov esi, [rsi + 4]
	mov edi, [rdi]
	call matrixNew
	pop rsi
	pop rdi
	push rax

	;rdi points on first matrix
	;rsi points on second matrix
	;rax points on new matrix
	
	xor r8, r8
	mov r8d, [rax + 8]
	imul r8d, dword [rax + 12]
	imul r8, 4
	add r8, rax
	add r8, 16
	
	xor r14, r14
	mov r14d, [rax + 12] ; r14 - number of columns in new matrix multiplied by 4
	imul r14, 4
	xor r13, r13
	mov r13d, [rdi + 12] ; r13 - number of rows in first matrix and number of columns in second multiplied by 4
	imul r13, 4


	;rdi points on first matrix
	;rsi points on second matrix
	;rax points on new matrix
	add rdi, 16
	add rsi, 16
	add rax, 16

	; r11 - current column in new array
	mov r11, 0 

.multiply
	xorps xmm0, xmm0

	mov rcx, r11

	mov r12, 0

	;loop which counts elements in [rax], [rax + 4], [rax + 8], [rax + 12]  
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

	;counting current column
	add r11, 16
	cmp r11, r14
	jne .notnewrow
	mov r11, 0
	add rdi, r13
.notnewrow

	;writing 4 counted numbers in result matrix
	movups [rax], xmm0
	add rax, 16
	cmp r8, rax
	jne .multiply

	jmp .multiply_no_error
.multiply_error
	xor rax, rax
.multiply_no_error
	pop rax
	pop r14
	pop r13
	pop r12
	ret