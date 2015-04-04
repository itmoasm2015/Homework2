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


; matrix = pointer to memory
; [pointer] = count of columns
; [pointer + 8] = count of rows
; [pointer + 16] = first element
; [i * m + j] = to access element matrix[i][j] 
; pos[i][j] = begin + i * m * 8 + j
; rdi = n = rows
; rsi = m = columns
; rax - answer = pointer to matrix
matrixNew:
	push rbp		; save registers
	push rdi		;
	push rsi		;
	push rbx		;
	push r11		;
	push rcx		;
	push rdx		;
	push r10		;
	push r8			;
	imul rdi, rsi		; calculate count of elements
	mov [msize], rdi	; remember it
	imul rdi, 8		;
	add rdi, 16		;	rdi is count of memory we need
	call malloc		; try to take memory
	jmp .fill_zero
.end_fill_zero:
	pop r8			; return saved registers on positions
	pop r10
	pop rdx
	pop rcx
	pop r11
	pop rbx
	pop rsi
	pop rdi
	mov [rax], rdi		; save rows in our matrix to [rax]
	mov [rax + 8], rsi	; save cows in our matrix to [rax + 8]
	pop rbp
	ret

.fill_zero:			; set zero all elements in our matrix
	mov rcx, 0		; set number of current element
	mov rdx, rax		; set current position
	add rdx, 16		; skip matrix proportions 
	mov rbx, 0
.loop1:
	cmp rcx, [msize]	; if position is end of matrix return
	jz .end_fill_zero
	mov [rdx], rbx		; set zero in curent position
	add rcx, 1		; next element
	add rdx, 8		;
	jmp .loop1

;rdi = pointer to matrix
matrixDelete:
	call free		; free memory of matrix 
	ret

;rdi = pointer to matrix
matrixGetRows:
	mov rax, [rdi]		; return count of rows, saved in [rdi]
	ret

;rdi = pointer to matrix
matrixGetCols:
	mov rax, [rdi + 8]	; return count of columns, saved in [rdi + 8]
	ret

;rdi = pointer to matrix
;rsi = row
;rdx = col
;xmm0 = answer
matrixGet:
	push rcx		; save registers
	mov rcx, rsi		; calculate position we need
	imul rcx, [rdi + 8]	; matrix[rsi][rdi] = 16 + (rsi * columns + rdi) * 8
	add rcx, rdx		; 8 is size of one number
	imul rcx, 8		;
	add rcx, 16		;
	movss xmm0, [rdi + rcx] ; write matrix[rsi][rdi] to xmm0
	pop rcx
	ret

;rdi = pointer to matrix
;rsi = row
;rdx = col
;xmm0 = value
matrixSet:
	push rbx		; save registers
	mov rbx, rsi		; calculate position we need
	imul rbx, [rdi + 8]	; look at matrixGet
	add rbx, rdx		;
	imul rbx, 8		;
	add rbx, 16		;
	add rbx, rdi		;
	movss [rbx], xmm0	; write value to current position matrix[rsi][rdi]
	pop rbx
	ret

;rdi = pointer to matrix
;xmm0 = scalar
;rax = pointer to new matrix
;for i in 1..n 
;    for j in 1..m 
;        matrixScalar[i][j] = matrix[i][j] * k
matrixScale:
	push rbx		; save registers
	push rdx		;
	push rdi		;
	push rsi		;
	mov r10, rdi		; save in r10 pointer to matrix
	mov rdi, [r10]		; save in rdi count of rows
	mov rsi, [r10 + 8]	; save in rsi count of columns
	call matrixNew		; create matrix which size is rdi * rsi
	mov r8, rax		; save pointer to new matrix in rax
	mov rdx, [r10]		; set rows and cols of new matrix are the same as current matrix
	mov [r8], rdx		;
	mov rdx, [r10 + 8]	;
	mov [r8 + 8], rdx	;
	imul rdx, [r8]		;
	mov [msize], rdx	; set size = rows * cols
	add r10, 16		; skip matrix proportions
	add r8, 16		;
	mov rbx, 0		; set number of current element = 0
.start_scale:			;
	cmp rbx, [msize]	; if number of current element == size then return
	jz .end_scale		;
	mov rdx, [r10]		; set matrixScalar[rbx] = matrix[rbx]
	mov [r8], rdx		;
	movss xmm1, [r8]	; multiply matrixScalar[rbx] to scalar xmm0
	mulss xmm1, xmm0	;
	movss [r8], xmm1	;
	add r8, 8		; next elements
	add r10, 8		;
	add rbx, 1		;
	jmp .start_scale
.end_scale:
	pop rsi
	pop rdi
	pop rdx
	pop rbx
	ret

; rdi = pointer to first matrix (rows = n, cols = m)
; rsi = pointer to second matrix (rows = n, cols = m)
; rax = result sum matrix 
;for i in 1..n 
;    for j in 1..m 
;        matrixSum[i][j] = matrix[i][j] + matrix2[i][j]
matrixAdd:
	push rbx		; save registers
	push rdx		;
	push rdi		;
	push rsi 		;
	mov rax, 0		; 
	mov r10, rdi		; save pointer to first matrix in r10
	mov r11, rsi		; save pointer to second matrix in r11
	mov rdi, [r10]		; save n to rdi
	cmp rdi, [r11]		; compare rows of first matrix with rows of second matrix
	jnz .end_sum		; if they are not equal return 0
	mov rsi, [r10 + 8]	; save m to rsi
	cmp rsi, [r11 + 8]	; compare cols of first matrix with cols of second matrix
	jnz .end_sum		; if they are not equal return 0
	call matrixNew		; create matrixSum which size is n * m
	mov rbx, 0		; set number of current element = 0 
	mov r8, rax		; set pointer to matrixSum to r8
	mov rdx, [r10]		; set rows and cols of matrixSum are the same as current matrixs
	mov [r8], rdx		;
	mov rdx, [r10 + 8]	;
	mov [r8 + 8], rdx	;
	imul rdx, [r8]		;
	mov [msize], rdx	; set size = rows * cols
	add r10, 16		; skip matrix proportions
	add r8, 16		;
	add r11, 16		;
.start_sum:
	cmp rbx, [msize]	; if number of current element == size then return
	jz .end_sum		;
	movss xmm1, [r10]	; set matrixScalar[rbx] = matrix[rbx] + matrix2[rbx]
	addss xmm1, [r11]	; do it using xmm1 float register
	movss [r8], xmm1	;
	add r8, 8		; next elements
	add r10, 8		;
	add r11, 8		;
	add rbx, 1		;
	jmp .start_sum		;
.end_sum:			
	pop rsi
	pop rdi
	pop rdx
	pop rbx
	ret

; rdi = pointer to first matrix (rows = n1, cols = m1)
; rsi = pointer to second matrix (rows = n2, cols = m2)
; rax = result mul matrix (rows = n1, cols = m2) 
; n2 == m1!
; for i in 1..n1
;     for j in 1..m2 
;         sum = 0
;         for k in 1..n2
;             sum += matrix[i][k] * matrix2[k][j]
;         matrixMul[i][j] = sum
; i = rbx
; j = rcx
; k = rdx
matrixMul:
	push rbx		; save registers
	push rdx		;
	push rdi		;
	push rsi 		;
	push rcx		;
	push r8			;
	push r10		;
	push r11		;
	mov rax, 0		;
	mov r10, rdi		; save pointer to first matrix in r10
	mov r11, rsi		; save pointer to second matrix in r11
	mov rsi, [r10 + 8]	; save m1 to rsi
	cmp rsi, [r11]		; compare cols of first matrix with rows of second matrix
	jnz .end_circle1	; if they are not equal return 0
	mov rdi, [r10]		; save n1 to rdi
	mov rsi, [r11 + 8]	; save m2 to rsi
	call matrixNew		; create matrixMul which size is n1 * m2
	mov rbx, 0		; 
	cmp rax, rbx		; if can't create matrixMul return zero
	jz .end_circle1		;
	mov r8, rax		; set pointer to matrixMul to r8
	mov rdx, [r10]		;
	mov [r8], rdx		; rows of matrixMul = n1
	mov rdx, [r11 + 8]	;
	mov [r8 + 8], rdx	; cols of matrixMul = m2
	imul rdx, [r8]		;
	mov [msize], rdx	; set size = rows * cols
	mov rdx, [r10 + 8]	;
	mov [rows], rdx		; set m1 to [rows] awhile
	add r10, 16		; skip matrix proportions
	add r8, 16		;
	add r11, 16		;
	jmp .start_circle1	;
.end_cirlce2:			;
	add rbx, 1		; 
.start_circle1:			; start for i in 1..n1
	cmp rbx, [rax]		; if rbx == n1 return
	jz .end_circle1		;
	mov rcx, 0		;
.start_circle2:			; start for j in 1..m2
	cmp rcx, [rax + 8]	; if rcx == m2 return
	jz .end_cirlce2		;
	mov rdx, 0		;
	mov [sum], rdx 		; set sum = 0
.start_cirlce3:			; start for k in 1..m1
	cmp rdx, [rows]		; if rdx == m1 return
	jz .end_circle3		;
	mov rdi, rbx		; calculate position we need
	imul rdi, [rows]	; matrix[rbx][rdx] = r10 + rdi * 8 = r10 + rbx * m1 + rdx
	add rdi, rdx		; matrix2[rdx][rcx] = r11 + rsi * 8 = r11 + rdx * m2 + rcx
	mov rsi, rdx		;
	imul rsi, [rax + 8]	;
	add rsi, rcx		;
	movss xmm1, [r10 + rdi * 8] ;
	mulss xmm1, [r11 + rsi * 8] ;
	addss xmm1, [sum]	; sum += matrix[rbx][rdx] * matrix2[rdx][rcx]
	movss [sum], xmm1	;
	add rdx, 1		;
	jmp .start_cirlce3	;
.end_circle3:
	mov rdx, [sum]		;
	mov [r8], rdx		; matrixMul[rbx][rdx] = sum
	add r8, 8		; next elements
	add rcx, 1		;
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
