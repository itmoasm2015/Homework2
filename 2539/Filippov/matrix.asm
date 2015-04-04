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

; encodes cell (x, y) to (x * m + y + 2) * 4, stores it in RAX
; so, (%1 + RAX) is address of cell in memory at the end
; %1 -- pointer to matrix
; %2 -- x
; %3 -- y
%macro encodeCell 3 
    mov eax, %2             ; RAX = x
    imul eax, [%1 + 4]      ; [%1 + 4] is number of columns, so RAX = x * m 
    add eax, %3             ; RAX = x * m + y
    add eax, 2              ; RAX = x * m + y + 2
    shl eax, 2              ; RAX = (x * m + y + 2) * 4, (%1 + RAX) is address of cell in memory
%endmacro

; creates new matrix by other one and fills it zeroes
; %1 -- pointer to matrix
; returns pointer to new matrix, store it in RAX
%macro createNewMatrix 1 
    push %1                 ; saving matrix -- %1
    xor rcx, rcx            ; 
    mov ecx, [%1]           ; [%1] is number of rows, so [RCX] = n
    xor rsi, rsi            ; [%1 + 4] is number of columns, saving it to RSI
    mov esi, [%1 + 4]       ; 
    mov rdi, rcx            ; saving number of rows ([%1]) to RDI
    ; now we have number of rows in RDI, number of columns in RSI, can call matrixNew
    call matrixNew          ; matrixNew(RDI, RSI) creates new matrix stored in RAX
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
; Creates new matrix with n rows and m columns, filled with zeroes
; RDI -- n
; RSI -- m
; Stores matrix as (n * m + 2) * 4 consecutive bytes in memory -- first 8 is n and m,
; other are matrix
; cell (x, y) encoded to (x * m + y + 8) cell in memory
; return pointer to matrix storing in RAX
; saves RDI, RSI
matrixNew:
    mov r8, rdi             ; R8 = n
    imul r8, rsi            ; R8 = n * m
    mov r10, r8             ; R10 = n * m
    add r8, 2               ; R8 = n * m + 2
    shl r8, 2               ; R8 = (n * m + 2) * 4 - number of bytes in memory

    push rdi                ;
    push rsi                ; saving registers
    mov rdi, r8             ; parameter of malloc should be in rdi
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
    xor r9, r9              ; now cell, firstly R9 = 0
.fill_zeroes:
    mov dword [rax + r9 * 4], 0     ; RAX + R9 * 4 -- address of cell
    inc r9                          ; next R9
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
    mov rax, [rdi]          ; [RDI] is number of rows, moving it to RAX
    ret

; unsigned int matrixGetCols(Matrix matrix)
; matrix -- RDI
matrixGetCols:
    mov rax, [rdi + 4]      ; [RDI + 4] is number of colums, moving it to RAX
    ret

; float matrixGet(Matrix matrix, unsigned int x, unsigned int y)
; matrix -- RDI
; x -- RSI
; y -- RDX
; returns value storing in XMM0
matrixGet:
    encodeCell rdi, esi, edx            ; encoded cell address in (RDI + RAX) now
    movss xmm0, dword [rdi + rax]       ; answer in XMM0
    ret

; void matrixSet(Matrix matrix, unsigned int x, unsigned int y, float value)
; matrix -- RDI
; x -- RSI
; y -- RDX
; value -- XMM0
matrixSet:
    encodeCell rdi, esi, edx            ; encoded cell address in (RDI + RAX) now
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
    unpcklps xmm1, xmm1     ; now XMM1 equals to (k, k, 0, 0)
    unpcklps xmm1, xmm1     ; and now it equals to (k, k, k, k)

    matrixSize rdi          ; now RCX = n * m
    xor r8, r8              ; now cell number
.split_by_4_cells:
    add r8, 4                       ; now cell (R8) += 4
    cmp r8, rcx                         
    ja .multiply_remaining_cells    ; if it is out of bound of matrix, we need to multiply remaining cells
    ; address of cell is equal to [RDI + (R8 - 4) * 4 + 8] = [RDI + (R8 - 2) * 4]
    sub r8, 2                       ; so, let's subtract 2 from R8 (and add it at the end!)
    movups xmm2, [rdi + r8 * 4]     ; moving number at cell in R8 to XMM2
    mulps xmm2, xmm1                ; multiplying, using vector operation
    movups [rax + r8 * 4], xmm2     ; moving back, but now to RAX (new matrix)
    add r8, 2                       ; adding 2 back to R8
    jmp .split_by_4_cells           ; let's continue multiplying
.multiply_remaining_cells:           
    sub r8, 4                       ; R8 -= 4 - now it points to cell we are now at
    cmp r8, rcx                     ; if R8 is equal to n * m, then all is done
    je .finish                      ;
    add r8, 4                       ; R8 += 4, restoring
    movss xmm2, [rdi + r8 * 4 - 8]  ; moving old value to XMM2 (address is RDI + R8 * 4 + 8 = RDI + (R8 + 4) * 4 - 8
    mulss xmm2, xmm0                ; multipling, scalar operation
    movss [rax + r8 * 4 - 8], xmm2  ; moving result to RAX
    inc r8                          ; next cell
    jmp .multiply_remaining_cells
.finish:
    ret

; matrixAdd(Matrix a, Matrix b)
; returns pointer to new matrix -- sum of these two matrix
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
    push rsi                        ; RSI should be saved -- createNewMatrix changes it
    createNewMatrix rdi             ; new matrix, storing in RAX
    pop rsi                         ; restoring RSI

    ; we will sum groups of 4 cells
    ; and then sum remained cells
    matrixSize rdi          ; now RCX = n * m
    xor r8, r8              ; now cell number
.split_by_4_cells:
    add r8, 4                       ; now cell (R8) += 4
    cmp r8, rcx                         
    ja .sum_remaining_cells    ; if it is out of bound of matrix, we need to sum remaining cells
    ; address of cell is equal to [RDI + (R8 - 4) * 4 + 8] = [RDI + (R8 - 2) * 4]
    sub r8, 2                       ; so, let's subtract 2 from R8 (and add it at the end!)
    movups xmm0, [rdi + r8 * 4]     ; moving number at cell in first matrix to XMM0
    movups xmm1, [rsi + r8 * 4]     ; moving number at cell in second matrix to XMM1
    addps xmm0, xmm1                ; adding, using vector operation
    movups [rax + r8 * 4], xmm0     ; moving back, but now to RAX (new matrix)
    add r8, 2                       ; adding 2 back to R8
    jmp .split_by_4_cells           ; let's continue adding
.sum_remaining_cells:           
    sub r8, 4                       ; R8 -= 4 - now it points to cell we are now at
    cmp r8, rcx                     ; if R8 is equal to n * m, then all is done
    je .finish                      ;
    add r8, 4                       ; R8 += 4, restoring
    movss xmm0, [rdi + r8 * 4 - 8]  ; moving old value from first matrix to XMM0 (address is RDI + R8 * 4 + 8 = RDI + (R8 + 4) * 4 - 8
    movss xmm1, [rsi + r8 * 4 - 8]  ; moving old value from second matrix to XMM1
    addss xmm0, xmm1                ; adding, scalar operation
    movss [rax + r8 * 4 - 8], xmm0  ; moving result to RAX
    inc r8                          ; next cell
    jmp .sum_remaining_cells
.wrong_sizes:
    mov rax, 0
.finish:
    ret

matrixMul:
    ret
