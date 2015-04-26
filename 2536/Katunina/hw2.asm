section .text

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

;matrix structure: 4 bytes for original number of rows, 4 - for original number of columns, 4 - for rounded up to four number of rows, 
;4 - for rounded up to four number of columns, rounded_rows*rounded_columns bytes for sequence of matrix' rows

;rows in rdi (32 bits), columns in rsi (32 bits)
matrixNew:
    mov r8, rdi
    mov rcx, rsi
    
    add rdi, 3
    and rdi, 0xFFFFFFFFFFFFFFFC;these two lines for rounding rows up to four
    mov r9, rdi
   
    add rsi, 3
    and rsi, 0xFFFFFFFFFFFFFFFC;these two lines for rounding columns up to four
    mov r10, rsi
    
    imul rdi, rsi
    mov rax, rdi;imul with one argument multiplies argument by rax
    mov r11, 4
    imul r11
    add rax, 32;original rows, original columns, rounded rows, rounded columns in bytes
    cmp rdx, 0;overflow?
    jne .overflow
    mov rdi, rax
    mov rsi, 1
    
    
    push r8
    push r9
    push r10
    push rcx
    
    call calloc
    
    pop rcx
    pop r10
    pop r9
    pop r8
    
    mov [rax], r8    
    mov [rax+8], rcx
    mov [rax+16], r9
    mov [rax+24], r10
    
    ret
    
.overflow:
    mov rax, 0
    ret
    
matrixDelete:
    call free
    ret
    
matrixGetRows:
    mov rax, [rdi]
    ret
    
matrixGetCols:
    mov rax, [rdi+8]
    ret

;rdi+((rsi-1)*([rdi+24])+rdx)*4+32, [rdi+24] - rounded up to 4 columns, 32 - to skip bytes for rows and columns    
matrixGet:
    sub rsi, 1
    imul rsi, [rdi+24]
    add rdi, 32
    add rsi, rdx
    imul rsi, 4
    mov xmm0, [rdi+rsi]
    ret 
                                
    
                                
    
    