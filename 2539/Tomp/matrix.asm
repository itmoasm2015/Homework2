extern malloc
extern free

global matrixNew
matrixNew:
        push rbp
        mov rbp, rsp
        push rbx

        mov eax, edi ; rows
        mov ebx, eax
        mov edx, esi ; cols
        mov ecx, edx

        test al, MASK_OMIT
        jz .loadHeight
        add eax, ALIGNMENT
        and eax, MASK_REST
.loadHeight:
        test dl, MASK_OMIT
        jz .allocate
        add edx, ALIGNMENT
        and edx, MASK_REST
.allocate:
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

%define getRows(r, m) mov r, [m]
%define getCols(r, m) mov r, [m + 4]

global matrixGetRows
matrixGetRows:
        getRows(eax, rdi)
        ret

global matrixGetCols
matrixGetCols:
        getCols(eax, rdi)
        ret

ALIGNMENT equ 16
MASK_OMIT equ ALIGNMENT - 1
MASK_REST equ ~MASK_OMIT
