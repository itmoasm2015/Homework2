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
global matrixGet
global matrixSet
global matrixScale

;  # Matrix data type definition
;
;  typedef struct {
;      unsigned int rows;
;      unsigned int cols;
;      float* data;
;  } *Matrix;


section .text
    
; Matrix matrixNewExt(unsigned int rows, unsigned int cols, int flag);
matrixNew:
    enter 0, 0 
    push_x64        ; save needed registers (from rbx, r12 - r15)
    mov rbp, rsp
    ;push rdx            ; save flag
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
    xor r15, r15        ; clean high 32 bits
    mov r15d, eax       ; because arguments are 32bit values
    mov rax, r15        ; so in high 32 bits of registers can be 
    mov r15d, esi       ; stored random values
    mov rsi, r15        ; clean them, make everyone happy
    mul rsi
    push rax            ; save matrix size for future use
    shl rax, 2          ; * 4, size of float == 4 bytes
    mov rsi, rax        ; size (rows * cols * 4 bytes)
    mov rdi, 16         ; alignment
    call aligned_alloc  ; void* aligned_alloc(size_t alignment, size_t size)
    mov rcx, rax

    pop rsi             ; restore matrix size
    pop rax             ; restore return value
    ;pop rdx             ; restore flag
    mov qword [rax + 8], rcx ; store pointer to matrix data // matrix.data = rcx

    ;test edx, edx
    ;jz .return               ; if flag == 0 than skip initialization
    ; # Move matrix size to /counter/ register rcx
    ; # Fill the matrix data with 0.0f values
    mov ebx, 1
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
    leave
    ret  

;matrixNew:
;    mov rdx, 1
;    call matrixNewExt
;    ret
;
;matrixAlloc: 
;    mov rdx, 0
;    call matrixNewExt
;    ret

; void matrixDelete(Matrix matrix)   
matrixDelete:
    enter 0, 0
    push_x64            ; save registers by x64 convention
    mov rbp, rsp

    mov r15, rdi        ; store struct address at safe register
    mov rdi, [rdi + 8]  ; pass argument of Matrix->(float* data) to free
    call free           ; free(void* ptr) -- free data
    mov rdi, r15        ; pass struct address to free
    call free           ; free(void* ptr) -- free matrix

    pop_x64             ; restore registers
    leave
    ret    

; unsigned int matrixGetRows(Matrix matrix)
matrixGetRows:
    mov rax, [rdi]      ; just get Matrix->rows
    ret

; unsigned int matrixGetCols(Matrix matrix)
matrixGetCols:
    mov rax, [rdi + 4] ; just get Matrix->cols
    ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
matrixGet:
    enter 0, 0
    xor rax, rax            ; clear high 32 bits for future use
    mov eax, [rdi + 4]      ; rax = matrix->cols
    fit_4 eax               ; make rax divides by 4
    xor rcx, rcx            ; clear high 32 bits
    mov ecx, edx            ; r8 = rdx // save rdx before multiply
    mul esi                 ; edx:eax = row * fit_cols
    add rax, rcx            ; eax = row * fit_cols + col // real index in data
    shl rdx, 32             ; we have 64 bit number in format (edx:eax) 
    add rax, rdx            ; pack it into one 64-bit register rax
    mov r8, [rdi + 8]       ; r8 = matrix->data 
    movss xmm0, [r8 + 4 * rax]  ; return matrix->data[real_index * sizeof(float)]
    leave
    ret

; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
    enter 0, 0
    xor rax, rax            ; clear high 32 bits for future use
    mov eax, [rdi + 4]      ; rax = matrix->cols
    fit_4 eax               ; make rax divides by 4
    xor rcx, rcx            ; clear high 32 bits
    mov ecx, edx            ; r8 = rdx // save rdx before multiply
    mul esi                 ; edx:eax = row * fit_cols
    add rax, rcx            ; eax = row * fit_cols + col // real index in data
    shl rdx, 32             ; we have 64 bit number in format (edx:eax) 
    add rax, rdx            ; pack it into one 64-bit register rax
    mov r8, [rdi + 8]       ; r8 = matrix->data 
    movss [r8 + 4 * rax], xmm0 ; set matrix value to matrix element 
    leave
    ret

; Matrix matrixScale(Matrix matrix, float k)
matrixScale:
    push_x64
    enter 0, 0
        
    
    mov r15, rdi            ; save pointer to input matrix
    mov edi, [r15]
    mov esi, [r15 + 4]
    ;call matrixAlloc
    call matrixNew
    mov rdi, r15
    mov r14, rax
    mov r13, [r14 + 8]

    pshufd xmm0, xmm0, 0    ; copy 1st float from xmm0 to all
        
    xor rax, rax            ; clean high 32 bits again
    xor rcx, rcx            ; :( seriously, 32bit arguments are not cool
    mov eax, [rdi]          ; get matrix->rows
    mov ecx, [rdi + 4]      ; get matrix->cols
    fit_4 eax               ; makes sizes divides by 4 
    fit_4 ecx               ; for SSE packed operations
    mul rcx                 ; calc size of matrix
    mov rsi, [rdi + 8]      ; store pointer to matrix->data
            
.multiply_loop:
    movaps xmm1, [rsi + 4 * rax - 16]   ; load 128 bits from aligned memory
    mulps xmm1, xmm0                    ; packed multiply
    movaps [r13 + 4 * rax - 16], xmm1   ; store 128 bits back
    sub rax, 4                          ; to the next 128 bits!
    jnz .multiply_loop

    mov rax, r14 

    leave
    pop_x64
    ret 
