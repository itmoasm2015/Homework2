section .text

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

extern calloc
extern malloc
extern free

; (x + 3) / 4 * 4 -- minimal y: y >= x && y % 4 == 0
%macro align4 1
    add %1, 3
    shr %1, 2
    shl %1, 2
%endmacro

; void getidx(matrix m, int i, int j, int &result);
%macro getidx 4
    push rax
    push rdx
    mov eax, [%1 + 4]
    align4 eax
    mul %2
    add eax, %3
    mov %4, eax
    pop rdx
    pop rax
%endmacro

; Matrix matrixNew(unsigned int rows, unsigned int cols);
; rows in edi
; cols in esi
; result: pointer to matrix in rax
matrixNew:    
    mov r8D, edi
    mov r9D, esi
    mov r10D, edi ; store rows to write to matrix 
    mov r11D, esi ; store cols to write to matrix

    align4 r8D ; r8D now is aligned rows  
    align4 r9D ; r8D now is aligned cols

    mov eax, r8D
    mul r9D ; rax now contains size of matrix
    
    lea rdi, [rax + 2]    
    mov rsi, 4
    push r10
    push r11
    call calloc ; return ptr to (rows * cols + 2) * 4 zero bytes
    pop r11
    pop r10
    mov [eax], r10D
    mov [eax + 4], r11D

    ret

; void matrixDelete(matrix matrix);
; ptr on matrix in rdi
matrixDelete:
    call free
    ret

; unsigned int matrixGetRows(matrix matrix);
; ptr on matrix in rdi
; result in eax
matrixGetRows:
    mov eax, [rdi]
    ret

; unsigned int matrixGetCols(matrix matrix);
; ptr on matrix in rdi
; result in eax
matrixGetCols:
    mov eax, [rdi + 4]
    ret

; float matrixGet(matrix matrix, unsigned int row, unsigned int col);
; args in rdi, esi, edx
; result in xmm0
matrixGet:
    mov eax, [rdi + 4]
    align4 eax ; eax now is real cols
    mov r9D, edx ; save edx
    mul esi
    add eax, r9D ; rax now is real pos in matrix: cols * row + col

    lea rax, [rdi + rax * 4 + 4 * 2] 
    movss xmm0, [rax]
    ret

; void matrixSet(matrix matrix, unsigned int row, unsigned int col, float value);
; args in rdi, esi, edx, xmm0
matrixSet:
    mov eax, [rdi + 4]
    align4 eax ; eax now is real cols
    mov r9D, edx ; save edx
    mul esi
    add eax, r9D ; rax now is real pos in matrix: cols * row + col

    movss [rdi + rax * 4 + 4 * 2], xmm0
    ret

; Matrix matrixScale(Matrix matrix, float k);
; args in rdi, xmm0
; result in rax
matrixScale
    push rbp
    push r12 ; store some used registers

    mov r12, rdi ; store ptr to matrix
    mov r8D, [rdi] ; store rows
    mov r9D, [rdi + 4] ; store cols
    mov edi, r8D 
    mov esi, r9D ; args to matrixNew
    push r8
    push r9 ; store r8, r9
    sub rsp, 4 ; store xmm0 in memory
    movss [rsp], xmm0
    call matrixNew
    movss xmm0, [rsp]
    add rsp, 4 ; return stack pointer
    mov rbp, rax ; store pointer to allocated memory
    pop r9
    pop r8

    align4 r8D
    align4 r9D ; r8 and r9 -- real matrix size
    
    unpcklps xmm0, xmm0 
    unpcklps xmm0, xmm0 ; xmm0 -- vector to multiply

    xor rax, rax ; rax = 0
    mov eax, r8D
    mul r9D ; rax = matrix size

    .loop
        sub rax, 4 ; iterate over 4 elements from the end of memory
        movups xmm1, [r12 + 4 * rax + 8]
        mulps xmm1, xmm0 ; multiply 4 elements by k
        movups [rbp + 4 * rax + 8], xmm1
        test eax, eax
        jnz .loop
    mov rax, rbp

    pop r12
    pop rbp
    ret

; Matrix matrixAdd(Matrix a, Matrix b);
; args in rdi, rsi
; result in rax
matrixAdd:
    push rbp
    push rbx
    push r12

    mov r8D, [rdi]
    mov r9D, [rsi]
    cmp r8D, r9D
    jne .notEqualDimensions
    mov r8D, [rdi + 4]
    mov r9D, [rsi + 4]
    cmp r8D, r9D
    jne .notEqualDimensions
    jmp .equalDimensions
    .notEqualDimensions    
        mov eax, 0
        pop r12
        pop rbx
        pop rbp
        ret        
.equalDimensions
    mov r8D, [rdi]

    mov rbp, rdi
    mov rbx, rsi
    mov edi, r8D
    mov esi, r9D
    push r8
    push r9
    call matrixNew
    pop r9
    pop r8
    mov r12, rax
   
    align4 r8D
    align4 r9D
    
    xor rax, rax
    mov eax, r8D
    mul r9D
    
    .loop
        sub rax, 4
        movups xmm0, [rbp + 4 * rax + 8]
        movups xmm1, [rbx + 4 * rax + 8]
        addps xmm0, xmm1
        movups [r12 + 4 * rax + 8], xmm0
        test eax, eax
        jnz .loop
    mov rax, r12

    pop r12
    pop rbx
    pop rbp
    ret

; Matrix matrixMul(Matrix a, Matrix b);
; args in rdi, rsi
; result in eax
matrixMul:
    push rbp
    push rbx
    push r12
    push r15

    mov r8D, [rdi + 4]
    mov r9D, [rsi]
    cmp r8D, r9D
    je .equalDimensions
        mov eax, 0
        pop r15
        pop r12
        pop rbx
        pop rbp
        ret        
.equalDimensions
    xor r10, r10
    mov r8D, [rdi]
    mov r9D, [rsi + 4]
    mov r10D, [rdi + 4]

    mov rbp, rdi
    mov rbx, rsi
    mov edi, r8D
    mov esi, r9D
    push r10
    call matrixNew
    pop r10
    mov r12, rax

    align4 r8D
    align4 r9D
    align4 r10D

    ; for j = b.m-1..0
    ;   for i = b.n-1..0
    ;     buf[i] = b[i][j]
    ;   for i = a.n-1..0
    ;     for k = a.m-1..0
    ;       res[i][j] += a[i][k] * buf[k]
    ; j = rsi, buf = rax, i = rdx, k = rdi
    ; a = rbp, b = rbx, res = r12

    ;mov edi, r10d
    lea edi, [r10 + 4 * r10]
    push r10
    call malloc
    pop r10
    
    xor rsi, rsi
    xor rdx, rdx
    xor rdi, rdi
    xor r11, r11
    xor r15, r15

    mov esi, [rbx + 4]
    .loop1
        dec esi
        mov edx, r10D
        .loop2
            dec edx
            getidx rbx, edx, esi, r11D
            mov r15D, [rbx + r11 * 4 + 8]
            mov [rax + rdx * 4], r15D
            test edx, edx
            jnz .loop2

        mov edx, [rbp]
        .loop3
            dec edx
            
            xorps xmm0, xmm0
            
            mov edi, r10D
            .loop4
                sub edi, 4

                getidx rbp, edx, edi, r11D
                movups xmm1, [rbp + r11 * 4 + 8]
                movups xmm2, [rax + rdi * 4]
                mulps xmm1, xmm2
                addps xmm0, xmm1

                test edi, edi
                jnz .loop4

            sub rsp, 16
            movups [rsp], xmm0
            xorps xmm0, xmm0
            movss xmm1, [rsp]
            addss xmm0, xmm1
            movss xmm1, [rsp + 4]
            addss xmm0, xmm1
            movss xmm1, [rsp + 8]
            addss xmm0, xmm1
            movss xmm1, [rsp + 12]
            addss xmm0, xmm1
            add rsp, 16
            
            getidx r12, edx, esi, r11D
            movss [r12 + r11 * 4 + 8], xmm0
    
            test edx, edx
            jnz .loop3

        test rsi, rsi
        jnz .loop1

    mov rdi, rax
    call free
    mov rax, r12

    pop r15
    pop r12
    pop rbx
    pop rbp
    ret
