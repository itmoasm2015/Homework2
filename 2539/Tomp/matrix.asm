extern aligned_alloc
extern free

%macro getAligned 1
        add %1, (ALIGNMENT - 1)
        and %1, ~(ALIGNMENT - 1)
%endmacro

%define getRows(r, m) mov r, [m]
%define getCols(r, m) mov r, [m + 4]

global matrixNew
matrixNew:
        push rbx
        push r12

        mov eax, edi ; rows
        mov ebx, eax
        mov edx, esi ; cols
        mov ecx, edx
        getAligned eax
        getAligned edx

        mul edx
        shl rdx, 32
        mov edx, eax
        lea rsi, [rdx + 3 * rdx + 16]
        mov r12, rcx
        mov rdi, 16
        call aligned_alloc
        mov [rax], ebx
        mov rcx, r12
        mov [rax + 4], ecx

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
        getAligned ecx
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
        call matrixNew
        mov rdi, rax
        mov rax, r12
        mov rcx, r13
        getAligned eax
        getAligned ecx
        mul ecx
        shl rdx, 32
        mov edx, eax
        mov rax, rdi

        movlhps xmm0, xmm0
        haddps xmm0, xmm0
.loop:
        movaps xmm1, [rbx + 4 * rdx]
        mulps xmm1, xmm0
        movaps [rdi + 4 * rdx], xmm1
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
        getAligned eax
        getAligned ebx
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
        xor eax, eax
.success:
        pop r14
        pop r13
        pop r12
        pop rbx
        ret

ALIGNMENT equ 4
