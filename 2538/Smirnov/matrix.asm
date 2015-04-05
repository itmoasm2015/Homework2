extern calloc
extern free

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

; struct Matrix:
;   8 bytes for real dims of matrix
;   8 bytes for aligned dims of matrix
;   4 * cols * rows bytes for matrix
%define ROWS 0
%define COLS 4
%define ALIGN_ROWS 8
%define ALIGN_COLS 12
%define MATRIX 16

%macro round4 1
    add         %1, 3
    and         %1, -4
%endmacro

;rdi - pointer to Matrix struct
;rsi - row number
;rdx - column number
;return rax - address
%macro getAddress 0 
    mov         rcx, rdx
    xor         rax, rax            
    mov         eax, [rdi + ALIGN_COLS] ; rax - number of columns                   
    imul        rax, 4 ; rax = ALIGN_COLS * 4   
    imul        rsi, rax ; i = i * ALIGN_COLS * 4
    imul        rcx, 4 ; j = j * 4
    add         rsi, rcx ; i = i * ALIGN_COLS * 4 + j * 4
    mov         rax, rdi 
    add         rax, MATRIX
    add         rax, rsi ; ans = pointer + MATRIX + i * ALIGN_COLS * 4 + j * 4  
%endmacro

section .text

;rdi - count of rows
;rsi - count of cols
;return rax - pointer to matrix
matrixNew:
    xor         rax, rax
    push        rdi
    push        rsi
    round4      rdi
    round4      rsi
    push        rdi
    push        rsi
    imul        rdi, rsi
    lea         rdi, [rdi + 4]
    mov         rsi, 4
    call        calloc ;allocate memory and fill with zeroes
    pop         rsi
    pop         rdi
    mov         [rax + ALIGN_ROWS], edi ;set count of rows rounded to 4
    mov         [rax + ALIGN_COLS], esi ;set count of columns rounded to 4
    pop         rsi
    pop         rdi 
    mov         [rax + ROWS], edi ;set real count of rows
    mov         [rax + COLS], esi ;set real count of columns
ret


;rdi - pointer to matrix
matrixDelete:
    call        free
ret

;rdi - pointer to matrix
matrixGetRows:
    mov         eax, [rdi + ROWS]
ret

;rdi - pointer to matrix
matrixGetCols:
    mov         eax, [rdi + COLS]
ret


;rdi - pointer to matrix
;rsi - number of row
;rdx - number of col
;xmm0 - ans
matrixGet:
    getAddress      
    movss       xmm0, [rax]
ret

; rdi - pointer to matrix
; rsi - row number
; rdx - column number
; xmm0 - value to set
matrixSet:
    getAddress  
    movss       [rax], xmm0
ret

;rdi - pointer to matrix
;xmm0 - scalar
;rax - pointer to new matrix
matrixScale:
    xor         rax, rax    
    ;creating new matrix
    mov         r8, rdi ; r8 - pointer to old matrix
    xor         rdi, rdi
    xor         rsi, rsi
    mov         edi, [r8 + ROWS]
    mov         esi, [r8 + COLS]
    movd        r9, xmm0
    push        r9
    push        r8  
    call        matrixNew
    pop         r8
    pop         r9
    movd        xmm0, r9
    
    cmp         rax, 0 ; can't create new matrix
    je          .scale_error

    unpcklps xmm0, xmm0 
    ;xmm0 = - - k k
    unpcklps xmm0, xmm0 
    ;xmm0 = k k k k

    mov         rsi, r8 ; rsi - pointer to old matrix
    
    xor         r8, r8
    mov         r8d, [rsi + ALIGN_ROWS]
    imul        r8d, [rsi + ALIGN_COLS]
    add         r8d, 4
    imul        r8d, 4
    ;r8 - number of elements in matrix multiplied by 4

    mov         rcx, MATRIX ; calculating pointer to matrix
    
    .scaling_loop:
        movups      xmm1, [rsi + rcx]
        mulps       xmm1, xmm0
        movups      [rax + rcx], xmm1
        add         rcx, 16
        cmp         r8, rcx
    jne .scaling_loop

    jmp .scale_end
    .scale_error:
        xor         rax, rax
    .scale_end:
ret

;rdi - first matrix
;rsi - second matrix
;rax - pointer to new matrix 
matrixAdd:
    ;check matrix's sizes and return 0 if needed;   
    mov         eax, [rdi + ROWS]
    cmp         eax, [rsi + ROWS]
    jne         .add_error
    mov         eax, [rdi + COLS]
    cmp         eax, [rsi + COLS]
    jne         .add_error

    ;creating new matrix    
    mov         r8, rdi 
    push        rdi
    push        rsi
    xor         rdi, rdi
    xor         rsi, rsi
    mov         edi, [r8 + ROWS]
    mov         esi, [r8 + COLS]    
    call        matrixNew
    pop         rsi
    pop         rdi

    cmp         rax, 0 ; can't create new matrix
    je          .add_error
    
    xor         r8, r8
    mov         r8d, [rsi + ALIGN_ROWS]
    imul        r8d, [rsi + ALIGN_COLS]
    add         r8d, 4
    imul        r8d, 4  ;r8 = (ALIGN_COLS * ALIGN_ROWS + 4) * 4

    mov         rcx, MATRIX ; calculating pointer to matrix
    
    .add_loop:
        movups      xmm0, [rsi + rcx]
        addps       xmm0, [rdi + rcx]
        movups      [rax + rcx], xmm0
        add         rcx, 16
        cmp         r8, rcx ;if all elements calculated ((ALIGN_COLS * ALIGN_ROWS + 4) * 4 == rcx) then break
        je          .add_end
    jmp         .add_loop

    jmp         .add_end ;no add error
    .add_error:
        xor         rax, rax ;return 0
    .add_end:
ret


;rdi - first matrix
;rsi - second matrix
;return rax - pointer to new matrix
matrixMul:
    push        r12
    push        r13
    push        r14
    push        r15
    
    ;check matrix's sizes and return 0 if needed;   
    mov         eax, [rdi + COLS]
    cmp         eax, [rsi + ROWS]
    jne         .multiply_error

    ;creating new matrix
    push        rdi
    push        rsi
    mov         esi, [rsi + COLS]
    mov         edi, [rdi + ROWS]
    call        matrixNew
    pop         rsi
    pop         rdi
    
    cmp         rax, 0 ; can't create new matrix
    je          .multiply_error
    
    mov         r15, rax ;save rax
    xor         r8, r8
    mov         r8d, [rax + ALIGN_ROWS]
    imul        r8d, [rax + ALIGN_COLS]
    imul        r8, 4
    add         r8, rax
    add         r8, MATRIX ; r8 - end of rax matrix 
    xor         r14, r14
    mov         r14d, [rax + ALIGN_COLS] ; r14 - number of columns in new matrix * 4
    imul        r14, 4
    xor         r13, r13
    mov         r13d, [rdi + ALIGN_COLS] ; r13 - number of rows in first matrix and number of columns in second multiplied by 4
    imul        r13, 4

    ;making matrix pointers
    add         rdi, MATRIX
    add         rsi, MATRIX
    add         rax, MATRIX 
    
    ; r11 - current column in new array
    xor         r11, r11
    .multiply_loop:
        xorps       xmm0, xmm0
        mov         rcx, r11
        xor         r12, r12

        .count   ;counting 4 elements starting from rax
            xorps       xmm1, xmm1
            movd        xmm1, [rdi + r12]
            unpcklps    xmm1, xmm1
            unpcklps    xmm1, xmm1
            movups      xmm2, [rsi + rcx]
            mulps       xmm1, xmm2
            addps       xmm0, xmm1
            add         rcx, r14
            add         r12, 4
            cmp         r12, r13
        jne         .count

        ;counting current column
        add         r11, 16
        cmp         r11, r14
        jne         .not_next_row
        xor         r11, r11
        add         rdi, r13
        .not_next_row:

        movups      [rax], xmm0 ;write to matrix
        add         rax, 16
        cmp         r8, rax
    jne         .multiply_loop

    mov         rax, r15
    jmp         .multiply_end
    .multiply_error:
        xor         rax, rax ; return 0
    .multiply_end:
    pop         r15
    pop         r14
    pop         r13
    pop         r12
ret