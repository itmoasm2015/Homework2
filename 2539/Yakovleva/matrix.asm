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

section .text
;Matrix matrixNew(unsigned int rows, unsigned int cols);
;void matrixDelete(Matrix matrix);
;unsigned int matrixGetRows(Matrix matrix);
;unsigned int matrixGetCols(Matrix matrix);
;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;Matrix matrixScale(Matrix matrix, float k);
;Matrix matrixAdd(Matrix a, Matrix b);
;Matrix matrixMul(Matrix a, Matrix b);


; matrix is a pointer
; [pointer] is count of columns
; [pointer + 8] is count of rows
; [pointer + 16] is first element
; [i * m + j] = to access element matrix[i][j] 
; pos[i][j] = begin + i * m * 8 + j
; rdi = n = rows
; rsi = m = columns
; rax - answer = pointer to matrix
matrixNew:
	push rbp
	push rdi
	push rsi
	push rbx
	push r11
	imul rdi, rsi
	mov [msize], rdi
	imul rdi, 8
	add rdi, 16
	call malloc
	pop r11	
	pop rbx
	pop rsi
	pop rdi
	mov [rax], rdi
	mov [rax + 8], rsi
	pop rbp
	ret
;	jmp .fill_zero
.end_fill_zero:

.fill_zero:
	mov rcx, 0
	mov rdx, rax
	add rdx, 16
	mov rbx, 0
.loop1:
	cmp rcx, [msize]
	jz .end_fill_zero
	mov [rdx], rbx
	add rcx, 1
	add rdx, 8
	jmp .loop1

;rdi - pointer to matrix
matrixDelete:
	call free
	ret

;rdi - pointer to matrix
matrixGetRows:
	mov rax, [rdi]
	ret

;rdi - pointer to matrix
matrixGetCols:
	mov rax, [rdi + 8]
	ret

;rdi - pointer to matrix
;rsi = row
;rdx = col
matrixGet:
	push rcx
	mov rcx, rsi
	imul rcx, [rdi + 8]
	add rcx, rdx
	imul rcx, 8
	add rcx, 16
	mov rax, [rdi + rcx]
	pop rcx
	ret

;rdi - pointer to matrix
;rsi = row
;rdx = col
;rcx = value
matrixSet:
	push rbx
	mov rbx, rsi
	imul rbx, [rdi + 8]
	add rbx, rdx
	imul rbx, 8
	add rbx, 16
	add rbx, rdi
	mov [rbx], rcx
	pop rbx
	ret

;rdi - pointer to matrix
;rsi = scalar
;rax - pointer to new matrix
;for i in 1..n 
;    for j in 1..m 
;        matrix2[i][j] = matrix[i][j] * k
matrixScale:
	push rbx
	push rdx
	push rdi
	push rsi
	mov r10, rdi
	mov r11, rsi
	mov rdi, [r10]
	mov rsi, [r10 + 8]
	call matrixNew
	mov r8, rax
	mov rdx, [r10]
	mov [r8], rdx
	mov rdx, [r10 + 8]
	mov [r8 + 8], rdx
	imul rdx, [r8]
	mov [msize], rdx
	add r10, 16
	add r8, 16
	mov rbx, 0
.start_scale:
	cmp rbx, [msize]
	jz .end_scale
	mov rdx, [r10]
	imul rdx, r11
	mov [r8], rdx
	add r8, 8
	add r10, 8
	add rbx, 1
	jmp .start_scale
.end_scale:
	pop rsi
	pop rdi
	pop rdx
	pop rbx
	ret

; rdi -- pointer to first matrix
; rsi -- pointer to second matrix
; rax -- result sum matrix 
matrixAdd:
	push rbx
	push rdx
	push rdi
	push rsi 
	mov rax, 0
	mov r10, rdi
	mov r11, rsi
	mov rdi, [r10]
	cmp rdi, [r11]
	jnz .end_sum
	mov rsi, [r10 + 8]
	cmp rsi, [r11 + 8]
	jnz .end_sum
	call matrixNew
	mov rbx, 0
	mov r8, rax
	mov rdx, [r10]
	mov [r8], rdx
	mov rdx, [r10 + 8]
	mov [r8 + 8], rdx
	imul rdx, [r8]
	mov [msize], rdx
	add r10, 16
	add r8, 16
.start_sum:
	cmp rbx, [msize]
	jz .end_sum
	mov rdx, [r10]
	add rdx, [r11]
	mov [r8], rdx
	add r8, 8
	add r10, 8
	add r11, 8
	add rbx, 1
	jmp .start_sum
.end_sum:
	pop rsi
	pop rdi
	pop rdx
	pop rbx
	ret

; rdi -- pointer to first matrix
; rsi -- pointer to second matrix
; rax -- result mul matrix 
; for (int i = 0; i < n1; i++)
;     for (int j = 0; j < m2; j++) 
;         sum = 0
;         for (int k = 0; k < m1 == n2; k++)
;             sum += matrix[i][k] * matrix2[k][j]
;         matrixMul[i][j] = sum
; i = rbx
; j = rcx
; k = rdx
		 
matrixMul:
	push rbx
	push rdx
	push rdi
	push rsi 
	push rcx
	push r8
	push r10
	push r11
	mov rax, 0
	mov r10, rdi
	mov r11, rsi
	mov rsi, [r10 + 8]
	cmp rsi, [r11]
	jnz .end_circle1
	mov rdi, [r10]
	mov rsi, [r11 + 8]
	call matrixNew
	mov rbx, 0	
	cmp rax, rbx
	jz .end_circle1
	mov r8, rax
	mov rdx, [r10]
	mov [r8], rdx
	mov rdx, [r11 + 8]
	mov [r8 + 8], rdx
	imul rdx, [r8]
	mov [msize], rdx
	mov rdx, [r10 + 8]
	mov [rows], rdx
	add r10, 16
	add r8, 16
	add r11, 16
	jmp .start_circle1
.end_cirlce2:
	add rbx, 1
.start_circle1:
	cmp rbx, [rax]
	jz .end_circle1
	mov rcx, 0
.start_circle2:
	cmp rcx, [rax + 8]	
	jz .end_cirlce2
	mov rdx, 0
	mov [sum], rdx 	
.start_cirlce3:
	cmp rdx, [rows]
	jz .end_circle3
	mov rdi, rbx
	imul rdi, [rows]
	add rdi, rdx
	mov rsi, rdx
	imul rsi, [rax + 8]
	add rsi, rcx
	mov r12, [r10 + rdi * 8]
	imul r12, [r11 + rsi * 8]
	add [sum], r12
	add rdx, 1
	jmp .start_cirlce3
.end_circle3:
	mov rdx, [sum]
	mov [r8], rdx
	add r8, 8
	add rcx, 1
	jmp .start_circle2
.end_circle1:
	pop r11
	pop r10
	pop r8
	pop rcx
	pop rsi
	pop rdi
	pop rdx
	pop rbx
	ret




section .bss
msize:		resq 1
rows:		resq 1
cols:		resq 1
sum: 		resq 1
