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


	;; Matrix structure
	;; 	rows - declared number of rows
	;; 	cols - declared number of cols
	;; 	real_rows - real number of rows (=rows ceiled by 4)
	;; 	real_cols - real number of cols (=cols ceiled by 4)
	;; 	cells - address of the beginning of cells array

                    struc   Matrix
rows:               resq    1
cols:               resq    1
real_rows:          resq    1
real_cols:          resq    1
cells:              resq    1
                    endstruc

	;; Macro for ceiling by 4
	;; Takes:
	;; 	%1 - destination
	;; 	%2 - ceiling number
	;; Returns:
	;; 	%1 = (%2 - 1) /4 * 4 + 4 = ceil(%2) by 4.
	
%macro ceil 2
	mov %1, %2
	dec %1
	shr %1, 2
	shl %1, 2
	lea %1, [%1 + 4]
%endmacro
	
	;; casn (Cells ASSigN)
	;; Macro for assignment the %3 value for all cells in matrix
	;; Takes:
	;; 	%1 - address of the first cell in cells array
	;; 	%2 - number of cells
	;; 	%3 - assigned value
	;; Uses:
	;; 	rdi, rcx, rax - rep requirements
	;; Returns:
	;; 	%1 - array of cells, valueted by %3
%macro casn 3
	mov rdi, %1
	mov rcx, %2
	mov eax, %3
	cld
	rep stosd
%endmacro
	
	;;  Matrix matrixNew(unsigned int rows, unsigned int cols);
	;;  creates new matrix (rdi*rsi)
	;;  Takes:
	;;  	RDI - number of rows
	;;  	RSI - number of cols 
	;;  Returns:
	;;   	RAX - new matrix
	;;  Uses:
	;;	R8 - Matrix
	;; 	R10 - temp variable for rows
	;; 	R11 - temp variable for cols
matrixNew:		push	rdi
        		push	rsi
        		mov	rdi, Matrix_size
        		call	malloc
        		mov 	r8, rax
        		pop	rsi
        		pop	rdi
        		mov	[r8 + rows], rdi
        		mov	[r8 + cols], rsi
			ceil	rdi, rdi
      			ceil	rsi, rsi
        		mov	[r8 + real_rows], rdi
        		mov	[r8 + real_cols], rsi
        		imul	rdi, rsi
        		shl	rdi, 4
        		push	rdi
        		push	r8
        		call	malloc
        		pop	r8
			mov	[r8 + cells], rax
        		pop	r9
        		shr	r9, 2
			casn	rax, r9, 0
        		mov	rax, r8
        		ret


	;;  Matrix matrixCopy(Matrix matrix);
	;;  clones the [rdi] matrix
	;;  Takes:
	;;   	RDI - matrix
	;;  Returns:
	;;  	RAX - new Matrix (=RDX)
	;;  Uses:
	;;  	R8 - Matrix matrix (=RDI)

matrixCopy:	mov	r11, [rdi + cols]
		mov	r10, [rdi + rows]
		mov	r12, rdi
		mov	rdi, r10
		mov	rsi, r11
		push	r12
		call	matrixNew
		pop	r12

		mov	rcx, [r12 + real_rows]
		imul	rcx, [r12 + real_cols]
		mov	rsi, [r12 + cells]
		mov	rdi, [rax + cells]
		cld
		rep	movsd
		ret

	;;void matrixDelete(Matrix matrix);
	;;Delletes the [rdi] matrix
	;;Takes:
	;;	RDI -  matrix

matrixDelete:	push	rdi
		mov	rdi, [rdi + cells]
		call	free
		pop	rdi
		call	free
		ret


	;;unsigned int matrixGetRows(Matrix matrix);
	;; 
	;;returns the number of rows in [rdi] matrix
	;;Takes:
	;;	RDI - Matrix matrix
	;;Returns:
	;;	RAX - matrix.rows

matrixGetRows:	mov	rax, [rdi + rows]
	        ret



	;;unsigned int matrixGetCols(Matrix matrix);
	;;
	;;returns the number of cols in [rdi] matrix
	;;Takes:
	;;	RDI - Matrix matrix
	;;Returns:
	;;	RAX - matrix.cols

matrixGetCols:	mov	rax, [rdi + cols]
	        ret




	;;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
	;;
	;;Returns the current cell in cells array
	;;Takes:
	;;	RDI - matrix
	;;	RSI - number of the row
	;;	RDX - number of the col
	;;Returns:
	;;	XMM0 - cells[RSI, RDX]
	;;Uses:
	;;	R10 - matrix.cells
	;;	R11 - index
	;; 	R12 - temporary variable

matrixGet:	push	r10
		push	r11
		push	r12
		mov	r12, rdi
		mov	r11, [r12 + real_cols]
		imul	r11, rsi
		lea	r11, [r11 + rdx]
		mov	r10, [r12 + cells]
		movss	xmm0, [r10 + r11*4]
		pop	r12
		pop	r11
		pop	r10
		ret

	;;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)			;
	;;
	;;sets the value of the current cell to 'value'
	;;Takes:
	;;	RDI - matrix
	;;	RSI - number of row
	;;	RDX - number of  col
	;;	XMM0 - float value
	;;Uses:
	;;	R10 - matrix.cells
	;;	R12 - index
	;; 	R11 - temporary variable

matrixSet:	push	r10
		push	r11
		push	r12
		mov	r12, rdi
		mov	r11, [r12 + real_cols]
	        imul	r11, rsi
		lea	r11, [r11 + rdx]
		mov	r10, [r12 + cells]
		movss	[r10 + r11*4], xmm0
		pop	r12
		pop	r11
		pop	r10
		ret


	;;Matrix matrixScale(Matrix matrix, float k);
	;;
	;;Scales given matrix according tho the given coefficient (k)
	;;Takes:
	;;	RDI - matrix
	;;	XMM0 - scale coefficient
	;;Returns:
	;;	RAX - scaled matrix
	;;Uses:
	;;	R9 - pointer to the first cell in quartas of cells for SLL operations
	;;	R10 - temporary variable

matrixScale:	shufps	xmm0, xmm0, 0
		call	matrixCopy
		mov	r8, rax
		mov	r10, [r8 + cells]
		mov	r9, [r8 + real_rows]
		imul	r9, [r8 + real_cols]
		shr	r9, 2	;splitting all cells by quartas

.loop		movups	xmm1, [r10]
		mulps	xmm1, xmm0
		movups	[r10], xmm1
		lea	r10, [r10 + 16]
		dec	r9
		jnz	.loop
		mov	rax, r8
		ret


;;Helping macro which adds four cells of one matrix to another
%macro add4cl 2
	movups	xmm0, [%1]
	addps	xmm0, [%2]
	movups	[%1], xmm0
%endmacro

	;;  Matrix matrixAdd(Matrix a, Matrix b);
	;;
	;;  Takes:
	;;    RDI - matrix a
	;;    RSI - matrix b
	;;  Returns:
	;;    RAX - sum of the matrix a and matrix b
	;;  Uses:
	;;    RCX - pointer to the quarta of cells for SSL operations
	;;    RDX - pointer to the cell of matrix
	;;    R8 - temporary variable
	;;    R9 - temporary variable
matrixAdd:	mov	r8,[rdi + cols]
		mov	r9, [rsi + cols]
		cmp	r8, r9	;	if matrix a has
		jne	.fail	;	another number of
		mov	r8, [rdi + rows] ;	cols or rows
		mov	r9, [rsi + rows] ;	then we willn't
		cmp	r8, r9	     ;  sum this matrix
		jne	.fail
		push	rsi
		call	matrixCopy
		pop	rsi
		mov	rcx, [rax + real_cols]
		imul	rcx, [rax + real_rows]
		shr	rcx, 2		;	splitting cells by quartas
		mov	rdx, [rax + cells]
		mov	r8, [rsi + cells]
.loop		add4cl	rdx, r8
		lea	rdx, [rdx + 16]
		lea	r8, [r8 + 16]
		dec	rcx
		jnz	.loop
		ret
.fail		xor rax, rax
		ret

	;; qtrp (Quanta TRansPose)
	;; Helping macro for transposing one quarta. Used for fast SSL matrix transposition
%macro qtrp 3
	movups xmm0, [%2]
	movss [%3], xmm0
	psrldq xmm0, 4
	lea %3, [%3 + %1 * 4]
	movss [%3], xmm0
	psrldq xmm0, 4
	lea %3, [%3 + %1 * 4]
	movss [%3], xmm0
	psrldq xmm0, 4
	lea %3, [%3 + %1 * 4]
	movss [%3], xmm0
	lea %3, [%3 + %1 * 4]
%endmacro

	;; Matrix matrixTranspose(Matrix matrix)
	;; Transposes the given matrix. Not the part of the task but it gives us an opportunity to use
	;; SSL operations in matrixMul simplier then without transposition
	;; Takes:
	;; 	RDI - matrix
	;; Returns:
	;; 	RAX - transposed matrix
matrixTranspose:
		push	rdi
		mov	rsi, [rdi + rows]
		mov	rdi, [rdi + cols]
	        call	matrixNew
	        pop	rdi
	        mov	r8, [rax + real_cols]
	        mov	r9, [rax + real_rows]
	        mov	r10, [rdi + cells]
		mov	rdi, [rax + cells]

	        xor	rcx, rcx
.loop_1:	xor	rdx, rdx
	        lea	r11, [rdi + rcx * 4]
.loop_2:	qtrp	r8, r10, r11
		lea	rdx, [rdx + 4]
	        lea	r10, [r10 + 16]
	        cmp	rdx, r9
	        jb	.loop_2
	        inc	rcx
	        cmp	rcx, r8
	        jb	.loop_1
	        ret

	;; scpr (SCalar PRoduction)
	;; scalar production of two 4-vectors
	;; helping macro, uses in matrixMul
	;; Takes:
	;; 	RDI - first 4-vector
	;; 	RSI - second 4-vector
	;; Uses:
	;; 	xmm0 - accumulator
	;; Returns:
	;; 	xmm0 - xmm0 += scalar production of rdi and rsi 4-vectors
%macro scpr 3
	movups 	xmm1, [%1 + r10]
        movups	xmm2, [%2 + r10]
        dpps	xmm1, xmm2, 0xF1
        addss	%3, xmm1
%endmacro

	;;Matrix matrixMul(Matrix a, Matrix b);
	;;
	;;Muls two matrix
	;;Takes:
	;;	RDI - Matrix a (m*n)
	;;	RSI - Matrix b (n*p)
	;;Returns:
	;;	RAX - Matrix c (m*p) = a * b
	;;Uses:
	;;	R8 - i
	;;	R9 - j
	;;	R10 - n
	;;	R11 - k
	;;	RBX - temporary variable 1
	;;	RBP - temporary variable 2
	;;	RDX - temporary variable 3
matrixMul:	mov	r8, [rdi + cols]
                mov	r9, [rsi + rows]
                cmp	r8, r9			; if num of colums of matrix a
                jne	.fail			; is differ from matrix b, then fail	
                push	rbx
                push	rbp
	;; transpose second matrix for better SSL using
        	push	rdi
                push	rsi
                mov	rdi, rsi
                call	matrixTranspose
                pop	rsi
                pop	rdi
	;; create template for new [m*p] matrix for result
                push	rax
                push	rdi
                mov	rdi, [rdi + rows]
                mov	rsi, [rsi + cols]
                call	matrixNew
                mov	rcx, [rax + cells]
                pop	rdi
                pop	rsi
	;; preparation before multiplication
		push	rsi
                mov	r8, [rdi + real_rows]
                mov	r9, [rsi + real_rows]
                mov	r10, [rdi + real_cols]
	        mov	rdi, [rdi + cells]
		mov	rsi, [rsi + cells]
		mov	rdx, rsi
		mov	rbx, r10
                shl	rbx, 2
		mov 	rbp, r9
        ;; for (i = m - 1; i >= 0; i--)
.loop_1:        mov	rsi, rdx
        	mov	r9, rbp
	;; for (j = p - 1; j >= 0; j--)
.loop_2:        xor 	r10, r10
                xorps	xmm0, xmm0
	;; for (k = 1; k<=n; shl k, 2)
.loop_3:        scpr	rdi, rsi, xmm0
                lea	r10, [r10 + 16]
		cmp	r10, rbx
                jne	.loop_3
                add	rsi, rbx
                movss	[rcx], xmm0
                lea	rcx, [rcx + 4]
                dec	r9
		jnz	.loop_2
                add	rdi, rbx
                dec	r8
                jnz	.loop_1
		pop	rdi
	;; delete transposed matrix
                push	rax
                call	matrixDelete
                pop	rax
                pop 	rbp
                pop	rbx
                ret
.fail:	        xor	rax, rax
                ret
