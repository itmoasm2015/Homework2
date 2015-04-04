section .text

extern malloc
extern free

global matrixNew
global matrixClone
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul

;Simple structure for Matrix
; NOTE columns
; `cells` are stored unaligned, but both rows and columns are aligned by 4
; so that one can use them in SSE instructions.
struc   Matrix
	rows:resq 1 ; unaligned amount of rows
	columns:resq 1 ; unaligned amount of columns
	rows_align:resq 1 ; aligned amount of rows (aligned by 4 bytes)
	columns_align:resq 1 ; aligned amount of columns (aligned by 4 bytes)
	cells:resq 1 ; pointer to float array where values stored
endstruc


; Matrix matrixNew(unsigned int rows, unsigned int columns);
;
; takes: rdi - int rows, 
;        rsi - int columns 
; returns: rax - pointer to Matrix

matrixNew:          
	push rdi
	push rsi
	
	mov rdi, Matrix_size ; allocate memory for Matrix
	call malloc
	
	mov r8, rax ; rax is result of calloc
	pop rsi
	pop rdi
	
	mov [r8 + rows], rdi ; initialize Matrix dimensions
	mov [r8 + columns], rsi
; Align rows and columns by 4
; rdi - ceil(rows / 4) * 4
; rsi - ceil(columns / 4) * 4
	dec rdi
	shr rdi, 2
	shl rdi, 2
	lea rdi, [rdi + 4]
	dec rsi
	shr rsi, 2
	shl rsi, 2
	lea rsi, [rsi + 4]
	mov [r8 + rows_align], rdi ; initialize corresponding fields in structure
	mov [r8 + columns_align], rsi
	
	imul rdi, rsi ; calculate aligned Matrix size
	lea rdi, [rdi * 4] ; sizeof float
	push rdi
	push r8
	
	call malloc; allocate space for cells
	pop r8
	pop rcx
	shr rcx, 2
	mov [r8 + cells], rax ; rax - ponts to allocated space
	mov rdi, rax
	xor eax, eax
	cld
	rep stosd; fill cells with zero
	mov rax, r8 ; move pointer to Matrix to rax
	ret

; Matrix matrixClone(Matrix matrix);
;Clones existing matrix to a new one.
; takes: rdi - Matrix matrix
; returns: rax - new Matrix

matrixClone:        
	mov r8, rdi
	mov rdi, [r8 + rows]
	mov rsi, [r8 + columns]
	push r8
	
	call matrixNew ; rax - pointer to new initialized Matrix
	pop r8
	
	mov rcx, [r8 + rows_align]
	imul rcx, [r8 + columns_align]
	mov rsi, [r8 + cells]
	mov rdi, [rax + cells]
	cld
	rep movsd ; copy cells from old to new matrix
	ret

; void matrixDelete(Matrix matrix);
; Deletes matrix and deallocates the space taken by cells
; takes: rdi - Matrix matrix

matrixDelete:       
	push rdi
	mov rdi, [rdi + cells]
	call free ; deallocate cells
	
	pop rdi
	call free ; deallocate matrix
	ret

; unsigned int matrixGetRows(Matrix matrix);
; Returns the amount of rows in Matrix matrix
; takes: rdi - Matrix matrix
; returns: rax - matrix.rows

matrixGetRows:      
	mov rax, [rdi + rows]
	ret

; unsigned int matrixGetCols(Matrix matrix);
; Returns the amount of columns in Matrix matrix
; takes: rdi - Matrix matrix
; returns: rax - matrix.rows

matrixGetCols:      
	mov rax, [rdi + columns]
	ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
; Get value from cell defined by int row and int col.
; takes: rdi - Matrix matrix
;        rsi - unsigned int row
;        rdx - unsigned int col
; returns: xmm0 - matrix.cells[index]

matrixGet:
	mov r8, [rdi + cells] ; getting cell pointer
	mov r9, [rdi + columns_align]
	imul r9, rsi
	lea r9, [r9 + rdx]
	movss xmm0, [r8 + r9 * 4]
	ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
; Set cell defined by int col and int row to float value.
; takes:
;   rdi - Matrix matrix
;   rsi - unsigned int row
;   rdx - unsigned int col
;   xmm0 - float value 

matrixSet:
	mov r8, [rdi + cells] ; getting cell pointer
	mov r9, [rdi + columns_align]
	imul r9, rsi
	lea r9, [r9 + rdx]
	movss [r8 + r9 * 4], xmm0 ; move provided value to defined cell
	ret

; Matrix matrixScale(Matrix matrix, float k);
; Return new Matrix multiplied on float k value. 
; takes: rdi - Matrix matrix
;        xmm0 - float k
; returns: rax - new Matrix

matrixScale:
	call matrixClone
	mov rcx, [rax + rows_align]
	imul rcx, [rax + columns_align]
	shr rcx, 2
	mov rdx, [rax + cells]
	shufps xmm0, xmm0, 0 ; makes vector xmm0 = (k:k:k:k)
.scale_loop:
	; load 4 of the cells to xmm1 register
	; multiply them by xmm0 vector
	; and put them back to the matrix
	; move output pointer 4 * sizeof float bytes
	movups xmm1, [rdx]
	mulps xmm1, xmm0
	movups [rdx], xmm1
	lea rdx, [rdx + 16]
	loop .scale_loop
	ret

; Matrix matrixAdd(Matrix a, Matrix b);
; Returns Matrix result of addition Matrix a to Matrix b;
; takes: rdi - Matrix a
;        rsi - Matrix b
; returns: rax - new Matrix

matrixAdd:
	; check if Matrix can be added
	mov r8, [rdi + rows]
	mov r9, [rsi + rows]
	cmp r8, r9
	jne .failure ; a.rows != b.rows
	
	mov r8, [rdi + columns]
	mov r9, [rsi + columns]
	cmp r8, r9
	jne .failure ; a.columns != b.columns
	
	push rsi
	call matrixClone ; copy Matrix to store result of matrixAdd
	pop rsi
	mov rcx, [rax + rows_align] ; get amounts of cells
	imul rcx, [rax + columns_align]
	shr rcx, 2
	
	mov rdx, [rax + cells] ; rdx - pointer to answer's cells
	mov r8, [rsi + cells] ; r8 - pointer to second Matrix's cells
.add_loop:
	; load 4 cells of answer Matrix into xmm0 and and adds them with second Matrix's 4 cells
	movups xmm0, [rdx]
	addps xmm0, [r8]
	movups [rdx], xmm0 ; returns answer into answer Matrix
	; move pointers 4 * sizeof float
	lea rdx, [rdx + 16]
	lea r8, [r8 + 16]
	loop .add_loop
	ret
.failure: ; Matrix can't be added           
	xor rax, rax
	ret

; Matrix matrixTranspose(Matrix matrix);
; Return transposed Matrix matrix
; takes: rdi - Matrix matrix (m*n)
; returns: rax - matrix (n*m)

matrixTranspose:
	push rdi
	mov rsi, [rdi + rows]
	mov rdi, [rdi + columns]
	call matrixNew
	pop rdi
	
	mov r8, [rax + columns_align]
	mov r9, [rax + rows_align]
	mov r10, [rdi + cells]
	mov rdi, [rax + cells]
	xor rcx, rcx ; loop iterations
.transpose_loop_1:
	xor rdx, rdx ; amount of elements moved in transpose_loop_2
	lea r11, [rdi + rcx * 4] ; adress of first output cell
.transpose_loop_2:
	movups xmm0, [r10] ; xmm0 = A : B : C : D
	movss [r11], xmm0               ; [r11] = A
	psrldq xmm0, 4
	
	lea r11, [r11 + r8 * 4]
	movss [r11], xmm0               ; [r11] = B
	psrldq xmm0, 4
	
	lea r11, [r11 + r8 * 4]
	movss [r11], xmm0               ; [r11] = C
	psrldq xmm0, 4
	
	lea r11, [r11 + r8 * 4]
	movss [r11], xmm0               ; [r11] = D
	
	lea r11, [r11 + r8 * 4]
	lea rdx, [rdx + 4] ; move pointer by 4 * sizeof float bytes
	lea r10, [r10 + 16] ; increase moved elements counter
	cmp rdx, r9 ; if rdx = r9 finished line
	jb .transpose_loop_2
	inc rcx
	cmp rcx, r8
	jb .transpose_loop_1
	ret

; Matrix matrixMul(Matrix a, Matrix b);
; Returns new matrix which is a result of multiplying matrices a and b.
; takes: rdi - Matrix a
;        rsi - Matrix b
; returns: rax - new Matrix

matrixMul:
	; check if a and b meets requirements for Mul operation 
	mov r8, [rdi + columns]
	mov r9, [rsi + rows]
	cmp r8, r9
	jne .failure
	
	push rbx
	push rbp
	push rdi
	push rsi
	mov rdi, rsi

	call matrixTranspose ; transposed RSI in RAX
	pop rsi
	pop rdi
	push rax
	push rdi
	mov rdi, [rdi + rows] ; get the dimensions of resulting matrix to call matrixNew
	mov rsi, [rsi + columns]
	
	call matrixNew ; rax - resulting Matrix
	
	mov rcx, [rax + cells]
	pop rdi
	pop rsi
	push rsi
	mov r8, [rdi + rows_align]
	mov r9, [rsi + rows_align]
	mov r10, [rdi + columns_align]
	mov rdi, [rdi + cells]  ; first initial matrix cells
	mov rsi, [rsi + cells]  ; transposed second matrix cells
	mov rdx, rsi
	mov rbx, r10
	mov rbp, r9
.mul_loop_1:
	dec r8
	mov rsi, rdx
	mov r9, rbp
.mul_loop_2:
	dec r9
	mov r10, rbx
	shr r10, 2
	xorps xmm0, xmm0  ; temporary variable for summing up results
.mul_loop_3:
	dec r10
	movups xmm1, [rdi]  ; XMM1 = A : B : C : D
	movups xmm2, [rsi]  ; XMM2 = E : F : G : H
	dpps xmm1, xmm2, 0xF1  ; XMM1 = (A*E+B*F)+(C*G+D*H) : ...
	addss xmm0, xmm1  ; add current result to xmm0
	lea rdi, [rdi + 16]  ; move pointer 4 * sizeof float bytes
	lea rsi, [rsi + 16]
	test r10, r10  ; check if we have processed whole line
	jnz .mul_loop_3
	
	sub rdi, rbx
	sub rdi, rbx
	sub rdi, rbx
	sub rdi, rbx
	movss [rcx], xmm0 ; move result to new matrix cell
	lea rcx, [rcx + 4]
	test r9, r9
	jnz .mul_loop_2 ; if we have filled whole line in resulting matrix (r10 == 0) move to next line in first operand matrix
	
	lea rdi, [rdi + rbx * 4]
	test r8, r8
	jnz .mul_loop_1 ; if we have processed all lines (r11 == 0) in first operand we have found the result
	
	pop rdi
	push rax
	call matrixDelete ; deallocate transposed second matrix
	pop rax
	pop rbp ; restore callee saved registers
	pop rbx
	ret
.failure: ; matrix can not be multiplied, return 0
	xor rax, rax
	ret