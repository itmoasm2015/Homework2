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

%macro fit_4 1    ; makes number divides by 4
    add %1, 3
    and %1, ~3
%endmacro

extern aligned_alloc
extern malloc
extern free

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols

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
    push_x64        ; save needed registers (from rbx, r12 - r15)
    mov rbp, rsp
    push rdi        ; save arguments
    push rsi        ; malloc will overwrite them
    
    mov rdi, 16     ; sizeof(unsigned int) * 2 + sizeof(float*) 
    call malloc     ; void* malloc(size_t size)
    
    pop rsi         ; restore arguments
    pop rdi 
    
    test rax, rax   ; if malloc returned NULL
    jz .return
    
.malloc_ok:
    
    mov dword [rax], edi        ; store Matrix->rows
    mov dword [rax + 4], esi    ; store Matrix->cols

    push rax            ; save return value, aligned_alloc will overwrite it
    
    fit_4 rsi           ; makes sizes divides by 4
    fit_4 rdi           ; to increase speed of functions
                        ; because SSE instructions process 
                        ; 4 numbers by instruction
    mov rax, rdi
    mul rsi
    push rax            ; save matrix size for future use
    shl rax, 2          ; * 4, size of float == 4 bytes
    mov rsi, rax        ; size (rows * cols * 4 bytes)
    mov rdi, 16         ; alignment
    call aligned_alloc  ; void* aligned_alloc(size_t alignment, size_t size)
    mov rcx, rax

    pop rsi             ; restore matrix size
    pop rax             ; restore return value
    mov qword [rax + 8], rcx ; store pointer to matrix data // matrix.data = rcx

    ; # Move matrix size to /counter/ register rcx
    ; # Fill the matrix data with 0.0f values
    mov rcx, rsi
    mov rsi, [rax + 8]
.fill_zeroes:
    mov dword [rsi + 4 * rcx - 4], 0.0
    loop .fill_zeroes
   
    ; # just for me
    ; windows: rcx, rdx, r8, r9, stack 
    ; linux:   rdi, rsi, rdx, rcx, r8, r9, stack
    
    
.return:            
    pop_x64
    ret  
   
matrixDelete:
    push_x64            ; save registers by x64 convention
    
    mov r15, rdi        ; store struct address at safe register
    mov rdi, [rdi + 8]  ; pass argument of Matrix->(float* data) to free
    call free           ; free(void* ptr) -- free data
    mov rdi, r15        ; pass struct address to free
    call free           ; free(void* ptr) -- free matrix

    pop_x64             ; restore registers
    ret    

matrixGetRows:
    mov rax, [rdi]      ; just get Matrix->rows
    ret

matrixGetCols:
    mov rax, [rdi + 4] ; just get Matrix->cols
    ret
