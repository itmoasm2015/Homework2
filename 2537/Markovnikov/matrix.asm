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
    global matrixTranspose
    
    ;; Matrix (n x m) is kept in the array where first two cells are numbers of rows
    ;; and columns in the matrix. Every cell contains 4 bytes.
    ;; [n][m][data (the first row, the second row, etc)]
    
    ;; Fills the matrix with some value
    %macro fillWithValue 1
        mov rcx, 0
        .fill_value:
            mov dword[rax + 4 * (rcx + 2)], %1
            inc rcx
            cmp rcx, rbx
            jne .fill_value
    %endmacro

    ;; Creates the matrix of a given sizes
    %macro createMatrix 0
        push rdi
        push rsi
        mov rcx, 0
        mov rdx, 0
        mov ecx, [rdi]              ; Number of rows
        mov edx, [rdi + 4]          ; Number of column
        mov rdi, rcx
        mov rsi, rdx
        call matrixNew              ; Put new matrix to rax
        mov rcx, rdi
        mov rdx, rsi
        pop rsi
        pop rdi
    %endmacro

    ;; Matrix matrixNew(unsigned int rows, unsigned int columns)
    ;;      Creates a new matrix with given numbers of rows and columns
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
    ;;      Returns the number of rows in the matrix
    ;; Takes:   RDI - pointer to the matrix
    ;; Returns: RAX - number of rows in the matrix
    matrixGetRows:
        mov rax, [rdi]
        ret

    ;; unsigned int matrixGetCols(Matrix matrix)
    ;;      Returns the number of columns in the matrix
    ;; Takes:   RDI - pointer to the matrix
    ;; Returns: RAX - number of columns in the matrix
    matrixGetCols:
        mov rax, [rdi + 4]
        ret

    ;; void matrixDelete(Matrix matrix)
    ;;      Frees a memory which was used by the matrix
    ;; Takes:   RDI - pointer to the matrix
    matrixDelete:
        call free
        ret

    ;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
    ;;      Returns the value in a given cell in the matrix
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
    ;;      Set the value to a given cell in the matrix
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
    ;;      Returns the sum of two matrices or returns null if it's impossible
    ;; Takes:   RDI - pointer to the matrix a
    ;;          RSI - pointer to the matrix b
    ;; Returns: RAX - ponter to (a + b)
    matrixAdd:
        push rbx                    ; Check sizes
        push rdx
        mov rbx, 0
        mov rdx, 0
        mov ebx, [rdi]
        mov edx, [rsi]
        jne .returnNull
        jmp .moreCheck
        .returnNull:
            pop rdx
            pop rbx
            mov rax, 0
            ret
        .moreCheck:
        mov ebx, [rdi + 4]
        mov edx, [rsi + 4]
        jne .returnNull
        pop rdx
        pop rbx
        
        createMatrix

        push r10
        mov r10, rcx
        imul r10, rdx               ; Count a size of the matrix
        mov rcx, 0
        ; for (int i = 0; i < n * m; i += 4)
        .loop:
            add rcx, 4
            cmp rcx, r10
            jnle .loopFinish
            movups xmm0, [rdi + 4 * (rcx - 2)]  ; Move packed 4 cells from the first matrix
            movups xmm1, [rsi + 4 * (rcx - 2)]  ; ... from the second
            addps xmm0, xmm1                    ; Add vectors
            movups [rax + 4 * (rcx - 2)], xmm0  ; Return result
            jmp .loop 
        .loopFinish:
            sub rcx, 4
            cmp rcx, r10
            jz .break
            movss xmm0, [rdi + 4 * (rcx + 2)]   ; Scalar mov
            addss xmm0, [rsi + 4 * (rcx + 2)]
            movss [rax + 4 * (rcx + 2)], xmm0
            inc rcx
            add rcx, 4
            jmp .loopFinish
        .break:
        pop r10
        ret
    
    ;; Matrix matrixScale(Matrix matrix, float k);
    ;;      Returns a result of muliplication of a given matrix and the number
    ;; Takes:   RDI - pointer to the matrix
    ;;          XMM0 - k
    ;; Returns: RAX - pointer to the matrix
    matrixScale:

        createMatrix

        push r10
        mov r10, 0
        mov r10, rcx
        imul r10, rdx                   ; Count a size
        mov rcx, 0
        movss xmm2, xmm0

        shufps xmm2, xmm2, 0            ; Create the 4-vector of k

        .loop2:
            add rcx, 4
            cmp rcx, r10
            jnle .loopFinish2
            movups xmm1, [rdi + 4 * (rcx - 2)]  ; Move packed data
            mulps xmm1, xmm2                    ; Multiply vectors
            movups [rax + 4 * (rcx - 2)], xmm1  ; Return result
            jmp .loop2
        .loopFinish2:
            sub rcx, 4
            cmp rcx, r10
            jz .break2
            movss xmm2, [rdi + 4 * (rcx + 2)]   ; Scalar
            mulss xmm2, xmm0
            movss [rax + 4 * (rcx + 2)], xmm2
            inc rcx
            add rcx, 4
            jmp .loopFinish2
        .break2:
        pop r10
        ret

    ;; Matrix matrixTranspose(Matrix a)
    ;;      Returns a transposed matrix of the given matrix
    ;; Takes:   RDI - pointer to a
    ;; Returns: RAX - pointer to transposed matrix
    matrixTranspose:
        ; rdi - matrix (n x m)
        push r13
        mov r13, rdi

        push rdi
        push rsi
        push rbp
        push rbx

        mov rcx, 0
        mov rdx, 0
        mov ecx, [rdi]              ; Number of rows
        mov edx, [rdi + 4]          ; Number of column
        mov rdi, rdx                ; rdi = m
        mov rsi, rcx                ; rsi = n
        call matrixNew              ; Put new matrix (m x n) to rax
        mov rcx, 0
        ; for (int i = 0; i < n; i++)
        .loop:
            mov rdx, 0
            ; for (int j = 0; j < m; j++)
             .loop2:
                mov rbx, rcx        ; rbx = i
                imul rbx, rsi       ; rbx = i * n
                add rbx, rdx        ; rbx = i * n + j
                mov rbp, rdx        ; rbp = j
                imul rbp, rdi       ; rbp = j * m
                add rbp, rcx        ; rbp = j * m + i
                mov r10d, [r13 + rbp * 4 + 8]
                mov [rax + rbx * 4 + 8], r10d
                inc rdx
                cmp rdx, rsi
                jne .loop2
            inc rcx
            cmp rcx, rdi
            jne .loop

        pop rbx
        pop rbp
        pop rsi
        pop rdi     
        pop r13

        ret


    ;; Matrix matrixMul(Matrix a, Matrix b)
    ;;      Multiplies two matrices or returns null if it's impossible
    ;; Takes:   RDI - pointer to a (n x m)
    ;;          RSI - pointer to b (m x q)
    ;; Returns: RAX - pointer to the result
    matrixMul:
        push rbx                 ; Check sizes     
        push rdx
        mov ebx, [rdi + 4]
        mov edx, [rsi]
        cmp ebx, edx
        jne .returnNull
        jmp .continue
       .returnNull:
            pop rdx
            pop rbx
            mov rax, 0
            ret
        .continue:

        pop rdx                     ; Save registers because of convension
        pop rbx
        push rbp
        push rbx
        push r12
        push r13

        push rdi
        push rsi

        mov r12, rdi                ; r12 = a
        mov r13, rsi                ; r13 = b

        mov rdi, rsi
        call matrixTranspose        ; Put transposed b to rax
        mov r11, rax                ; r11 = b^T

        mov rdi, 0
        mov edi, [r12]
        mov rsi, 0
        mov esi, [r13 + 4]

        push r11
        push r12
        push r13
        call matrixNew              ; Put the result to rax
        pop r13
        pop r12
        pop r11

        mov r9, 0
        mov r9d, [r12 + 4]          ; r9 = m
        mov rcx, 0
        ; for (int i = 0; i < n; i++)
        .loop:
            mov rdx, 0
            ; for (int j = 0; j < q; j++)
            .loop2:
                mov rbx, 0
                mov rbx, rcx    ; rbx = i
                imul rbx, r9    ; rbx = i * m
                mov rbp, 0
                mov rbp, rdx    ; rbp = j
                imul rbp, r9    ; rbp = j * m
                mov r10, 0
                xorps xmm1, xmm1
                xorps xmm0, xmm0
                xorps xmm2, xmm2
                xorps xmm3, xmm3
                ; for (int k = 0; k < m; k += 4)
                .loop3:
                    add r10, 4
                    cmp r10, r9
                    jg .break
                    movups xmm2, [r12 + 4 * (rbx + 2)]  ; a[i][k]
                    movups xmm1, [r11 + 4 * (rbp + 2)]  ; b^T[j][k]

                    dpps xmm1, xmm2, 0xF1               ; xmm1 = sum(a[i][k] * b^T[j][k])

                    addss xmm0, xmm1                    ; xmm0 = res[i][j] += xmm1
                    add rbx, 4                          ; Take next cell
                    add rbp, 4
                
                    jmp .loop3
                .break: 
                movups xmm3, xmm0                       ; Save the value
                sub r10, 4
                xorps xmm1, xmm1
                .loop3Finish:                           ; Count next cells
                    cmp r10, r9
                    je .breakFinish
                    movss xmm0, [r12 + 4 * (rbx + 2)]
                    mulss xmm0, [r11 + 4 * (rbp + 2)]
                    addss xmm1, xmm0
                    inc r10

                    inc rbx
                    inc rbp

                    jmp .loop3Finish
                .breakFinish:

                    addss xmm1, xmm3                    ; Add results

                    mov r10, rcx
                    imul r10, rsi
                    add r10, rdx
                    movss [rax + 4 * (r10 + 2)], xmm1   ; Write the result to rax
                    inc rdx
                    cmp rdx, rsi
                    jne .loop2
                inc rcx
                cmp rcx, rdi
                jne .loop
            push rax
            mov rdi, r11

            call matrixDelete

            pop rax
            .exi
            
            pop rsi
            pop rdi
            pop r13
            pop r12
            pop rbx
            pop rbp
        ret

