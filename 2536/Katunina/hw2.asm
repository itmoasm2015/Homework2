section .text

%define float_size 4
%define rows_origin_offset 0
%define cols_origin_offset 8
%define rows_rounded_offset 16
%define cols_rounded_offset 24
%define matrix_offset 32
 
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

;matrix structure: 4 bytes for original number of rows, 4 - for original number of columns, 4 - for rounded up to eight number of rows,
;4 - for rounded up to eight number of columns, rounded_rows*rounded_columns bytes for sequence of matrix' rows
;rows in rdi (32 bits), columns in rsi (32 bits)
matrixNew:
    mov r8, rdi
    mov rcx, rsi
    add rdi, 3
    and rdi, 0xFFFFFFFFFFFFFFF8;these two lines for rounding rows up to eight
    mov r9, rdi
    add rsi, 3
    and rsi, 0xFFFFFFFFFFFFFFF8;these two lines for rounding columns up to eight
    mov r10, rsi
    imul rdi, rsi
    mov rax, rdi;imul with one argument multiplies argument by rax
    mov r11, float_size
    imul r11
    add rax, matrix_offset;original rows, original columns, rounded rows, rounded columns in bytes
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
    mov [rax+rows_origin_offset], r8
    mov [rax+cols_origin_offset], rcx
    mov [rax+rows_rounded_offset], r9
    mov [rax+cols_rounded_offset], r10
    ret
.overflow:
    mov rax, 0
    ret
    
;matrix in rdi
matrixDelete:
    call free
    ret
    
;matrix in rdi
matrixGetRows:
    mov rax, [rdi+rows_origin_offset]
    ret
    
;matrix in rdi
matrixGetCols:
    mov rax, [rdi+cols_origin_offset]
    ret
 
;matrix in rdi, rows in rsi, cols in rdx
matrixGet:
    call calculateMatrixElementAddress
    mov eax, [rdi+rows_origin_offset]
    movd xmm0, eax
    ret
    
;rdi+((rsi-1)*([rdi+24])+rdx-1)*4+32, [rdi+24] - rounded up to 8 columns, 32 - to skip bytes for rows and columns
calculateMatrixElementAddress:
    sub rsi, 1
    imul rsi, [rdi+cols_rounded_offset]
    add rdi, matrix_offset
    add rsi, rdx
    sub rsi, 1
    imul rsi, float_size
    add rdi, rsi
    ret
    
;matrix in rdi, rows in rsi, cols in rdx, value in xmm0
matrixSet:
    call calculateMatrixElementAddress
    movd [rdi], xmm0
    ret

;matrix in rdi, scale in xmm0
matrixScale:
    mov r8, rdi
    mov rdi, [r8+rows_origin_offset]
    mov rsi, [r8+cols_origin_offset]
    call matrixNew
    mov r9, rax
    add r9, matrix_offset
    mov rax, [r8+rows_rounded_offset]
    imul rax, [r8+cols_rounded_offset]
    mov rcx, 0
.loop:
    vmovups ymm1, [rcx] 
    vmulps ymm1, ymm2,ymm0 
    vmovups [r9+rcx], ymm1
    add rcx, matrix_offset
    cmp rcx, rax
    jne .loop 
    
    mov rax, r9
    sub rax, matrix_offset
    
    ret
     
                                
    
                                
    
    