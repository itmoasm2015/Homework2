section .text

extern aligned_alloc
extern malloc
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

%macro roundTo4 1
        push rax
        push rdx
        dec %1
        mov rax, %1
        
        xor rdx, rdx
        push rcx
        mov qword rcx, 4
        div rcx
        pop rcx
        
        sub %1, rdx
        add %1, 4
        pop rdx
        pop rax
%endmacro

%macro countSize 3
        push rax
        push rdx
        
        xor rdx, rdx
        mov rax, %2
        mul %3
        mov %1, rax
        
        pop rdx
        pop rax
%endmacro

%macro allocMatrix 2
        push rcx
        countSize rcx, %1, %2

        sal rcx, 2
        add rcx, 16

        push rdi
        push rsi
        
        mov rsi, rcx
        mov rdi, 16
        call aligned_alloc

        pop rsi
        pop rdi
        pop rcx
%endmacro

matrixNew:
        push rsi
        push rdi
;; Rounding sizes
        roundTo4 rsi
        roundTo4 rdi
;; Allocating memory
        allocMatrix rdi, rsi
        countSize rcx, rdi, rsi

        pop rdi
        pop rsi

;; Check if allocation successfull
        test rax, rax
        jz .exit
        
;; Store sizes in struct
        mov [rax], rdi
        mov [rax + 8], rsi

        push rax
;; Fill matrix with zeroes
        lea rdi, [rax + 16]
        xor rax, rax
        cld
        rep stosd
        pop rax

.exit:
        ret


matrixDelete:
        call free
        ret

matrixGetRows:
        mov rax, [rdi]
        ret

matrixGetCols:
        mov rax, [rdi + 8]
        ret


matrixGet:
;; Get rounded amount of columns
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8
;; Save column number
        mov r8, rdx

;; Get index in linear representation
        xor rdx, rdx
        mul rsi
        add rax, r8

        add rdi, 16
        movss xmm0, [rdi + rax * 4]
        ret
        
matrixSet:
;; Get rounded amount of columns
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8
;; Save column number
        mov r8, rdx
;; Get index in linear representation
        xor rdx, rdx
        mul rsi
        add rax, r8
;; Set value
        add rdi, 16
        movss [rdi + rax * 4], xmm0
        ret
        


cloneMatrix:
;; Allocate matrix and calc size
        push rdi
;; Get sizes
        mov rsi, [rdi + 8]
        mov rcx, [rdi]
        mov rdi, rcx
;; Round sizes
        roundTo4 rdi
        roundTo4 rsi
;; Allocate matrix and calc size
        allocMatrix rdi, rsi
        countSize rcx, rdi, rsi
        pop rdi
;; Test allocation successfull
        test rax, rax
        jz .exit
;; Copy sizes into new matrix
        mov rdx, [rdi]
        mov [rax], rdx
        mov rdx, [rdi + 8]
        mov [rax + 8], rdx
;; Prepare to copy values
        mov rsi, rdi
        add rsi, 16
        mov rdi, rax
        add rdi, 16
;; Copy values
        cld
        rep movsd
.exit
        ret

matrixScale:
        push rdi
;; Clone matrix and check if is correct
        call cloneMatrix
        test rax, rax
        jz .exit_fail
        
        pop rdi
;; Calc amount of 4-float chunks
        mov r8, [rdi]
        mov r9, [rdi + 8]
        roundTo4 r8
        roundTo4 r9
        countSize rcx, r8, r9
        shr rcx, 2
;; Copy given scale in xmm0 four times [k, k, k, k] to multiply
        shufps xmm0, xmm0, 0

        push rax
        add rax, 16
;; Main loop
;; Takes four values from matrix and multiplies each on k
;; Using xmm0
.loop:
        cmp rcx, 0
        je .exit
        movups xmm1, [rax]
        mulps xmm1, xmm0
        movups [rax], xmm1
;; Add size of chunk
        add rax, 16
;; Dec counter
        dec rcx
        jmp .loop
.exit:
        pop rax
.exit_fail:
        ret
        
matrixAdd:
;; Check amount of rows is equal
        mov rax, [rdi]
        mov rdx, [rsi]
        cmp rax, rdx
        jne .exit_fail

;; Check amount of columns is equal
        mov rax, [rdi + 8]
        mov rdx, [rsi + 8]
        cmp rax, rdx
        jne .exit_fail
;; Cloning first matrix
        push rdi
        push rsi
        call cloneMatrix
        pop rsi
        pop rdi
;; Check cloning successfull
        test rax, rax
        jz .exit_fail
;; Calc amount of 4-float chunks
        mov r8, [rdi]
        mov r9, [rdi + 8]
        roundTo4 r8
        roundTo4 r9
        countSize rcx, r8, r9
        shr rcx, 2

        push rax
        
        add rax, 16
        add rsi, 16

;; Sum each element of clone of first matrix with element of second matrix
;; a[i][j] + b[i][j]
;; Store in clone
;; Take 4-float chunks
.loop:
        cmp rcx, 0
        je .exit
        
        movups xmm1, [rax]
        movups xmm0, [rsi]
        addps xmm1, xmm0
        movups [rax], xmm1
;; Add size of chunk
        add rax, 16
        add rsi, 16
;; Dec counter
        dec rcx
        jmp .loop
.exit:
        pop rax
        ret
.exit_fail:
        xor rax, rax
        ret

matrixMul:
;; Check if amount of cols of A same as amount of rows of B
        mov rax, [rdi + 8]
        mov rdx, [rsi]
        cmp rax, rdx
        jne .exit_fail

        mov r8, [rdi]
        mov r9, [rsi + 8]
        
        roundTo4 r8             ; amount of rows in A and in C
        roundTo4 r9             ; amount of columns in B and in C

        push r8
        push r9
        allocMatrix r8, r9
;; Check allocation successfull
        test rax, rax 
        jz .exit_fail

        mov r8, [rdi]
        mov r9, [rsi + 8]
        mov [rax], r8
        mov [rax + 8], r9

        pop r9
        pop r8

        
        push rbx
        push r12
        push r13
        push r14

        mov r10, [rdi + 8]        ; amount of columns in A, rows in B
        roundTo4 r10
        mov r14, r10
        shr r10, 2              ; amount of iterations of the third level loop

        mov r11, rax            ; pointer to result matrix
        push r11
        add r11, 16             ; move pointer to first element

        
        xor rax, rax            ; set i = 0
        xor rbx, rbx            ; set j = 0
        xor rcx, rcx            ; set k = 0
;;; c[i][j] = sum (for k) a[i][k]*b[k][j]
        add rdi, 16
        add rsi, 16
.loopI:
        cmp rax, r8             ; check i loop is finished
        je .exit
        mov r13, rdi

.loopJ:
        cmp rbx, r9             ;check j loop is finished
        jne .loopJContinue
        
        inc rax                 ; if finished inc i and goto i loop
        lea rdi, [rdi + 4 * r14]
        xor rbx, rbx
        jmp .loopI
        
.loopJContinue:
        lea r12, [rsi + rbx * 4]            ; set pointer to first element of column [j]
        xorps xmm7, xmm7
.loopK:
        cmp rcx, r10            ; check loop k finished
        je .store               ; of finished proceed to stroring calculated value
        
        movups xmm0, [r13]      ; take chunk from [i]-row in A -> [y1,y2,y3,y4]
        add r13, 16             ; move pointer to current elem of A
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIX
;;; Ugly code to take 4-float chunk from [j]-column of B
;;; [4*k][j], [4*k + 1][j], [4*k + 2][j], [4*k + 3][j],

        movss xmm1, [r12]       ; [4*k][j] -> x1
        lea r12, [r12 + 4 * r9]              ; move pointer on a value of size of a row to point to [4*k + 1][j] element
        movss xmm2, [r12]       ;[4*k + 1][j]  -> x2
        lea r12, [r12 + 4 * r9]
        movss xmm3, [r12]       ;[4*k + 2][j]  -> x3
        lea r12, [r12 + 4 * r9]
        movss xmm4, [r12]       ;[4*k + 3][j]  -> x4
        lea r12, [r12 + 4 * r9]
        
        unpcklps xmm1, xmm2     ; store in xmm4 [ , ,x2, x4]
        unpcklps xmm3, xmm4     ; store in xmm3 [ , ,x1, x3]
        movlhps xmm1, xmm3
        mulps xmm0, xmm1        ; multiply [x1 * y1, x2 * y2, x3 * y3, x4 * y4]
        addps xmm7, xmm0        ; add result to accumulator

        xorps xmm0, xmm0
        xorps xmm1, xmm1
        xorps xmm2, xmm2
        xorps xmm3, xmm3
        xorps xmm4, xmm4

        inc rcx
        jmp .loopK

.store:
        xor rcx, rcx
        inc rbx
        mov r13, rdi
        ;; Get horisontal sum of accumulator
        haddps xmm7, xmm7
        haddps xmm7, xmm7

        ;; Store result in C[i][j]
        movss [r11], xmm7
        add r11, 4              ;inc pointer to current element of result matrix
        jmp .loopJ
.exit:
        pop rax
        pop r14
        pop r13
        pop r12
        pop rbx                 ;get stored pointer to result
        ret
.exit_fail:
        xor rax, rax
        ret
