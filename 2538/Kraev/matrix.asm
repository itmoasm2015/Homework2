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

; multipush
%macro mpush 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

;multipop
%macro mpop 1-*
    %rep %0
        %rotate -1
        pop %1
    %endrep
%endmacro

; save registers for some calls, like malloc
%macro x86_64_calle_push 0
    mpush rbp, rbx, r12, r13, r14, r15 
%endmacro

; restore them
%macro x86_64_calle_pop 0
    mpop rbp, rbx, r12, r13, r14, r15 
%endmacro

;nasm macros for plain structures
struc matrix

matrix_rows              resq 1
matrix_cols              resq 1
matrix_rows_aligned      resq 1
matrix_cols_aligned      resq 1 
matrix_ptr               resq 1 

endstruc

;zero memory with malloc
extern calloc
;malloc
extern malloc
extern free
;copy memory for matrixCopy
extern memcpy

section .text

;this macro makes number be  divided by 4 without reminder.
%macro align_4 1
   add %1, 3  ; add 0...11b
   and %1, ~3 ;flush last two binary digits.
%endmacro


;Matrix matrixNew(unsigned int rows, unsigned int cols);
; rax                      rdi                 rsi
matrixNew:
    enter 0, 0
    x86_64_calle_push

    mov r12, rdi    ;save rows for future
    mov r13, rsi    ;do this with cols
    mov rdi, matrix_size    ;nasm feature for det. of struct size.
    call malloc     ;
    test rax, rax   ; do we have enough memory?
    jz .end     
   
    mov r14, rax    ;save our allocated struct

    mov [r14 + matrix_rows], r12 ;fill rows of our struct
    mov [r14 + matrix_cols], r13 ;fill cols
    align_4 r12     ;precalc scaled rows
    mov [r14 + matrix_rows_aligned], r12 ;save rows 
    align_4 r13          ;prec. scaled cols
    mov [r14 + matrix_cols_aligned], r13 ;save them
    mov rax, r12 ;calc the whole size
    mul r13      ;
    
    mov rdi, rax ;we want our matrix to be zero-filled (amount param)
    mov rsi, 4 ;prepare for calloc (it is size of type param)
    call calloc
   
    test rax, rax ;Do we have enough memory?
    jz .calloc_fail
  
    mov [r14 + matrix_ptr], rax 
    mov rax, r14
    jmp .end
   
    .calloc_fail ;No.
    mov rdi, r14
    call free ;free our struct
    xor rax, rax ;return 0
    
    .end
    x86_64_calle_pop
    leave
    ret


;void matrixDelete(Matrix matrx)
matrixDelete:
    enter 0, 0
    x86_64_calle_push
    mov r12, rdi ;preparations for free
    mov rdi, [r12 + matrix_ptr];ptr to struct storage
    call free; just kill it!
    mov rdi, r12; and
    call free   ; another one
    x86_64_calle_pop   ;all done
    leave
    ret

;unsigned int matrixGetRows(Matrix matrix)
matrixGetRows:
    xor rax, rax
    mov rax, [rdi + matrix_rows] ;get rows
    ret

;unsigned int matrixGetCols(Matrix matrix)
matrixGetCols:
    xor rax, rax
    mov rax, [rdi + matrix_cols] ;get cols
    ret


;;; some macros, which determinates the true position of 
;elements. Exact address to do [r..]
;r8, r9, rdx, rax spoil
;rows, cols, matrix, reg for position
%macro get_true_position 4
   mov r8, %2
   mov rax, [%3 + matrix_cols_aligned]
   mul %1 
   add rax, r8
   mov r10, rax
   shl rax, 2
   mov %4, [%3 + matrix_ptr]
   add %4, rax 
%endmacro

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;xmm0               rdi                 rsi             rdx
matrixGet:
    enter 0, 0
    get_true_position rsi, rdx, rdi, r9 ; spoil only caller-save regs.
    movss xmm0, [r9]    ;store float into xmm0
    leave
    ret
;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
    enter 0, 0    
    get_true_position rsi, rdx, rdi, r9 ; spoil only caller-save regs.
    movss [r9], xmm0   ;set float to it's right place 
    leave
    ret

;Matrix matrixCopy(Matrix matrix)
matrixCopy:
    enter 0, 0
    x86_64_calle_push
    mov r12, rdi    ;save matrix to r12
    mov rdi, [r12 + matrix_rows] ;let's call matrixNew
    mov rsi, [r12 + matrix_cols] 
   
    call matrixNew
    test rax, rax; Do we have memory for this operation?
    jz .ret

    mov r13, rax ;save it fo future
    
    mov rdi, [r13 + matrix_ptr] ; save pointer for memcpy
    mov rsi, [r12 + matrix_ptr] ; save source for memcpy
    mov rax, [r13 + matrix_rows_aligned]    ;calc whole size
    mul qword [r13 + matrix_cols_aligned]  
    mov rdx, rax ;save size
    shl rdx, 2  ;multiply by float size
    call memcpy
    mov rax, r13    ;done
    
    .ret
    x86_64_calle_pop
    leave
    ret
;Matrix matrixScale(Matrix matrix, float k)

matrixScale:
    enter 0, 0
    x86_64_calle_push
    sub rsp, 4 
    movss [rsp], xmm0 ; save our float to stack. Some calls can spoil it.
    call matrixCopy  ;we need another matrix to calculate.
    movss xmm1, [rsp] ;restore value
    add rsp, 4
    pshufd xmm1, xmm1, 0 ;copy low bits to all places.
    mov r12, rax ; save our new matrix with the same content into r12
    
    mov rax, [r12 + matrix_rows_aligned] ;calc true size
    mul qword [r12 + matrix_cols_aligned]
    mov r13, [r12 + matrix_ptr] ;mov pointer to reg
   
    .mul
    test rax, rax; while rax != 0
        jz .ret   
            sub rax, 4 ; rax -= 4
            movups xmm0, [r13 + rax * 4]; take 4 floats and multiply them
            mulps xmm0, xmm1;;;
            movups [r13 + rax * 4], xmm0; return them.
        jmp .mul
    .ret
    mov rax, r12    ;our result
    x86_64_calle_pop
    leave
    ret

;Matrix matrixAdd(Matrix a, Matrix b)
matrixAdd:
    enter 0, 0
    x86_64_calle_push
    
    mov rax, [rdi]
    cmp rax, [rsi]
    jnz .dimens            ;width cmp

    mov rax, [rdi + 8]
    cmp rax, [rsi + 8]     ;height cmp 
    jnz .dimens

    mov r12, rsi    ;save second matrix
    call matrixCopy ;just copy first matrix, which is in rdi
    
    test rax, rax; memory. again
    jz .dimens
     
    mov r13, rax    ;save it
    
    mov rax, [r12 + matrix_rows_aligned] ;calc the whole size
    mul qword [r12 + matrix_cols_aligned]
   
    mov r14, [r13 + matrix_ptr] ;save pointers
    mov r15, [r12 + matrix_ptr]
    
    .add
    test rax, rax
        jz .xret   
            sub rax, 4
            movups xmm0, [r14 + rax * 4] ;load 4 floats
            movups xmm1, [r15 + rax * 4] ;load another 4 floats
            addps xmm0, xmm1 ; add them
            movups [r14 + rax * 4], xmm0 ;store them
        jmp .add
    .xret
    mov rax, r13 ;return our matrix
    jmp .ret 
    
    .dimens
    xor rax, rax ;something went wrong...
    
    .ret
    x86_64_calle_pop
    leave
    ret

;Matrix matrixMul(Matrix a, Matrix b)
; rax               rdi         rsi
matrixMul:
    enter 0, 0
    x86_64_calle_push
    
    mov r12, rdi    ;save first one
    mov r13, rsi    ;save second

    mov rax, [r12 + matrix_cols];check dimens
    cmp rax, [r13 + matrix_rows]
    jnz .size_fail; some dimens are not equal..

    mov rdi, [r12 + matrix_rows]; preparations for matrixNew
    mov rsi, [r13 + matrix_cols]

    call matrixNew
    mov r14, rax

    test rax, rax ;maybe we have no memory for our true matrix
    jz .size_fail  

    mov rbx, [r12 + matrix_cols]; test for zero-dimen matrix
    test rbx, rbx
    jz .ret

    mov rbx, [rax + matrix_rows]
    test rbx, rbx ;another zero sized matrix
    jz .ret
    
    mov rbx, [rax + matrix_cols]
    test rbx, rbx ;also zero-sized
    jz .ret    
    
    ;non zero matrix
    ;for i = 0..rowsA
    ;   for j = 0..colsA
    ;      for k = 0..colsB
    ;           c[i][k] += a[i][j] * b[j][k]

    ;r12 -- A
    ;r13 -- B
    ;r14 -- C
    ;i - r15
    ;j - ebx
    ;k - ecx

; macro : matrix, i, j, res
; calcs and store exact address in res
%macro calc_exact_address 4
    mov %4, [%1 + matrix_ptr]
    push rax
    xor rax, rax
    mov rax, [%1 + matrix_cols_aligned]
    mul %2
    add rax, %3
    shl rax, 2
    add %4, rax
    pop rax 
%endmacro

;macro : counter, --, begin, end
; it does simple for loop routine
%macro loop_routine 4
    test %1, %1
    jz %4
    sub %1, %2
    jmp %3
%endmacro
    ;we will go from the end.
    mov r15, [r12 + matrix_rows_aligned]; init i
    dec r15 
    .i_loop:
        mov rbx, [r12 + matrix_cols_aligned]; init j
        dec rbx
       .j_loop:
                       
            calc_exact_address r12, r15, rbx, r8;Our current A element.
            movss xmm2, [r8]
            pshufd xmm2, xmm2, 0 ;just copy it
         
            calc_exact_address r13, rbx, 0, r9; beginning of B row
            calc_exact_address r14, r15, 0, r10; beginning of C row
          
                 ;r10 -- C beginning pointer
                 ;r9 -- B beginning pointer
           
            mov rcx, [r13 + matrix_cols_aligned]; k init
            sub rcx, 4
            .k_loop:

                movups xmm0, [r9 + 4 * rcx] ;load B row
                mulps xmm0, xmm2    ;multiply it by A elem
                movups xmm1, [r10 + 4 * rcx] ; load C row
                addps xmm1, xmm0 ; add B to C
                movups [r10 + 4 * rcx], xmm1 ; save C row;                     
                              
                loop_routine rcx, 4, .k_loop, .end_k
            .end_k
            loop_routine rbx, 1, .j_loop, .end_j
       .end_j
       loop_routine r15, 1, .i_loop, .end_i
    .end_i

    mov rax, r14 ;return our matrix
    jmp .ret
  
    .size_fail ;something has gone wrong...
    xor rax, rax
    
    .ret
    x86_64_calle_pop
    leave
    ret
