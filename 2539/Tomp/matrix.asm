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
        shr rdx, ALIGNMENT_LOG
        mov rax, rdi

        movlhps xmm0, xmm0
        haddps xmm0, xmm0
.loop:
        add rdi, 16
        add rbx, 16
        movaps xmm1, [rbx]
        mulps xmm1, xmm0
        movaps [rdi], xmm1
        dec rdx
        test rdx, rdx
        jg .loop

        pop r13
        pop r12
        pop rbx
        ret

ALIGNMENT equ 4
ALIGNMENT_LOG equ 2
