
extern calloc
extern free

global matrixNew ;done
global matrixDelete ;done
global matrixSet ;done
global matrixGet ;done
global matrixGetRows ;done
global matrixGetCols ;done
global matrixAdd ;done
global matrixScale ;done
global matrixMul
global matrixRotate

%define ROWS 0
%define COLS 8
%define REALCOLS 16
%define DATA 24 
%define FLOAT_SIZE 4
%define HELP_FIELD 6

%macro roundTo4 1
    add %1, 3
    shr %1, 2
    shl %1, 2 
%endmacro


section .text

    ; Matrix matrixNew(unsigned int rows, unsigned int cols);
    ;                               rdi                rsi
    matrixNew: 
        mov rcx, rsi
        roundTo4 rcx  ;alignment 4 
        mov rax, rcx

        mul rdi       ; rax contains matrix size
        add rax, HELP_FIELD 
         
        push rsi      ; 
        push rdi

        mov rdi, rax
        mov rsi, FLOAT_SIZE

        call calloc   ; allocate memory for matrix

        pop rdi
        pop rsi

        mov rcx, rsi 
        roundTo4 rcx
        mov [rax + ROWS], rdi   ;count rows
        mov [rax + COLS], rsi   ;count colums
        mov [rax + REALCOLS], rcx ;colunt colums with alignment

        ret


    ;void matrixDelete(Matrix matrix);
    matrixDelete:
        call free 
        ret  


    ;unsigned int matrixGetRows(Matrix matrix);
    matrixGetRows:
        mov rax, [rdi + ROWS]
        ret

    ;unsigned int matrixGetCols(Matrix matrix);
    matrixGetCols:
        mov rax, [rdi + COLS]
        ret

    ;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
    ;                      rdi                  rsi               rdx
    matrixSet
        mov rax, rsi
        imul rax, [rdi + REALCOLS]
        add rax, rdx            ; rax contains realcols * row + col
        movss [rdi + rax * 4 + DATA], xmm0
        ret

    ;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
    ;                       rdi                  rsi               rdx

    matrixGet
        mov rax, rsi
        imul rax, [rdi + REALCOLS]
        add rax, rdx            ; rax contains realcols * row + col
        movss xmm0, [rdi + rax * 4 + DATA]
        ret

    ;Matrix matrixAdd(Matrix a, Matrix b);
    ;                        rdi       rsi

    matrixAdd: 
        push r12
        push r13
        push r14            ;save registers
        mov rax, [rdi + ROWS]
        mov rcx, [rsi + ROWS] 
        cmp rax, rcx
        jne .fail           ; if a.rows != b.rows return 0

        mov rax, [rdi + COLS]
        mov rcx, [rsi + COLS]
        cmp rax, rcx
        jne .fail           ; if a.cols != b.cols return 0

        mov r12, rdi ; a
        mov r13, rsi ; b
    
        mov rdi, [r12 + ROWS]
        mov rsi, [r12 + COLS]
        
        call matrixNew      ; create matrix for answer
        mov r14, rax ; c
    
        mov rcx, 0              ; loop counter
        mov rdx, [r12 + REALCOLS]  
        imul rdx, [r12 + ROWS]  ; rdx = realcols * rows
        .loop 
            movups xmm0, [r12 + rcx * 4 + DATA] ;xmm0 contain rcx, rcx + 1, rcx + 2, rcx + 3 elements from matrix a
            movups xmm1, [r13 + rcx * 4 + DATA] ;xmm1 contain rcx, rcx + 1, rcx + 2, rcx + 3 elements from matrix b
            addps  xmm0, xmm1
            movups [r14 + rcx * 4 + DATA], xmm0 ;write to result matrix 

            add rcx, 4              ; rcx += 4
            cmp rdx, rcx
            jg .loop                ; go if rdx > rcx 

        mov rax, r14                ; wirte answer to rax
        jmp .end

    .fail
        pop r14
        pop r13
        pop r12
        mov rax, 0
        ret

    .end
        pop r14
        pop r13
        pop r12
        ret

    ;Matrix matrixScale(Matrix matrix, float k);
    ;                          rdi      

    ; this function is similar matrixAdd

    matrixScale:
        push r12
        push r13
        push r14

        mov r12, rdi ; a
    
        mov rdi, [r12 + ROWS]
        mov rsi, [r12 + COLS]
        
        call matrixNew   ; create matrix for answer
        mov r14, rax ; c
    
        mov rcx, 0
        mov rdx, [r12 + REALCOLS]  
        imul rdx, [r12 + ROWS]   ; rdx = a.realcols * rows

        unpcklps xmm0, xmm0   ; (k, 0, 0, 0) -> (k, k, 0, 0);
        unpcklps xmm0, xmm0   ; (k, k, 0, 0) -> (k, k, k, k)

        .loop 
            movups xmm1, [r12 + rcx * 4 + DATA]   ;xmm1 contain rcx, rcx + 1, rcx + 2, rcx + 3 elements from matrix a
            mulps  xmm1, xmm0
            movups [r14 + rcx * 4 + DATA], xmm1   ; write down to result matrix

            add rcx, 4
            cmp rdx, rcx
            jg .loop

        mov rax, r14
        jmp .end

    .fail
        pop r14
        pop r13
        pop r12
        mov rax, 0
        ret

    .end
        pop r14
        pop r13
        pop r12
        ret


    ;Matrix matrixRotate(Matrix a);
    ;                           rdi
    
    ;this function rotates the matrix 
    ;  size matrix a = n * m
    ;  resutl matrix size = m * n
     
    matrixRotate:
        push r13
        push r14
        push rbp
        mov r13, rdi

        ; create rotated matrix
    
        mov rdi, [r13 + COLS]
        mov rsi, [r13 + ROWS]
        
        call matrixNew
        mov r14, rax ; br   create empty matrix m * n

        ; start rotate

        mov rbp, rsp
        sub rsp, 32

        mov r8, 0
        mov [rbp - 8], r8
        mov r8, [r13 + ROWS]
        mov [rbp - 16], r8
    
        .loop1                      ; for i = 0 .. n
            mov r8, 0
            mov [rbp - 24], r8
            mov r8, [r13 + COLS]
            mov [rbp - 32], r8
            .loop2                      ; for j = 0 .. m
                ; write element a[i][j] -> result[j][i]
                mov rdi, r13
                mov rsi, [rbp - 8] 
                mov rdx, [rbp - 24]
                call matrixGet   ;; get element

                mov rdi, r14
                mov rsi, [rbp - 24] 
                mov rdx, [rbp - 8]
                call matrixSet  ;; set elemnt

                mov r8, [rbp - 24]
                inc r8
                mov [rbp - 24], r8
                cmp [rbp - 32], r8
                jg .loop2
            
            mov r8, [rbp - 8]

            inc r8
            mov [rbp - 8], r8

            cmp [rbp - 16], r8
            jg .loop1

        add rsp, 32 
        mov rax, r14  ; write result to rax

        pop rbp
        pop r14
        pop r13

        ret


    ;Matrix matrixMul(Matrix a, Matrix b);  
    ;                        rdi       rsi
    ;   a = n * m  r12
    ;   b = m * k  r13
    ;   br= k * m  r14
    ;   c = n * k  r15

    matrixMul:
        push r12
        push r13
        push r14
        push r15
        push rbp            ;save registers
        mov rax, [rdi + COLS]
        mov rcx, [rsi + ROWS] 
        cmp rax, rcx
        jne .fail           ; check a.cols == b.rows

        mov r12, rdi ; a    ; save pointer to matrix a
        mov r13, rsi ; b    ; save pointer to matrix b


    ; create matrix c
        mov rdi, [r12 + ROWS]
        mov rsi, [r13 + COLS];
        
        call matrixNew     ; creat matrix for answer
        mov r15, rax  ; c   

    ; rotate
        mov rdi, r13 
        call matrixRotate   ;rotate matrix b
        mov r14, rax ; br

;;;;;;;;;;;;;;;;;;;;;;;;;

        mov rbp, rsp
        sub rsp, 32

        mov r8, 0
        mov [rbp - 8], r8
        mov r8, [r12 + ROWS] ; n
        mov [rbp - 16], r8
    
        .loop1            ;   for i = 0 .. n
            mov r8, 0
            mov [rbp - 24], r8
            mov r8, [r13 + COLS] ; k
            mov [rbp - 32], r8
            .loop2       ;    for j = 0 ... k
                ;;; main part     
                
                mov rcx, 0
                mov rdi, [r12 + REALCOLS] ; m
                xorps xmm2, xmm2     ; clear xmm2
                
                mov r8, [rbp - 8]
                imul r8, rdi        ; r8 = i * a.realcols

                mov r9, [rbp - 24]
                imul r9, rdi       ; r9 = j * br.realcols

                .loop3
                    movups xmm0, [r12 + r8 * FLOAT_SIZE + DATA] ; write to register
                    movups xmm1, [r14 + r9 * FLOAT_SIZE + DATA] ; write to register
                    mulps  xmm0, xmm1    ; mul (r8) * (r9) ; (r8 + 1) * (r9 + 1); (r8 + 2) * (r9 + 2) ; (r8 + 3) * (r9 + 3)
                    addps  xmm2, xmm0

                    add rcx, 4
                    add r8, 4
                    add r9, 4 

                    cmp rdi, rcx 
                    jg .loop3

                haddps xmm2, xmm2   ;  
                haddps xmm2, xmm2   ; 
                                    ; (a1, a2, a3, a4) -> (a1 + a2 + a3 + a4, ... , ... , ...)
                mov rcx, [rbp - 8]
                mov rdi, [r15 + REALCOLS]
                imul rcx, rdi
                add rcx, [rbp - 24]  ; rcx = i * result.realcols + j
            
                movss [r15 + rcx * FLOAT_SIZE + DATA], xmm2  ; write to result matrix

                ;movups xmm1, [r12 + rcx * 4 + DATA]
                ;mulps  xmm1, xmm0
                

                ;;;;;;;;;;;
                mov r8, [rbp - 24]
                inc r8                  ; j++
                mov [rbp - 24], r8
                cmp [rbp - 32], r8
                jg .loop2
            
            mov r8, [rbp - 8]

            inc r8                    ; i++
            mov [rbp - 8], r8

            cmp [rbp - 16], r8
            jg .loop1

        add rsp, 32 
        mov rax, r15 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp .end

    .fail
        pop rbp
        pop r15
        pop r14
        pop r13
        pop r12
        mov rax, 0
        ret

    .end
        pop rbp
        pop r15
        pop r14
        pop r13
        pop r12
        ret
  









; g++-multilib

section .data
    ;FLOAT_SIZE dd 4
    ZERO dd 0


