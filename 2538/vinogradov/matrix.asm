;; In this file, for a value x, notation ⟦x⟧⁴ stands for x rounded up to the nearest multiple of 4. For example, ⟦5⟧⁴=8, ⟦12⟧⁴=12.
;; Matrix is defined as struct { float* addr; unsigned rows, cols; }
;; Field /addr/ points to a dynamically allocated block of memory of size sizeof(float)*rows*⟦cols⟧⁴. Addr is aligned on 16 bytes.
;; Every row are aligned on 16 bytes; so, every row takes sizeof(float)*⟦cols⟧⁴ bytes.
;; Element at row /i/, column /j/ of the matrix is stored at location /addr + sizeof(float)*(i*⟦cols⟧⁴ + j)/
;; The Matrix struct is passed to and return from functions via registers.
;; On error, a matrix with field /addr/ equal to zero is returned
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
	;; save dimensions to stack to return them in the end
	push rdi
	mov [rsp+4], esi
	;; [rsp] = cols:rows

	;; calculate number of bytes needed for the matrix
	mov rax, rdi
	upto4 rsi
	mul rsi
	mov rsi, rax
	shl rsi, 4

	;; save the number of bytes to stack, because calling aligned_alloc will destroy the register
	push rsi

	;; allocate memory for the matrix
	alloc16

	;; fill the matrix with zeros
	mov rdi, rax
	pop rsi
	call bzero

	;; get dimensions from stack to return them
	pop rdx

	ret

;; void matrixDelete(Matrix {addr,rows,cols})
;; Deallocates memory for the matrix
;; input: rdi=addr, rsi=cols:rows
matrixDelete:
	jmp free

;; unsigned int matrixGetRows(Matrix {addr,rows,cols});
;; Returns number of rows
;; input: rdi=addr, rsi=cols:rows
;; output: rax=rows
matrixGetRows:
	mov eax, esi
	ret

;; unsigned int matrixGetRows(Matrix {addr,rows,cols});
;; Returns number of columns
;; input: rdi=addr, rsi=cols:rows
;; output: rax=cols
matrixGetCols:
	mov rax, rsi
	shr rax, 32
	ret

;; Calculates offset of the element at the given position
;; input: rsi=rows:cols, rdx=row, rcx=col
;; output: rcx = row*⟦cols⟧⁴ + col
%macro calculate_offset 0
	shr rsi, 32
	upto4 rsi
	mov eax, edx
	mul rsi
	add rcx, rax
%endmacro

;; float matrixGet(Matrix e{addr,rows,cols}, unsigned int row, unsigned int col);
;; Returns element of the matrix at the given position
;; input: rdi=addr, rsi=cols:rows, rdx=row, rcx=col
;; output: xmm0=the element
matrixGet:
	calculate_offset
	movss xmm0, [rdi+4*rcx]
	ret

;; void matrixGet(Matrix e{addr,rows,cols}, unsigned int row, unsigned int col, float value);
;; Sets element of the matrix at the given position to the given value
;; input: rdi=addr, rsi=cols:rows, rdx=row, rcx=col, xmm0=value
matrixSet:
	calculate_offset
	movss [rdi+4*rcx], xmm0
	ret


;; Allocates a new matrix with given number of rows and cols and sets rbx to the offset of the last 4-element block in such matrix
;; input: rsi = cols:rows
;; output: rax = new_addr, rbx = rows*⟦cols⟧⁴-4
%macro allocate_and_move_to_end 0
	mov eax, esi
	shr rsi, 32
	upto4 rsi
	mul rsi
	lea rbx, [rax-4]
	lea rsi, [rax*4]

	alloc16
%endmacro
	
;; Matrix{new_addr,rows,cols} matrixScale(Matrix matrix{addr,rows,cols}, float k);
;; Multiplies every element of the matrix by k
;; input: rdi=addr, rsi=cols:rows, xmm0=0:0:0:k
;; output: rax=new_addr, rdx=cols:rows
matrixScale:	
	push rbx
	push r12

	;; save dimensions to return them in the end
	push rsi

	;; remember input matrix addr
	mov r12, rdi

	allocate_and_move_to_end

	;; clone k:
				; xmm0 = 0:0:0:k
	movsldup xmm0, xmm0	; xmm0 = 0:0:k:k
	unpcklps xmm0, xmm0	; xmm0 = k:k:k:k
	
	;; multiply all elements by k and write to the new matrix
.loop:
	movups xmm1, [r12+4*rbx]
	mulps xmm1, xmm0
	movups [rax+4*rbx], xmm1

	sub rbx, 4		; move to the previous 4-element block
	jae .loop
.end:
	pop rdx		    ; get dimensions from stack to return them

	pop r12
	pop rbx

	ret
	
;; Matrix{addr,rows,cols} matrixAdd(Matrix {addr1,rows1,cols1, Matrix {addr2,rows2,cols2});
;; Adds matrices
;; input: rdi=addr1, rsi=cols1:rows1, rdx=addr2, rcx=cols2:rows2
;; output: rax=addr, rdx=cols:rows
matrixAdd:	
	;; check dimensions
	cmp rsi, rcx
	je .dims_are_ok
.dims_are_bad:
	;; return zero
	xor rax, rax
	ret
.dims_are_ok:	
	push rbx
	push r12
	push r13

	;; save dimensions to stack to return them in the end
	push rsi

	;; remember the addrs
	mov r12, rdi
	mov r13, rdx

	allocate_and_move_to_end
	
	;; add all elements and write to the new matrix
.loop:
	movups xmm0, [r12+4*rbx]
	addps xmm0, [r13+4*rbx]
	movaps [rax+4*rbx], xmm0

	sub rbx, 4		; move to the prevous 4-element block
	jae .loop
.end:
	;; get dimensions from the stack to return them
	pop rdx

	pop r13
	pop r12
	pop rbx

	ret

;; Matrix{addr,rows,cols} matrixMul(Matrix {addr1,rows1,cols1}, Matrix {addr2,rows2,cols2});
;; Multiplies matrices
;; input: rdi=addr1, rsi=cols1:rows1, rdx=addr2, rcx=cols2:rows2
;; output: rax=addr, rdx=cols:rows
matrixMul:	
	;; check that cols1==rows2:
	mov rax, rsi
	shr rax, 32
	cmp eax, ecx
	je .dims_are_ok
.dims_are_bad:
	;; return zero
	xor rax, rax
	ret
.dims_are_ok:	
	push rbx
	push r12
	push r13
	push r14

	;; save result dimensions to stack to return them in the end
	push rcx
	mov [rsp], esi

	;; remember the addrs and cols2
	mov r12, rdi
	mov r13, rdx
	mov rbx, rcx

	;; Before calculating the product we calculate transposition of the second matrix
.allocate_transposition:
	;; calculate number of bytes needed for the transposed matrix
	mov eax, ecx
	upto4 rax
	mov r8, rcx
	shr r8, 32
	mul r8
	lea rsi, [rax*4]

	;; allocate memory for the transposed second matrix
	alloc16

	;; Calculate transposition of the second matrix:
.transpose:
	;; get number of columns in the original matrix
	mov rdx, rbx
	shr rdx, 32

	mov ecx, ebx		; set outer loop counter to the number of rows in the original numbers
	mov rsi, r13		; get addr of the original matrix

	;; get actual width of the tranposed matrix
	mov r11, rcx
	upto4 r11		; r11 = ⟦rows2⟧⁴

	xor r10, r10		; start from the first column of the transposed matrix
.transpose_row:
	mov r8, rdx		; reset inner loop counter to the number of columns in the original matrix
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
	;; calculate number of bytes needed for the product of matrices
	mov esi, [rsp+4]
	upto4 rsi
	mov eax, [rsp]
	mul rsi
	lea rsi, [rax*4]

	;; allocate memory for the product
	alloc16
	
	;; save the address for the product in r14
	mov r14, rax
	
.calculate:
	mov r8d, [rsp]		; reset .loop1 counter to the number of rows in the result

	;; get actual width the first matrix (= width of the transposed second matrix)
	mov ebx, ebx
	upto4 rbx		; rbx = ⟦cols1⟧

	;; for each row of the first matrix:
.loop1:				
	mov rdi, r13		; move to the first row of second matrix
	mov r9d, [rsp+4]	; reset .loop2 counter to the number of columns in the result matrix

	;; for each row of the transposed second matrix:
.loop2: 
	lea r10, [rbx-4]	; start from the right-most 4-element block
	xorps xmm0, xmm0	; zero the accumulator

	;; for each 4-element block:
.loop3:
	;; multiply elements of the block pointwise
	movaps xmm1, [r12+4*r10]
	mulps xmm1, [rdi+4*r10]
	;; add the product to the accumulator pointwise
	addps xmm0, xmm1

	sub r10, 4		; move to the previous 4-element block
	jae .loop3
.loop2_end:
	;; get sum of the products
	haddps xmm0, xmm0
	haddps xmm0, xmm0
	;; store the sum into the cell of the result matrix
	movss [rax], xmm0

	lea rdi, [rdi+4*rbx]	; move to the next row of the transposed second matrix
	add rax, 4		; move to the next cell of the result matrix
	sub r9, 1
	jnz .loop2
.loop1_end:
	lea r12, [r12+4*rbx]	; move to the next row of the first matrix
	
	upto16 rax		; move to the next row of the result matrix (see usage of 'upto16' in transposing for a more detailed explanation)
	sub r8, 1
	jnz .loop1

.end:
	mov rax, r14		; get the result matrix addr to return it
	pop rdx			; get the result dimensions to return them

	pop r14
	pop r13
	pop r12
	pop rbx

	ret
