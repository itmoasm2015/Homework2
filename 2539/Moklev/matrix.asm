%macro push_x64 0 ; push registers that callee must save due to x64 calling convention
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro pop_x64 0  ; pop registers that callee must save due to x64 calling convention
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
%endmacro


extern aligned_alloc
extern malloc

global matrixNew

;  # Matrix data type definition
;
;  typedef struct {
;      unsigned int rows;
;      unsigned int cols;
;      float* data;
;  } *Matrix;


section .text
    
; Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew: 
    push_x64 ; save needed registers (from rbx, r12 - r15)
    mov rbp, rsp
    ;  $! fix for windows: rcx -> rdi
    push rcx
    
    
    ;  $! fix for windows: rcx -> rdi
    mov rcx, 16 ; sizeof(unsigned int) * 2 + sizeof(float*) 
    call malloc ; void* malloc(size_t size)
    
    pop rcx
    
    mov rax, rcx
    pop_x64
    ret
    
    test rax, rax  ; if malloc returned NULL
    jz .return
    
.malloc_ok:
    
    ;  $! rcx -> rdi
    ;mov ecx, dword [rbp]
    mov dword [rax], ecx
    mov dword [rax + 4], 69
    mov dword [rax + 8], 107
         
    ; windows: rcx, rdx, r8, r9, stack 
    ; linux:   rdi, rsi, rdx, rcx, r8, r9, stack
    
    
.return:            
    add rsp, 8
    pop_x64
    ret
    
    