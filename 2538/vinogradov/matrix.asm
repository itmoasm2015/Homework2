;; In this file, for a value x, notation ⟦x⟧⁴ stands for x rounded up to the nearest multiple of 4. For example, ⟦5⟧⁴=8, ⟦12⟧⁴=12.
;; Matrix is stored as a struct { unsigned rows, cols; char padding[8]; float values[rows][⟦cols⟧⁴]; }
;; Matrix location is always aligned on 16 bytes.
;; Every row is aligned on 16 bytes; so, every row takes sizeof(float)*⟦cols⟧⁴ bytes.
extern aligned_alloc, bzero, free
	
global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

;; matrix representation
struc matrix
	m_rows resd 1
	m_cols resd 1
	m_pad  resb 8
	m_vals resb 0
endstruc

;; round %1 up to the nearest multiple of %2. %2 must be a power of 2
%macro roundup 2
	add %1, %2-1
	and %1, ~(%2-1)		; zero last bits
%endmacro

;; round up to the nearest multiple of 4
%macro upto4 1
	roundup %1, 4
%endmacro

;; round up to the nearest multiple of 16
%macro upto16 1
	roundup %1, 16
%endmacro

;; Allocates memory aligned on 16 bytes; if aligned_alloc failed, returns with rax=0
;; Number of bytes to allocate should be in rsi
;; The allocated memory address goes to rax
%macro alloc16 0
	mov rdi, 16
	call aligned_alloc
	test rax, rax
	jnz %%alloc_ok
	ret			; aligned_alloc failed, return
%%alloc_ok:
%endmacro

;; Matrix matrixNew(unsigned rows, unsigned cols)
;; Allocates a new matrix and fills it with zeros
;; input: rdi=rows, rsi=cols
;; output: rax=addr, rdx=cols:rows
matrixNew:	
	;; save calle-save registers
	push rbx
	
	;; remember dimensions
	push rdi
	push rsi

	;; calculate number of bytes needed for the matrix
	mov rax, rdi
	upto4 rsi
	mul rsi
	mov rsi, rax
	shl rsi, 4
	mov rbx, rsi
	add rsi, 16

	;; allocate memory for the matrix
	alloc16

	;; put rows and cols
	pop rsi
	pop rdi
	mov [rax+m_rows], edi
	mov [rax+m_cols], esi

	;; fill the matrix with zeros
	lea rdi, [rax+m_vals]
	mov rsi, rbx
	mov rbx, rax
	call bzero

	mov rax, rbx

	;; restore calle-save registers
	pop rbx

	ret

;; void matrixDelete(Matrix matrix)
;; Deallocates memory for the matrix
;; input: rdi=matrix
matrixDelete:
	jmp free

;; unsigned int matrixGetRows(Matrix matrix);
;; Returns number of rows
;; input: rdi=matrix
;; output: rax=rows
matrixGetRows:
	mov eax, [rdi+m_rows]
	ret

;; unsigned int matrixGetRows(Matrix matrix);
;; Returns number of columns
;; input: rdi=matrix
;; output: rax=cols
matrixGetCols:
	mov eax, [rdi+m_cols]
	ret

;; Calculates offset of the element at the given position
;; input: rdi=matrix, rsi=row, rdx=col
;; output: rsi = row*⟦cols⟧⁴ + col
%macro calculate_offset 0
	mov ecx, [rdi+m_cols]
	upto4 rcx
	mov eax, esi
	mov rsi, rdx
	mul rcx
	add rsi, rax
%endmacro

;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;; Returns element of the matrix at the given position
;; input: rdi=matrix, rsi=row, rdx=col
;; output: xmm0=the element
matrixGet:
	calculate_offset
	movss xmm0, [rdi+m_vals+4*rsi]
	ret

;; void matrixGet(Matrix matrix, unsigned int row, unsigned int col, float value);
;; Sets element of the matrix at the given position to the given value
;; input: rdi=matrix, rsi=row, rdx=col, xmm0=value
matrixSet:
	calculate_offset
	movss [rdi+m_vals+4*rsi], xmm0
	ret


;; Allocates a new matrix with given number of rows and cols and sets rbx to the offset of the last 4-element block in such matrix
;; input: rsi = cols:rows
;; output: rax = matrix, rbx = rows*⟦cols⟧⁴-4
%macro allocate_and_move_to_end 0
	push rsi
	mov eax, esi
	shr rsi, 32
	upto4 rsi
	mul rsi
	lea rbx, [rax-4]
	lea rsi, [matrix_size+rax*4]
	alloc16
	pop qword [rax]
%endmacro
	
;; Matrix matrixScale(Matrix matrix, float k);
;; Multiplies every element of the matrix by k
;; input: rdi=matrix, xmm0=0:0:0:k
;; output: rax=result_matrix
matrixScale:	
	;; save calle-save registers
	push rbx
	push r12

	;; remember input matrix
	mov r12, rdi

	;; allocate new matrix
	mov rsi, [rdi]
	allocate_and_move_to_end

	;; clone k:
				; xmm0 = 0:0:0:k
	movsldup xmm0, xmm0	; xmm0 = 0:0:k:k
	unpcklps xmm0, xmm0	; xmm0 = k:k:k:k
	
	;; multiply all elements by k and write to the new matrix
.loop:
	movups xmm1, [r12 + m_vals + 4*rbx]
	mulps xmm1, xmm0
	movups [rax + m_vals + 4*rbx], xmm1

	sub rbx, 4		; move to the previous 4-element block
	jae .loop
.end:
	;; restore calle-save registers
	pop r12
	pop rbx

	ret
	
;; Matrix matrixAdd(Matrix matrix1, Matrix matrix2);
;; Adds matrices
;; input: rdi=matrix1, rsi=matrix2
;; output: rax=matrix
matrixAdd:	
	;; check dimensions
	mov rax, [rdi]
	cmp [rsi], rax
	je .dims_are_ok
.dims_are_bad:
	;; return zero
	xor rax, rax
	ret
.dims_are_ok:	
	;; save calle-save registers
	push rbx
	push r12
	push r13

	;; remember input matrices
	mov r12, rdi
	mov r13, rsi

	mov rsi, [rsi]
	allocate_and_move_to_end
	
	;; add all elements and write to the new matrix
.loop:
	movups xmm0, [r12 + m_vals + 4*rbx]
	addps xmm0, [r13 + m_vals + 4*rbx]
	movaps [rax + m_vals + 4*rbx], xmm0

	sub rbx, 4		; move to the prevous 4-element block
	jae .loop
.end:
	pop r13
	pop r12
	pop rbx

	ret

;; Matrix matrixMul(Matrix matrix1, Matrix matrix2);
;; Multiplies matrices
;; input: rdi=matrix1, rsi=matrix2
;; output: rax=matrix
matrixMul:	
	;; check that cols1==rows2:
	mov eax, [rsi+m_rows]
	cmp [rdi+m_cols], eax
	je .dims_are_ok
.dims_are_bad:
	;; return zero
	xor rax, rax
	ret
.dims_are_ok:	
	;; save calle-save registers
	push rbx
	push r12
	push r13
	push r14

	;; remember the input matrices and number of columns in the second matrix
	mov r12, rdi
	mov r13, rdx
	mov ebx, [rdx+m_cols]

	;; Before calculating the product we calculate transposition of the second matrix
.allocate_transposition:
	;; calculate number of bytes needed for the transposed matrix
	mov eax, [rsi+m_rows]
	upto4 rax
	mov r8d, [rsi+m_cols]
	mul r8
	lea rsi, [rax*4]

	;; allocate memory for the transposed second matrix
	alloc16

	;; Calculate transposition of the second matrix:
.transpose:
	;; get number of columns in the original matrix
	mov edx, [r13+m_cols]

	mov ecx, [r13+m_rows] 	; set outer loop counter to the number of rows in the original matrix
	lea rsi, [r13+m_vals]	; get addr of the original matrix

	;; get actual width of the tranposed matrix
	mov r11, rcx
	upto4 r11		; r11 = ⟦rows2⟧⁴

	xor r10, r10		; start from the first column of the transposed matrix
.transpose_row:
	mov r8d, [r13+m_cols] 	; reset inner loop counter to the number of columns in the original matrix
	lea rdi, [rax+r10]	; move to the current column of the first row of the transposed matrx
.transpose_cell:
	movsd			; copy the element and move to the next cell of the original matrix
	lea rdi, [rdi+4*r11-4]	; move to the next row of the transposed matrix ('movsd' added 4 to rdi, so we subtract it back)
	sub r8, 1
	jnz .transpose_cell
.transpose_cell_end:
	upto16 rsi 		; move to the next row of the original matrix: if the width of the original matrix is not a multiple of 4, there is an unused tail in the end of each row; so we jump over this tail
	add r10, 4		; move to the next column of the transposed matrix
	sub rcx, 1
	jnz .transpose_row
.transpose_row_end:
	;; save the address of the tranposed matrix in r13
	mov r13, rax

.allocate_result:
	;; calculate number of bytes needed for the product matrix
	mov esi, ebx
	upto4 rsi
	mov eax, [r12+m_rows]
	mul rsi
	lea rsi, [matrix_size + rax*4]

	;; allocate memory for the product
	alloc16

	;; set rows and cols
	mov ecx, [r12+m_rows]
	mov [rax+m_rows], ecx
	mov [rax+m_cols], ebx
	
	;; save the address for the product in r14
	lea r14, [rax+m_vals]
	
.calculate_product:
	mov r8d, [rax+m_rows]		; reset .loop1 counter to the number of rows in the result

	;; get actual width the first matrix (= width of the transposed second matrix)
	mov ebx, [r12+m_cols]
	upto4 rbx		; rbx = ⟦cols1⟧

	;; for each row of the first matrix:
.loop1:				
	mov rdi, r13		; move to the first row of second matrix
	mov r9d, [rax+m_cols]	; reset .loop2 counter to the number of columns in the result matrix

	;; for each row of the transposed second matrix:
.loop2: 
	lea r10, [rbx-4]	; start from the right-most 4-element block
	xorps xmm0, xmm0	; zero the accumulator

	;; for each 4-element block:
.loop3:
	;; multiply elements of the block pointwise
	movaps xmm1, [r12 + m_vals + 4*r10]
	mulps xmm1, [rdi + 4*r10]
	;; add the product to the accumulator pointwise
	addps xmm0, xmm1

	sub r10, 4		; move to the previous 4-element block
	jae .loop3
.loop2_end:
	;; get sum of the products
	haddps xmm0, xmm0
	haddps xmm0, xmm0

	;; store the sum into the cell of the result matrix
	movss [r14], xmm0

	lea rdi, [rdi+4*rbx]	; move to the next row of the transposed second matrix
	add r14, 4		; move to the next cell of the result matrix
	sub r9, 1
	jnz .loop2
.loop1_end:
	lea r12, [r12+4*rbx]	; move to the next row of the first matrix
	
	upto16 r14		; move to the next row of the result matrix (jumping over the unused tail of the row; the same trick with 'upto16' is used in transposing)
	sub r8, 1
	jnz .loop1

.end:
	pop r14
	pop r13
	pop r12
	pop rbx

	ret
