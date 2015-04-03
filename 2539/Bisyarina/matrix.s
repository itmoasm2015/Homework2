section .text

extern aligned_alloc
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

;;; Matrix is stored in memorys way:
;;; First 8 bytes - amount of rows
;;; Second 8 bytes - amount of columns
;;; In further memory matrix is placed by rows
;;; Column and row sizes are rounded up to 4 to simplify access using SSE
;;; Alllocated memory is aligned by 16 to speed up


;;; Rounds first arguments to 4 and stores it
;;; Affects only first arg
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

;;; Macro to store result of multiplication of second and third args in first arg
;;; Affects nothing xcept first arg
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

;;; Allocates matrix and stores pointer to in rax
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
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

;;;Matrix matrixNew(unsigned int rows, unsigned int cols)
;;; rows stored in rdi, cols stored in rsi
;;; pointer to matrix stores in rax
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
matrixNew:
        push rsi
        push rdi

        ;; Rounding sizes to 4
        roundTo4 rsi
        roundTo4 rdi

        ;; Allocating memory
        allocMatrix rdi, rsi
        countSize rcx, rdi, rsi

        pop rdi
        pop rsi

        ;; Check if allocation is successfull
        test rax, rax
        jz .exit
        
        ;; Store sizes in struct
        mov [rax], rdi
        mov [rax + 8], rsi

        push rax

        ;; Fill matrix with zeroes
        lea rdi, [rax + 16]             ; set rdi to pointer to the beginning of matrix values
        xor rax, rax
        cld                             ; set direction flag to 0
        rep stosd
        pop rax
.exit:
        ret

;;; void matrixDelete(Matrix m)
;;; Pointer to matrix stored in rdi
;;; Frees memory allocated for matrix
matrixDelete:
        call free
        ret
        
;;; unisigned int matrixGetRows(Matrix m)
;;; Pointer to matrix stored in rdi
;;; Returns amount of rows in matrix in rax
matrixGetRows:
        mov rax, [rdi]
        ret

;;; unisigned int matrixGetCols(Matrix m)
;;; Pointer to matrix stored in rdi
;;; Returns amount of columns in matrix in rax
matrixGetCols:
        mov rax, [rdi + 8]
        ret

;;; float matrixGet(Matrix m, unsigned int row, unsigned int col)
;;; Pointer to matrix - A - stored in rdi
;;; Row number stored in rsi
;;; Column number stored in rdx
;;; Return A[row][col] in xmm0
;;; Affects r8, rdx, rdi
matrixGet:
        ;; Get rounded amount of columns 
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8
        
        ;; Save column number
        mov r8, rdx

        ;; Get index in linear representation and get value
        xor rdx, rdx
        mul rsi
        add rax, r8
        add rdi, 16
        movss xmm0, [rdi + rax * 4]     ; Store value A[row][col] in xmm0 
        ret

;;; void matrixSet(Matrix m, unsigned int row, unsigned int col, float k)
;;; Pointer to matrix - A - stored in rdi
;;; Row number stored in rsi
;;; Column number stored in rdx
;;; Number to set stored in xmm0
;;; A[row][col] = k
;;; Affects rax, r8, rdx, rdi
matrixSet:
        ;; Get rounded amount of columns
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8

        ;; Save column number
        mov r8, rdx

        ;; Get index in linear representation and store
        xor rdx, rdx
        mul rsi
        add rax, r8
        add rdi, 16
        movss [rdi + rax * 4], xmm0     ; A[row][col] = k
        ret

;;; Matrix matrixClone(Matrix m)
;;; Source matrix pointer stored in rdi
;;; Cloned matrix pointer returned in rax
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
matrixClone:
        push rdi

        ;; Get sizes of source matrix
        mov rsi, [rdi + 8]
        mov rcx, [rdi]
        mov rdi, rcx

        ;; Round sizes
        roundTo4 rdi
        roundTo4 rsi

        ;; Allocate matrix and calc size of memory
        allocMatrix rdi, rsi
        countSize rcx, rdi, rsi
        pop rdi
        
        ;; Test if allocation is successfull
        test rax, rax
        jz .exit

        ;; Copy sizes into new matrix
        mov rdx, [rdi]
        mov [rax], rdx
        mov rdx, [rdi + 8]
        mov [rax + 8], rdx

        ;; Copy values from source to new matrix
        mov rsi, rdi
        add rsi, 16
        mov rdi, rax
        add rdi, 16
        cld                             ; set direction flag to 0
        rep movsd
.exit
        ret

;;; Matrix matrixScale(Matrix m, float k)
;;; Pointer to source matrix - A - stored in rdi
;;; Scalar to multiply with stored in xmm0
;;; Return pointer to new matrix - B = k * A - in rax
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
matrixScale:
        push rdi
        
        ;; Clone matrix and check if it is correct
        call matrixClone
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

        ;; Copy given scale in xmm0 four times [k, k, k, k] to multiply with
        shufps xmm0, xmm0, 0

        push rax
        add rax, 16

;;; Main loop 
;;; Takes 4-float chunk from source matrix and multiplies each on k
.loop:
        cmp rcx, 0
        je .exit

        movaps xmm1, [rax]
        mulps xmm1, xmm0

        movaps [rax], xmm1
        add rax, 16                     ; add size of chunk
        dec rcx
        jmp .loop
.exit:
        pop rax
        ret
.exit_fail:
        ret

;;; Matrix matrixAdd(Matrix A, Matrix B)
;;; Pointer to A stored in rdi
;;; Pointer to B stored in rsi
;;; Sizes of A must be same to sizes of B 
;;; Return pointer to new matrix C = A + B in rax
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
matrixAdd:
        ;; Check if amount of rows is equal
        mov rax, [rdi]
        mov rdx, [rsi]
        cmp rax, rdx
        jne .exit_fail

        ;; Check if amount of columns is equal
        mov rax, [rdi + 8]
        mov rdx, [rsi + 8]
        cmp rax, rdx
        jne .exit_fail

        ;; Cloning first matrix
        push rdi
        push rsi
        call matrixClone
        pop rsi
        pop rdi

        ;; Check if cloning is successfull
        test rax, rax
        jz .exit_fail

        ;; Calc amount of 4-float chunks in matrix A(same as in B)
        mov r8, [rdi]
        mov r9, [rdi + 8]
        roundTo4 r8
        roundTo4 r9
        countSize rcx, r8, r9
        shr rcx, 2

        push rax
        
        add rax, 16
        add rsi, 16

;;; Sum each element of clone of first matrix with element of second matrix
;;; A[i][j] + B[i][j] and store in cloned matrix C
;;; Taking 4-float chunks
.loop:
        cmp rcx, 0
        je .exit

        movaps xmm1, [rax]
        movaps xmm0, [rsi]
        
        addps xmm1, xmm0
        movaps [rax], xmm1

        ;; Add size of chunk
        add rax, 16
        add rsi, 16

        dec rcx
        jmp .loop
.exit:
        pop rax
        ret
.exit_fail:
        xor rax, rax
        ret

;;; Matrix matrixMul(Matrix A, Matrix B)
;;; Pointer to A stored in rdi
;;; Pointer to B stored in rsi
;;; Amount of columns of A must be same to amount of rows of B
;;; Return pointer to new matrix C = A * B in rax
;;; Amount of rows in C same as A, columns - save as B
;;; Affects everything except rbp, rbx, r12-r15 because of memory allocation
matrixMul:
        ;; Check if amount of cols of A same as amount of rows of B
        mov rax, [rdi + 8]
        mov rdx, [rsi]
        cmp rax, rdx
        jne .exit_fail

        mov r8, [rdi]
        mov r9, [rsi + 8]

        roundTo4 r8                     ; amount of rows in A and in C
        roundTo4 r9                     ; amount of columns in B and in C

        push rdi                        ; saving registers may be affected by allocating memory
        push rsi

        allocMatrix r8, r9

        pop rsi
        pop rdi

        ;; Check allocation successfull
        test rax, rax 
        jz .exit_fail

        mov r8, [rdi]
        mov r9, [rsi + 8]
        mov [rax], r8
        mov [rax + 8], r9
        roundTo4 r8                     ; rounded to 4 amount of rows in A and in C
        roundTo4 r9                     ; rounded to 4 amount of columns in B and in C

        push rbx
        push r12
        push r13
        push r14

        mov r10, [rdi + 8]              ; amount of columns in A, rows in B
        roundTo4 r10
        mov r14, r10                    ; rounded to 4 amount if columns in A, rows in B
        shr r10, 2                      ; amount of iterations of the third level loop

        mov r11, rax                    ; pointer to result matrix
        push r11
        add r11, 16                     ; move pointer to first element of matrix

        ;; Set loop variables
        xor rax, rax                    ; set i = 0
        xor rbx, rbx                    ; set j = 0
        xor rcx, rcx                    ; set k = 0

;;; Calculating C[i][j] = sum (for k = 0 .. r10) A[i][k] * B[k][j]
        add rdi, 16
        add rsi, 16

;;; In loop rdi points to current [i] row
.loopI:
        cmp rax, r8                     ; check i loop is finished
        je .exit
        mov r13, rdi                    ; r13 points to current to 4-float chunk

.loopJ:
        cmp rbx, r9                     ; check j loop is finished
        jne .loopJContinue
        
        inc rax                         ; if finished inc i and goto i loop
        lea rdi, [rdi + 4 * r14]        ; move rdi to next row
        xor rbx, rbx                    ; reset j index loop
        jmp .loopI
        
.loopJContinue:
        lea r12, [rsi + rbx * 4]        ; set pointer to first element of column [j]
        xorps xmm7, xmm7                ; reset  accumulator
.loopK:
        cmp rcx, r10                    ; check loop k finished
        je .store                       ; if finished proceed to storing calculated value

        movaps xmm0, [r13]              ; take chunk from [i]-row in A -> [y1, y2, y3, y4]
        add r13, 16                     ; move pointer to next chunk

        ;; Taking 4-float chunk from [j]-column of B
        ;; [4*k][j], [4*k + 1][j], [4*k + 2][j], [4*k + 3][j],
        movss xmm1, [r12]               ; [4*k][j] -> x1
        lea r12, [r12 + 4 * r9]         ; move pointer on a value of size of a row to point to [4*k + 1][j] element
        movss xmm2, [r12]               ;[4*k + 1][j]  -> x2
        lea r12, [r12 + 4 * r9]
        movss xmm3, [r12]               ;[4*k + 2][j]  -> x3
        lea r12, [r12 + 4 * r9]
        movss xmm4, [r12]               ;[4*k + 3][j]  -> x4
        lea r12, [r12 + 4 * r9]

        ;; Place x1, x2, x3, x4 in xmm1:[x1, x2, x3, x4]
        unpcklps xmm1, xmm2             ; store in xmm1 [x1, x2, , ]
        unpcklps xmm3, xmm4             ; store in xmm3 [x3, x4, , ]
        movlhps xmm1, xmm3              ; store in xmm1 [x1, x2, x3, x4]
        
        mulps xmm0, xmm1                ; multiply [x1 * y1, x2 * y2, x3 * y3, x4 * y4]
        addps xmm7, xmm0                ; add result to accumulator

        inc rcx
        jmp .loopK

.store:
        xor rcx, rcx
        inc rbx
        mov r13, rdi            ; reset r13 to the beginning of row
        
        ;; Get horisontal sum of accumulator
        haddps xmm7, xmm7
        haddps xmm7, xmm7

        ;; Store result in C[i][j]
        movss [r11], xmm7
        add r11, 4              ; inc pointer to current element of result matrix
        jmp .loopJ
.exit:
        pop rax
        pop r14
        pop r13
        pop r12
        pop rbx                 ; get stored pointer to result
        ret
.exit_fail:
        xor rax, rax
        ret
