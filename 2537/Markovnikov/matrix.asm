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

    ;; Matrix is kept in the array where first two cells are numbers of rows
    ;; and columns in the matrix. Every cell contains 4 bytes.

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
    ;;          RSI - number of columns
    ;; Returns: RAX - pointer to the matrix
    matrixNew:
        push rbx                    ; Save registers
        push rdi
        push rsi	
        mov rbx, rsi
        imul rbx, rdi               ; rbx = rows * columns = size of the matrix
        mov rdi, rbx
        add rdi, 2                  ; Two places for sizes of the matrix
        imul rdi, 4                 ; Every cell's size is size of float
        push rdi
        call malloc                 ; Malloc takes rdi and returns to rax
        pop rdi                     ; Return registers
        pop rsi
        pop rdi
        mov [rax], edi              ; Put rows number
        mov [rax + 4], esi          ; Put colomns number after
        fillWithValue 0             ; Fill the matrix with zeroes
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

    ;; Matrix matrixAdd(Matrix a, Matrix b)
    ;; Takes:   RDI - pointer to the matrix a
    ;;          RSI - pointer to the matrix b
    ;; Returns: RAX - ponter to (a + b)
    matrixAdd:
        push rdi                    ; Given matrices can not be changed
        push rsi

        mov rcx, 0
        mov rdx, 0
        mov ecx, [rdi]              ; Number of rows
        mov edx, [rdi + 4]          ; Number of columns
        
        mov rdi, rcx
        mov rsi, rdx
        call matrixNew              ; Put new matrix to rax
        mov rcx, rdi
        mov rdx, rsi
        pop rsi
        pop rdi

        push r10

        mov r10, rcx
        imul r10, rdx
        mov rcx, 0
        ; for (int i = 0; i < n * m; i += 4)
        .loop:
            add rcx, 4
            cmp rcx, r10
            jnle .loopFinish
            movups xmm0, [rdi + 4 * (rcx - 2)]
            movups xmm1, [rsi + 4 * (rcx - 2)]
            addps xmm0, xmm1
            movups [rax + 4 * (rcx - 2)], xmm0
            jmp .loop 
        .loopFinish:
            sub rcx, 4
            cmp rcx, r10
            jz .break
            movss xmm0, [rdi + 4 * (rcx + 2)]
            addss xmm0, [rsi + 4 * (rcx + 2)]
            movss [rax + 4 * (rcx + 2)], xmm0
            inc rcx
            add rcx, 4
            jmp .loopFinish
        .break:
        pop r10
        ret


