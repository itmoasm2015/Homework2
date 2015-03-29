extern calloc, free
extern printf

; 4byte = 4 bytes
; Matrix is an array of 4bytes where first 4byte is row count, second 4byte is column count
; Cols rounded to the nearest multiply of 4 for using SSE
; indexes from 3 to 3+cols-1 is 1st row
;         from 3+cols to 3+2*cols-1 is 2nd row, etc.
;
; So, reg+2 in some places in the code means that first and second 4bytes are for the column and row count

; From matrix to array index:
; (row, col) -> row * col_cnt + col + 2

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

%macro roundToFour 1
        sub %1, 1
        and %1, ~3
        add %1, 4
%endmacro

matrixNew:
    ; rdi=rows
    ; rsi=cols

    mov rax, rsi
    roundToFour rax
    mul rdi     ; rax = rdi*rsi (rows*cols)
    add rax, 2  ; for row and column count
    ; rax = 2 + (rows*cols)

    ; allocating of rax byte, size of byte = 4
    push rdi
    push rsi
    mov rdi, rax    ; count of byte
    mov rsi, 4      ; size = 4
    call calloc
    ; rax = matrix.values
    pop rsi
    pop rdi

    push rsi
    push rdi
    push rax
    mov rsi, rax
    mov rdi, fmtAl
    mov rax, 0
    call printf
    pop rax
    pop rdi
    pop rsi

    mov [rax], rdi      ; values[0] = rows
    mov [rax+4], rsi    ; values[1] = cols
    ret

matrixDelete:
    ; rdi = matrix.values
    call free
    ret

matrixGetRows:
    ; rdi = matrix.values
    ; rows = matrix.values[0] = [rdi]
    mov eax, [rdi]
    ret

matrixGetCols:
    ; rdi = matrix.values
    ; rows = matrix.values[1] = [rdi+4]
    mov eax, [rdi+4]
    ret

matrixGet:
    ; rdi = matrix.values
    ; rsi = row
    ; rdx = col

    ; (row, col) -> row * col_cnt + col + 2
    call matrixGetCols
    roundToFour rax
    ; save rdx because of mul writes bad data in it
    push rdx
    mul rsi
    pop rdx

    ; rax = (row, col)
    add rax, rdx
    add rax, 2

    movss xmm0, [rdi+4*rax] ; xmm0 = values[rax]
    ret

matrixSet:
    ; rdi = matrix.values
    ; rsi = row
    ; rdx = col
    ; xmm0 = value

    ; (row, col) -> row * col_cnt + col + 2
    call matrixGetCols ; rax = col_cnt
    roundToFour rax
    ; save rdx because of mul writes bad data in it
    push rdx
    mul rsi
    pop rdx

    ; rax = (row, col)
    add rax, rdx
    add rax, 2

    movss [rdi+4*rax], xmm0 ; values[rax] = xmm0 (value)
    ret

matrixScale:
    ; rdi = matrix.values
    ; xmm0 = 0:0:0:k

    movss xmm5, xmm0      ; xmm5 = 0:0:0:k
    movsldup xmm5, xmm5   ; xmm5 = 0:0:k:k
    unpcklps xmm5, xmm5   ; xmm5 = k:k:k:k

    call matrixGetRows
    mov r10, rax        ; r10 = rows
    call matrixGetCols
    mov r11, rax        ; r11 = cols

    push r11         ; save not rounded cols
    roundToFour r11

    push r10         ;
    push r11         ; save registers
    push rdi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = newMatrix.values
    mov r9, rax      ; r9 = newMatrix.values
    pop rdi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded rcx

    mov [r9], r10    ; newRows = rows
    mov [r9+4], r11  ; newCols = cols

    roundToFour r11

    ; rcx = rax = cols*rows
    mov rax, r11
    mul r10
    mov rcx, rax

.looptop:
    sub rcx, 4
    movups xmm1, [rdi+(rcx+2)*4]
    mulps xmm1, xmm5
    movups [r9+(rcx+2)*4], xmm1
.overit:
    cmp rcx, 0
    jnz .looptop

    mov rax, r9 ; rax = newMatrix.values
    ret

matrixAdd:
    ; rdi = A.values
    ; rsi = B.values

    call matrixGetRows
    mov r10, rax        ; r10 = A.rows

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetRows
    mov rdx, rax        ; rdx = B.rows
    pop rdi             ; load rdi
    cmp rdx, r10        ; compare A.rows, B.rows
    jnz .badSizes

    call matrixGetCols
    mov r11, rax        ; r11 = A.cols

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetCols
    mov rdx, rax        ; rdx = B.cols
    pop rdi             ; load rdi
    cmp rdx, r11        ; compare A.cols, B.cols
    jnz .badSizes

    push r11         ; save not rounded cols
    roundToFour r11

    push r10         ;
    push r11         ;
    push rdi         ; save registers
    push rsi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = newMatrix.values
    mov r9, rax      ; r9 = newMatrix.values
    pop rdi          ;
    pop rsi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded rcx

    mov [r9], r10    ; newRows = rows
    mov [r9+4], r11  ; newCols = cols

    roundToFour r11

    ; rcx = rax = cols*rows
    mov rax, r11
    mul r10
    mov rcx, rax


.looptop:
    sub rcx, 4
    movups xmm0, [rdi+(rcx+2)*4]
    movups xmm1, [rsi+(rcx+2)*4]
    addps xmm0, xmm1
    movups [r9+(rcx+2)*4], xmm0
.overit:
    cmp rcx, 0
    jnz .looptop

    mov rax, r9 ; rax = newMatrix.values
    ret

.badSizes:
    mov rax, 0
    ret

matrixMul:
    ; rdi = A.values
    ; rsi = B.values

    call matrixGetCols
    mov r10, rax        ; r10 = A.cols

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetRows
    mov rdx, rax        ; rdx = B.rows
    pop rdi             ; load rdi
    cmp rdx, r10        ; compare A.cols, B.rows
    jnz .badSizes

    call matrixGetRows
    mov r10, rax        ; r10 = A.rows = newMatrix.rows

    push rdi            ; save rdi
    mov rdi, rsi
    call matrixGetCols
    mov r11, rax        ; r11 = B.cols = newMatrix.cols
    pop rdi             ; load rdi


    push r11         ; save not rounded cols
    roundToFour r11

    push r10         ;
    push r11         ;
    push rdi         ; save registers
    push rsi         ;
    mov rdi, r10     ; rdi = rows
    mov rsi, r11     ; rci = cols
    call matrixNew   ; rax = newMatrix.values
    mov r9, rax      ; r9 = newMatrix.values
    pop rdi          ;
    pop rsi          ;
    pop r11          ; load registers
    pop r10          ;

    pop r11          ; load not rounded rcx

    mov [r9], r10    ; newRows = rows
    mov [r9+4], r11  ; newCols = cols

    roundToFour r11

    ; rcx = rax = cols*rows
    mov rax, r11
    mul r10
    mov rcx, rax


;.looptop:
;    sub rcx, 4
;    movups xmm0, [rdi+(rcx+2)*4]
;    movups xmm1, [rsi+(rcx+2)*4]
;    addps xmm0, xmm1
;    movups [r9+(rcx+2)*4], xmm0
;.overit:
;    cmp rcx, 0
;    jnz .looptop

    mov rax, r9 ; rax = newMatrix.values
    ret


.badSizes:
    mov rax, 0
    ret

section .data
msg:    db "Hello, world,", 0
msg2:   db "...and goodbye!", 0
fmtAl:    db 'New matrix allocated at %d',10,0
fmt:    db '%ld',10,0
fmtf:    db '%f',10,0
rs dq 1.6
