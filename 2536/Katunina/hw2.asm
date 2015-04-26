section .text

%define float_size 4
%define service_info_size 8
 
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
    
    add rdi, 7
    and rdi, 0xFFFFFFFFFFFFFFF8;these two lines for rounding rows up to eight
    mov r9, rdi
   
    add rsi, 7
    and rsi, 0xFFFFFFFFFFFFFFF8;these two lines for rounding columns up to eight
    mov r10, rsi
    
    imul rdi, rsi
    mov rax, rdi;imul with one argument multiplies argument by rax
    mov r11, float_size
    imul r11
    mov r12, service_info_size
    imul r12, 4
    add rax, r12;original rows, original columns, rounded rows, rounded columns in bytes
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
    mov [rax+service_info_size], rcx
    mov r12, service_info_size
    imul r12, 2
    mov [r12], r9
    add r12, service_info_size
    mov [r12], r10
    
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
    mov rax, [rdi]
    ret

;matrix in rdi    
matrixGetCols:
    mov rax, [rdi+service_info_size]
    ret

;matrix in rdi, rows in rsi, cols in rdx    
matrixGet:
    call calculateMatrixElementAddress
    mov eax, [rdi]
    movd xmm0, eax
    ret 

;rdi+((rsi-1)*([rdi+24])+rdx-1)*4+32, [rdi+24] - rounded up to 8 columns, 32 - to skip bytes for rows and columns
calculateMatrixElementAddress:
    sub rsi, 1
    mov r12, service_info_size
    imul r12, 3
    imul rsi, [rdi+r12]
    add r12, service_info_size
    add rdi, r12
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
    mov rdi, [r8]
    mov rsi, [r8+service_info_size]
    call matrixNew
     
                                
    
                                
    
    