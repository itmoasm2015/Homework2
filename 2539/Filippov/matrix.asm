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
; %1 is pointer to matrix
; %2 is x
; %3 is y
%macro encodeCell 3 
    mov rax, %2             ; RAX = x
    imul rax, [%1 + 4]      ; [%1 + 4] is number of columns, so RAX = x * m 
    add rax, %3             ; RAX = x * m + y
    add rax, 2              ; RAX = x * m + y + 2
    shl rax, 2              ; RAX = (x * m + y + 2) * 4, (%1 + RAX) is address of cell in memory
%endmacro

; void matrixNew(int n, int m)
; Creates new matrix with n rows and m columns, filled with zeroes
; RDI -- n
; RSI -- m
; Stores matrix as (n * m + 2) * 4 consecutive bytes in memory -- first 8 is n and m,
; other are matrix
; cell (x, y) encoded to (x * m + y + 8) cell in memory
; return pointer to matrix in RAX
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
    push rdi
    call free               ; calling free function
    pop rdi
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
; returns value stored in xmm0
matrixGet:
    encodeCell rdi, rsi, rdx  ; encoded cell address in (RDI + RAX) now
    movss xmm0, [rdi + rax]   ; answer in xmm0
    ret

; void matrixSet(Matrix matrix, unsigned int x, unsigned int y, float value)
; matrix -- RDI
; x -- RSI
; y -- RDX
; value -- xmm0
matrixSet:
    encodeCell rdi, rsi, rdx      ; encoded cell address in (RDI + RAX) now
    movss [rdi + rax], xmm0       ; moving value (xmm0) to this address
    ret

matrixScale:
    ret

matrixAdd:
    ret

matrixMul:
    ret
