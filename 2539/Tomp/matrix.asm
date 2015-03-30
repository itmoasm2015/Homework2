extern malloc
extern free

%macro getAligned 1
        add %1, (ALIGNMENT - 1)
        and %1, ~(ALIGNMENT - 1)
%endmacro

%define getRows(r, m) mov r, [m]
%define getCols(r, m) mov r, [m + 4]

global matrixNew
matrixNew:
        push rbp
        mov rbp, rsp
        push rbx

        mov eax, edi ; rows
        mov ebx, eax
        mov edx, esi ; cols
        mov ecx, edx
        getAligned eax
        getAligned edx

        mul edx
        shl rdx, 32
        mov edx, eax
        lea rdx, [rdx + 3 * rdx + 8]
        push rcx
        mov rdi, rdx
        call malloc
        pop rcx
        mov [rax], ebx
        mov [rax + 4], ecx

        pop rbx
        mov rsp, rbp
        pop rbp
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
        lea rdi, [rdi + 4 * rdx + 8]
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

ALIGNMENT equ 4
