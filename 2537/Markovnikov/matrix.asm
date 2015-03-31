section .text
	extern malloc
	extern free

	global matrixNew
	global matrixDelete
	global matrixSet
	global matrixGet
	global matrixGetRows
	global matrixGetCols
	global matrixAdd
	global matrixScale
	global matrixMul

	;; Fill the matrix with some value
	%macro fillWithValue 1
		mov rcx, 0
		.fill_value:
			mov dword[rax + 4 * (rcx + 2)], %1
			inc rcx
			cmp rcx, rbx
			jne .fill_value
	%endmacro

	;; Matrix matrixNew(unsigned int rows, unsigned int columns)
	;; Takes:   RDI - number of rows
	;;			RSI - number of columns
	;; Returns:	RAX - pointer to the matrix
	matrixNew:
		push rbx					; Save registers
		push rdi
		push rsi	
		mov rbx, rsi
		imul rbx, rdi				; rbx = rows * columns = size of the matrix
		mov rdi, rbx
		add rdi, 2					; Two places for sizes of the matrix
		imul rdi, 4					; Every cell's size is size of float
		push rdi
		call malloc					; Malloc takes rdi and returns to rax
		pop rdi						; Return registers
		pop rsi
		pop rdi
		mov [rax], edi			    ; Put rows number
		mov [rax + 4], esi	        ; Put colomns number after
		fillWithValue 0			    ; Fill the matrix with zeroes
		pop rbx
		ret

	;; unsigned int matrixGetRows(Matrix matrix)
	;; Takes:   RDI - pointer to the matrix
	;; Returns: RAX - number of rows in the matrix
	matrixGetRows:
		mov rax, [rdi]
		ret

	;; unsigned int matrixGetCols(Matrix matrix)
	;; Takes:   RDI - pointer to the matrix
	;; Returns: RAX - number of columns in the matrix
	matrixGetCols:
		mov rax, [rdi + 4]
		ret
	
	;; void matrixDelete(Matrix matrix)
	;; Takes:   RDI - pointer to the matrix
	matrixDelete:
		call free
		ret

    ;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
    ;; Takes:   RDI - pointer to the matrix
    ;;          RSI - row
    ;;          RDX - col
    ;; Returns: XMM0 - number in the cell [rsi][rdx]
    matrixGet:
        mov rax, 0
        mov eax, esi
        push rcx                    ; Save rcx because of convension
        mov rcx, 0
        mov ecx, [rdi + 4]
        imul eax, ecx

        pop rcx

        add eax, edx                ; eax = row * rowsCount + col = place in our array
        movss xmm0, [rdi + 4 * (rax + 2)]
        ret
    
    ;; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
    ;; Takes:   RDI - pointer to the matrix
    ;;          RSI - row
    ;;          RDX - col
    ;;          XMM0 - value to set
    matrixSet:
        mov rax, 0
        mov eax, esi
        push rcx
        mov rcx, 0
        mov ecx, [rdi + 4]
        imul eax, ecx

        pop rcx

        add eax, edx                ; eax = row * rowsCount + col = place in our array
        movss [rdi + 4 * (rax + 2)], xmm0
        ret
