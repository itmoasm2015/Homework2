extern malloc
extern free

default rel

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

;encodes cell (x, y) to (x * m + y + 2) * 4, stores it in RAX
; so, (%1 + RAX) is address of cell in memory at the end
; %1 -- pointer to matrix
; %2 -- x
; %3 -- y
%macro encodeCell 3 
    mov rax, %2             ; RAX = x
    imul eax, [%1 + 4]      ; [%1 + 4] is number of columns, so RAX = x * m 
    add rax, %3             ; RAX = x * m + y
    add rax, 2              ; RAX = x * m + y + 2
    shl rax, 2              ; RAX = (x * m + y + 2) * 4, (%1 + RAX) is address of cell in memory
%endmacro

; creates new matrix by other one and fills it with zeroes
; %1 -- pointer to matrix
; returns pointer to new matrix, storing in RAX
%macro createNewMatrix 1 
    push %1                 ; saving matrix -- %1
    push rsi                ; RSI may be pointer to matrix in some functions, we must save it
    push rdi                ; RDI may be pointer to matrix in some functions, we must save it
    xor rcx, rcx            ; 
    mov ecx, [%1]           ; [%1] is number of rows, so [RCX] = n
    xor rsi, rsi            ; [%1 + 4] is number of columns, saving it to RSI
    mov esi, [%1 + 4]       ; 
    mov rdi, rcx            ; saving number of rows ([%1]) to RDI
    ; now we have number of rows in RDI, number of columns in RSI, so we can call matrixNew
    call matrixNew          ; matrixNew(RDI, RSI) creates new matrix storing in RAX
    pop rdi                 ; restoring RDI
    pop rsi                 ; restoring RSI
    pop %1                  ; restoring matrix
%endmacro

; calculates matrix size by pointer to it
; stores result in RCX
; %1 -- pointer to matrix
; RCX - size of matrix (result)
%macro matrixSize 1
    xor rcx, rcx
    mov ecx, [%1]
    xor rdx, rdx
    mov edx, [%1 + 4]
    imul rcx, rdx
%endmacro    

; Matrix matrixNew(int n, int m)
; Creates new matrix with n rows and m columns and fills it with zeroes
; RDI -- n
; RSI -- m
; Stores matrix as (n * m + 2) * 4 consecutive bytes in memory -- first 8 is n and m respectively,
; other are matrix
; cell (x, y) -> cell (x * m + y + 8) in memory
; returns pointer to matrix storing in RAX
; saves RDI, RSI
matrixNew:
    mov r8, rdi             ; R8 = n
    imul r8, rsi            ; R8 = n * m
    mov r10, r8             ; R10 = n * m
    add r8, 2               ; R8 = n * m + 2
    shl r8, 2               ; R8 = (n * m + 2) * 4 - number of bytes in memory

    push rdi                ;
    push rsi                ; saving registers
    mov rdi, r8             ; parameter of malloc should be in RDI
    push r8                 ;
    push r10                ;
    call malloc             ; allocating memory for matrix
    pop r10                 ;
    pop r8                  ;    
    pop rsi                 ; restoring registers
    pop rdi                 ;
    
    mov [rax], rdi          ; moving n to RAX
    mov [rax + 4], rsi      ; moving m after n

    push rax                ; saving old RAX
    add rax, 8              ; RAX += 8 -- now cells have addresses [RAX + (x * m + y) * 4]
    xor r9, r9              ; cell we are now at, firstly R9 = 0
.fill_zeroes:
    mov dword [rax + r9 * 4], 0     ; RAX + R9 * 4 -- address of cell
    inc r9                          ; next cell
    cmp r9, r10                     ; if R9 is less than R10 (R10 = n * m), then continue
    jl .fill_zeroes         
    pop rax                 ; else -- break, restoring RAX             
    ret

; void matrixDelete(Matrix matrix)
; matrix -- RDI
matrixDelete:
    call free               ; calling free function (RDI is what we need, so we can simply call it)
    ret

; unsigned int matrixGetRows(Matrix matrix)
; matrix -- RDI
matrixGetRows:
    xor rax, rax
    mov eax, [rdi]          ; [RDI] is number of rows, moving it to RAX
    ret

; unsigned int matrixGetCols(Matrix matrix)
; matrix -- RDI
matrixGetCols:
    xor rax, rax
    mov eax, [rdi + 4]      ; [RDI + 4] is number of colums, moving it to RAX
    ret

; float matrixGet(Matrix matrix, unsigned int x, unsigned int y)
; matrix -- RDI
; x -- RSI
; y -- RDX
; returns matrix[x][y] storing in XMM0
matrixGet:
    encodeCell rdi, rsi, rdx            ; encoded cell address is in (RDI + RAX) now
    movss xmm0, dword [rdi + rax]       ; answer is in XMM0
    ret

; void matrixSet(Matrix matrix, unsigned int x, unsigned int y, float value)
; matrix -- RDI
; x -- RSI
; y -- RDX
; value -- XMM0
matrixSet:
    encodeCell rdi, rsi, rdx            ; encoded cell address is in (RDI + RAX) now
    movss dword [rdi + rax], xmm0       ; moving value (XMM0) to this address
    ret

; Matrix matrixScale(Matrix matrix, float k)
; creates new matrix with all elements multiplied by k
; matrix -- RDI
; k -- XMM0
; returns new matrix, storing in RAX
matrixScale:
    createNewMatrix rdi  

    ; we will multiply groups of 4 cells to k
    ; and then multiply remained cells

    ; first of all, let's create vector of four numbers k
    movss xmm1, xmm0        ; XMM1 = XMM0 = (k, 0, 0, 0)
    unpcklps xmm1, xmm1     ; and now XMM1 equals to (k, k, 0, 0)
    unpcklps xmm1, xmm1     ; and now it equals to (k, k, k, k)

    matrixSize rdi          ; now RCX = n * m
    xor r8, r8              ; cell number we are now at
.split_by_4_cells:
    add r8, 4                       ; now cell (R8) += 4
    cmp r8, rcx                         
    ja .multiply_remaining_cells    ; if it is out of bound of matrix, we need to multiply remaining cells
    ; address of cell equals to [RDI + (R8 - 4) * 4 + 8] = [RDI + (R8 - 2) * 4]
    sub r8, 2                       ; so, we will subtract 2 from R8 (and add it at the end!)
    movups xmm2, [rdi + r8 * 4]     ; moving number at cell we are now at to XMM2
    mulps xmm2, xmm1                ; multiplying, using vector operation
    movups [rax + r8 * 4], xmm2     ; moving back, but now to RAX (new matrix)
    add r8, 2                       ; adding 2 to R8 after subtracting
    jmp .split_by_4_cells           ; let's continue multiplying
.multiply_remaining_cells:           
    sub r8, 4                       ; R8 -= 4 - now it points to cell we are now at
    cmp r8, rcx                     ; if R8 is equal to n * m, then all is done
    je .finish                      ;
    add r8, 2                       ; R8 += 2, now address is equal to [RDI + R8 * 4]
    movss xmm2, [rdi + r8 * 4]      ; moving old value to XMM2 (address is RDI + (R8 - 2) * 4 + 8 = RDI + R8 * 4
    mulss xmm2, xmm0                ; multipling, scalar operation
    movss [rax + r8 * 4], xmm2      ; moving result to RAX
    inc r8                          ; next cell
    add r8, 2                       ; restoring old value of R8
    jmp .multiply_remaining_cells
.finish:
    ret

; Matrix matrixAdd(Matrix a, Matrix b)
; returns pointer to new matrix -- sum of these two matrixes
; if their sizes are wrong, returns 0
; a -- RDI
; b -- RSI
; return new matrix, storing in RAX
matrixAdd:
    ; let's check if sizes are wrong
    xor rcx, rcx
    xor rdx, rdx                    
    mov ecx, [rdi]                  ; RCX = a->n
    mov edx, [rsi]                  ; RDX = b->n
    cmp rcx, rdx                    ; if a->n != b->n then can't add, fail
    jne .wrong_sizes

    mov ecx, [rdi + 4]              ; RCX = a->m
    mov edx, [rsi + 4]              ; RDX = b->m
    cmp rcx, rdx                    ; if a->m != b->m then can't add, fail
    jne .wrong_sizes

    ; all is ok, we must find sum
    createNewMatrix rdi             ; new matrix, storing in RAX

    ; we will sum groups of 4 cells
    ; and then sum remained cells
    matrixSize rdi                  ; now RCX = n * m
    xor r8, r8                      ; cell number we are now at
.split_by_4_cells:
    add r8, 4                       ; now cell (R8) += 4
    cmp r8, rcx                         
    ja .sum_remaining_cells         ; if it is out of bound of matrix, we need to sum remaining cells
    ; address of cell is equal to [RDI + (R8 - 4) * 4 + 8] = [RDI + (R8 - 2) * 4]
    sub r8, 2                       ; so, let's subtract 2 from R8 (and add it at the end!)
    movups xmm0, [rdi + r8 * 4]     ; moving number at cell in first matrix to XMM0
    movups xmm1, [rsi + r8 * 4]     ; moving number at cell in second matrix to XMM1
    addps xmm0, xmm1                ; adding, using vector operation
    movups [rax + r8 * 4], xmm0     ; moving back, but now to RAX (new matrix)
    add r8, 2                       ; adding 2 to R8 after subtracting it
    jmp .split_by_4_cells           ; let's continue adding
.sum_remaining_cells:           
    sub r8, 4                       ; R8 -= 4 - now it points to cell we are now at
    cmp r8, rcx                     ; if R8 is equal to n * m, then all is done
    je .finish                      ;
    add r8, 2                       ; R8 += 2, address of cell is equal to [RDI + R8 * 4]
    movss xmm0, [rdi + r8 * 4]      ; moving old value from first matrix to XMM0 (address is RDI + R8 * 4 + 8 = RDI + (R8 + 4) * 4 - 8
    movss xmm1, [rsi + r8 * 4]      ; moving old value from second matrix to XMM1
    addss xmm0, xmm1                ; adding, scalar operation
    movss [rax + r8 * 4], xmm0      ; moving result to RAX
    add r8, 3                       ; restoring R8 and going to next cell (it is R8 += 2, R8 += 1)
    jmp .sum_remaining_cells
.wrong_sizes:
    xor rax, rax                    ; wrong sizes of matrixes, returning 0
.finish:
    ret

; Matrix matrixMul(Matrix a, Matrix b)
; multiplies two matrix if can
; if can't, returns 0
; if can, returns pointer to new matrix, storing in RAX
; a -- RDI
; b -- RSI
; returns pointer to product of a and b in RAX
matrixMul:
    ; if number of columns in a is not equal to number of rows in b, than we can't multiply matrixes (return 0)
    ; otherwise, we will transpose matrix b, and after that result[i][j] = row_a[i] * row_b[j]
    xor r8, r8                      ;
    mov r8d, [rdi + 4]              ; R8 = number of columns in a
    xor r9, r9                      ;
    mov r9d, [rsi]                  ; R9 = number of rows in b
    cmp r8, r9                      ; comparing it
    jne .wrong_sizes                ; if R8 != R9, than error, returning 0
.transpose:                         ; after that we need to transpose matrix b (RSI)
    mov r10, rsi                    ;
    createNewMatrix r10             ; creating new matrix (RAX), where result of transposition will be stored
    xor r10, r10                    ;
    mov r10, -1                     ; R10 is row of matrix b we are now at
.for_row
    inc r10                         ; next row
    cmp r10d, [rax]                 ; if number of row is equal to rows count, break
    je .swap_rows_and_columns       ; and swap numbers of rows and numbers of columns of new matrix
    xor r11, r11                    ; R11 is column of matrix b we are now at
.for_column
    cmp r11d, [rax + 4]             ; if number of colunm is equal to columns count, break
    je .for_row                     ; and go for next row

    push rax                        ; RAX -- our new matrix, need to save it
    mov rax, r11                    ; RAX = y
    imul eax, [rsi]                 ; RAX = y * n
    add rax, r10                    ; RAX = y * n + x -- it is encoded address of cell in tranposed matrix
    add rax, 2                      ; RAX = y * n + x + 2
    shl rax, 2                      ; RAX = (y * n + x + 2) * 4 -- final address
    mov rcx, rax                    ; remembering it to RCX
    pop rax                         ; restoring RAX

    push rax                        ; RAX -- our new matrix, need to save it
    encodeCell rsi, r10, r11        ; now RAX is encoded address of cell (R10, R11)
    mov rdx, rax                    ; remembering it to RDX
    pop rax                         ; restoring RAX

    push r12                        ; we must push R12 on stack due to calling conventions
    xor r12, r12                    
    mov r12d, [rsi + rdx]           ; R12 = b[R10][R11]
    mov [rax + rcx], r12d           ; writing R12 to RAX[R11][R10] -- transposed cell
    pop r12                         ; restoring R12
    inc r11                         ; next cell in row
    jmp .for_column                 ; let's continue with new cell
.swap_rows_and_columns:
    push r12                        ; we must push R12 on stack due to calling conventions
    xor r12, r12
    mov r12d, [rax]                 ; R12 = n
    push r13                        ; we must push R13 on stack due to calling conventions
    xor r13, r13                    
    mov r13d, [rax + 4]             ; R13 = m
    mov [rax], r13d                 ; 
    mov [rax + 4], r12d             ; swapping n and m -- moving n to [RAX + 4], m to [RAX]
    pop r13                         ; restoring R13
    pop r12                         ; restoring R12

    ; now let's delete matrix, stored in RSI, we don't need it anymore
    ;push rdi                        ; RDI is first matrix, we need to save it
    ;push rax                        ; RAX is pointer to new matrix, we need to save it
    ;mov rdi, rsi                    ; RDI = RSI -- preparing to call free function
    ;call free                       ; removing pointer to RSI
    ;pop rax                         ; restoring RAX
    ;pop rdi                         ; restoring RDI

    mov rsi, rax                    ; moving new matrix to RSI, now RSI is transposed matrix
.multiplying:
    ; we will multiply matrixes like in matrixScale, matrixAdd: first by groups of 4 cells and then other cells
    push rdi                        ; RDI is first matrix, need to save it
    push rsi                        ; RSI is second matrix, need to save it
    xor r8, r8                      ;
    mov r8d, [rdi]                  ; R8 = number of rows in result matrix
    xor r9, r9                      ;
    mov r9d, [rsi]                  ; R9 = number of colunms in result matrix
    mov rdi, r8                     ; RDI = R8
    mov rsi, r9                     ; RSI = R9
    call matrixNew                  ; can call matrixNew, now result matrix is in RAX
    pop rsi                         ; restoring RSI
    pop rdi                         ; restoring RDI
  
    xor r8, r8                      ; R8 is number of row we are now at
    mov r8, -1
.row_loop:
    inc r8                          ; next row
    cmp r8d, [rax]                  ; if now row is equal to matrix rows number then break
    je .finish                      
    xor r9, r9                      ; R9 is number of colunm we are now at
.column_loop:
    cmp r9d, [rax + 4]              ; is now column is equal to matrix columns number then next row
    je .row_loop

    push rax                        ; RAX is pointer to new matrix, need to save it
    xor rcx, rcx                    ; RCX = 0 -- y-coordinate
    encodeCell rdi, r8, rcx         ; encoding cell (R8, 0) in first matrix
    mov r10, rax                    ; it will be in R10
    pop rax                         ; restoring RAX

    push rax                        ; RAX is pointer to new matrix, need to save it
    xor rcx, rcx                    ; RCX = 0 -- y-coordinate
    encodeCell rsi, r9, rcx         ; encoding cell (R9, 0) in second matrix
    mov r11, rax                    ; it will be in R11
    pop rax                         ; restoring RAX

    ; now we need to calc RAX[R8][R9]
    ; RAX[R8][R9] = sum_j(RDI[R8][j] * RSI[R9][j]) -- easy to use vector operations
    xorps xmm2, xmm2                ; XMM2 = (0, 0, 0, 0)
    xorps xmm3, xmm3                ; XMM3 = (0, 0, 0, 0)
    xor rdx, rdx                    ; RDX = 0 -- number of cell in row
.cell_in_row:
    add rdx, 4                      ; taking 4 cells from row
    cmp edx, [rdi + 4]              ; if there are less than 4 cells remaining then we call silly multiplying
    ja .multiply_remaining_cells
    movups xmm0, [rdi + r10]        ; XMM0 = RDI[R8][RDX-4..RDX-1]
    movups xmm1, [rsi + r11]        ; XMM1 = RSI[R9][RDX-4..RDX-1]
    mulps xmm0, xmm1                ; XMM0 = XMM0 * XMM1, vector operation
    addps xmm2, xmm0                ; XMM2 -- global sum, updating it
    add r10, 16                     ; moving pointer for 4 * 4 bytes
    add r11, 16                     ; moving pointer for 4 * 4 bytes
    jmp .cell_in_row
.multiply_remaining_cells:
    sub rdx, 4                      ; 
    cmp edx, [rdi + 4]              ; if RDX - 4 == [RDI + 4] then all is done
    je .finish_row
    movss xmm0, [rdi + r10]         ; XMM0 = RDI[R8][RDI]
    movss xmm1, [rsi + r11]         ; XMM1 = RSI[R9][RDI]
    mulss xmm0, xmm1                ; XMM0 = xmm0 * XMM1, scalar operation
    addss xmm3, xmm0                ; XMM3 -- global sum, updating it
    add r10, 4                      ; moving pointer for 4 * 1 bytes
    add r11, 4                      ; moving pointer for 4 * 1 bytes
    add rdx, 5                      ; RDX += 4 + 1 - next cell
    jmp .multiply_remaining_cells
.finish_row:
                                    ; xmm2 = (t1, t2, t3, t4)
    haddps xmm2, xmm2               ; xmm2 = (t1 + t2, t3 + t4, t1 + t2, t3 + t4) 
    haddps xmm2, xmm2               ; xmm2 = ((t1 + t2 + t3 + t4) <4 times>)
    addss xmm3, xmm2                ; adding it to XMM3

    push rax                        ; RAX is pointer to result matrix, we need to save it
    mov rdx, rax                    ; RDX is temporary pointer to RAX
    encodeCell rdx, r8, r9          ; RAX -- encoded cell (R8, R9)
    mov rdx, rax                    ; RDX = RAX
    pop rax                         ; restoring RAX
    movss [rax + rdx], xmm3         ; writing result[R8][R9] (XMM3) to [RAX + RDX]

    inc r9                          ; next cell in row
    jmp .column_loop                ; let's go to new cell
    
.wrong_sizes:
    xor rax, rax                    ; wrong parameters, returning 0
.finish:
    ret
