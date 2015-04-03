extern aligned_alloc
extern free

%define getAligned(a) alignNumber a, 4

%macro alignNumber 2
        add %1, (%2 - 1)
        and %1, ~(%2 - 1)
%endmacro

%define getRows(r, m) mov r, [m]
%define getCols(r, m) mov r, [m + 4]

global matrixNew
matrixNew:
        push rbx
        push r12
        push r13
        push rbp
        mov rbp, rsp

        mov eax, edi ; rows
        mov ebx, eax
        mov edx, esi ; cols
        mov ecx, edx
        getAligned(eax)
        getAligned(edx)

        mul edx
        shl rdx, 32
        mov edx, eax
        lea r13, [rdx + 3 * rdx]
        lea rsi, [r13 + 16]
        mov r12, rcx
        mov rdi, 16
        and rsp, ~15
        call aligned_alloc
        mov [rax], ebx
        mov rcx, r12
        mov [rax + 4], ecx

        xorps xmm0, xmm0
.loop:
        movaps [rax + r13], xmm0
        sub r13, 16
        jnz .loop

        mov rsp, rbp
        pop rbp
        pop r13
        pop r12
        pop rbx
        ret

global matrixDelete
matrixDelete: jmp free

global matrixGetRows
matrixGetRows:
        getRows(eax, rdi)
        ret

global matrixGetCols
matrixGetCols:
        getCols(eax, rdi)
        ret

%macro loadCellAddress 0
        ; rdi - address
        ; rsi - row
        ; rdx - column
        getCols(ecx, rdi)
        getAligned(ecx)
        lea rdi, [rdi + 4 * rdx + 16]
        mov eax, esi
        mul ecx
        shl rdx, 32
        mov edx, eax
        lea rdi, [rdi + 4 * rdx]
%endmacro

global matrixGet
matrixGet:
        loadCellAddress
        movss xmm0, dword [rdi]
        ret

global matrixSet
matrixSet:
        loadCellAddress
        movss dword [rdi], xmm0
        ret

global matrixScale
matrixScale:
        push rbx
        push r12
        push r13

        mov rbx, rdi
        getRows(edi, rbx)
        getCols(esi, rbx)
        mov r12, rdi
        mov r13, rsi
        movaps xmm1, xmm0
        call matrixNew
        mov rdi, rax
        mov rax, r12
        mov rcx, r13
        getAligned(eax)
        getAligned(ecx)
        mul ecx
        shl rdx, 32
        mov edx, eax
        mov rax, rdi

        shufps xmm1, xmm1, 0
.loop:
        movaps xmm0, [rbx + 4 * rdx]
        mulps xmm0, xmm1
        movaps [rdi + 4 * rdx], xmm0
        sub rdx, 4
        jnz .loop

        pop r13
        pop r12
        pop rbx
        ret

global matrixAdd
matrixAdd:
        push rbx
        push r12
        push r13
        push r14

        mov r12, rdi
        mov r13, rsi
        getRows(edi, r12)
        getRows(ecx, r13)
        cmp edi, ecx
        jne .badSizes
        getCols(esi, r12)
        getCols(ecx, r13)
        cmp esi, ecx
        jne .badSizes
        mov ebx, edi
        mov r14, rsi
        call matrixNew
        mov rdi, rax
        mov rax, r14
        getAligned(eax)
        getAligned(ebx)
        mul ebx
        shl rdx, 32
        mov edx, eax
        mov rax, rdi
.loop:
        movaps xmm0, [r12 + rdx * 4]
        addps xmm0, [r13 + rdx * 4]
        movaps [rdi + rdx * 4], xmm0
        sub rdx, 4
        jz .success
        jmp .loop
.badSizes:
        xor rax, rax
.success:
        pop r14
        pop r13
        pop r12
        pop rbx
        ret

%macro loadAndTranspose 3
        movaps xmm0, [%1]
        movaps xmm1, [%1 + 4 * %2]
        lea %3, [%1 + 8 * %2]
        movaps xmm2, [%3]
        movaps xmm3, [%3 + 4 * %2]
        movaps xmm4, xmm0
        movlhps xmm4, xmm1
        movaps xmm6, xmm2
        movlhps xmm6, xmm3
        movaps xmm5, xmm4
        shufps xmm4, xmm6, EVEN_POS
        shufps xmm5, xmm6, ODD_POS
        movaps xmm6, xmm1
        movhlps xmm6, xmm0
        movaps xmm8, xmm3
        movhlps xmm8, xmm2
        movaps xmm7, xmm6
        shufps xmm6, xmm8, EVEN_POS
        shufps xmm7, xmm8, ODD_POS
%endmacro

%macro loadAndMultiply 1
        movaps xmm3, [%1]
        movaps xmm0, xmm3
        mulps xmm0, xmm4
        movaps xmm1, xmm3
        mulps xmm1, xmm5
        movaps xmm2, xmm3
        mulps xmm2, xmm6
        mulps xmm3, xmm7
        haddps xmm0, xmm1
        haddps xmm2, xmm3
        haddps xmm0, xmm2
%endmacro

global matrixMul
matrixMul:
        push rbx
        push r12
        push r13
        push r14
        push r15

        mov r12, rdi
        mov r13, rsi
        xor rcx, rcx
        getCols(ecx, r12)
        mov r15, rcx
        getRows(edx, r13)
        cmp ecx, edx
        jne .badSizes
        xor rdi, rdi
        xor rsi, rsi
        getRows(edi, r12)
        getCols(esi, r13)
        mov r14, rdi
        mov rbx, rsi
        call matrixNew
        getAligned(r14)
        getAligned(rbx)
        getAligned(r15)
        add r12, 16
        add r13, 16
        ; r12 - 1st matrix
        ; r13 - 2nd matrix
        ; rax - result
        ; r14 - rows
        ; rbx - cols
        ; r15 - 1st matrix cols
        mov r11, r15
.col1:  mov r8, rbx
        lea rdi, [rax + 16]
.col2:  loadAndTranspose r13, rbx, rcx
        mov r9, r14
        mov r10, r12
        mov rdx, rdi
.row1:  loadAndMultiply r10
        lea r10, [r10 + 4 * r15]
        addps xmm0, [rdx]
        movaps [rdx], xmm0
        lea rdx, [rdx + 4 * rbx]
        sub r9, 1
        jnz .row1
; .row1 end
        add r13, 16
        add rdi, 16
        sub r8, 4
        jnz .col2
; .col2 end
        add r12, 16
        lea r13, [r13 + 4 * rbx]
        lea r13, [r13 + 8 * rbx]
        sub r11, 4
        jnz .col1
; .col1 end
        jmp .success
.badSizes:
        xor rax, rax
.success:
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        ret

ODD_POS equ (3 << 6) + (1 << 4) + (3 << 2) + 1
EVEN_POS equ (2 << 6) + (0 << 4) + (2 << 2) + 0
