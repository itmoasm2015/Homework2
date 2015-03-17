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
    push rdi ; save arguments
    push rsi ; malloc will overwrite them
    
    mov rdi, 16 ; sizeof(unsigned int) * 2 + sizeof(float*) 
    call malloc ; void* malloc(size_t size)
    
    pop rsi ; restore arguments
    pop rdi 
    
    test rax, rax  ; if malloc returned NULL
    jz .return
    
.malloc_ok:
    
    mov dword [rax], edi
    mov dword [rax + 4], esi

    push rax ; save return value, aligned_alloc will overwrite it
    
    mov rax, rdi
    mul rsi
    mov rsi, rax ; size (rows * cols)
    mov rdi, 16  ; alignment
    call aligned_alloc ; void* aligned_alloc(size_t alignment, size_t size)
    mov rcx, rax
     
    pop rax ; restore return value
    
    mov qword [rax + 8], rcx
         
    ; windows: rcx, rdx, r8, r9, stack 
    ; linux:   rdi, rsi, rdx, rcx, r8, r9, stack
    
    
.return:            
    pop_x64
    ret
    
    
