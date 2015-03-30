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
global matrixAdd
global matrixMul
global matrixTranspose

;  # Matrix data type definition
;
;  typedef struct {
;      unsigned int rows;
;      unsigned int cols;
;      float* data;
;  } *Matrix;


section .text
    
; Matrix matrixNewExt(unsigned int rows, unsigned int cols, int flag);
; # Allocates new matrix of size rows x cols and initialize with zeroes if flag != 0
matrixNewExt:
    enter 0, 0 
    push_x64        ; save needed registers (from rbx, r12 - r15)
    mov rbp, rsp
    push rdx            ; save flag
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
    pop rdx             ; restore flag
    mov qword [rax + 8], rcx ; store pointer to matrix data // matrix.data = rcx
    
    test rcx, rcx       ; if aligned_alloc returned NULL
    jnz .after_null
    mov rdi, rax        ; 1st argument of free -- pointer to matrix
    call free           ; free alloc'd memory for matrix's struct
    xor rax, rax        ; return NULL
    jmp .return     
        

.after_null:
    test edx, edx
    jz .return               ; if flag == 0 than skip initialization
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

; Matrix matrixNew(unsigned int rows, unsigned int cols)
matrixNew:
    mov rdx, 1
    call matrixNewExt
    ret

; # Allocates matrix of size rows x cols without initialization
matrixAlloc: 
    mov rdx, 0
    call matrixNewExt
    ret

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
    enter 0, 0
    push_x64
        
    
    mov r15, rdi            ; save pointer to input matrix
    mov edi, [r15]          ; 1st argument -- rows
    mov esi, [r15 + 4]      ; 2nd argument -- cols
    call matrixAlloc        ; allocate matrix of equal size
    test rax, rax           ; if matrixAlloc returned NULL
    jz .return              ; return NULL too
    mov rdi, r15            ; restore pointer to input matrix
    mov r14, rax            ; save pointer to allocated matrix
    mov r13, [r14 + 8]      ; save pointer to data of allocated matrix

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
    movaps [r13 + 4 * rax - 16], xmm1   ; store 128 bits to result
    sub rax, 4                          ; to the next 128 bits!
    jnz .multiply_loop

    mov rax, r14 

.return:
    pop_x64
    leave
    ret

; Matrix matrixAdd(Matrix a, Matrix b)
matrixAdd:
    enter 0, 0
    push_x64
    
    xor rax, rax        
    mov ecx, [rdi]          ; compare rows
    cmp ecx, [rsi]
    jne .return             ; return 0 if sizes are not equal
    mov ecx, [rdi + 4]
    cmp ecx, [rsi + 4]      ; compare cols
    jne .return 

    push rdi
    push rsi
    mov edi, [rdi]          ; 1st argument -- rows
    mov esi, ecx            ; 2nd argument -- cols, rest in ecx (high half of rsi unused)
    call matrixAlloc        ; allocate matrix of equal to input matrices size
    pop rsi
    pop rdi
    
    test rax, rax           ; if matrixAlloc returned NULL
    jz .return              ; return NULL too
    mov r15, rax            ; store pointer to allocated matrix
    mov r14, [rax + 8]      ; save pointer to allocated matrix's data
    
    xor rcx, rcx            ; what are we doing?
    xor rax, rax            ; yes, cleaning up high 32 bits again
    mov ecx, [rdi]          ; load sizes again
    mov eax, [rdi + 4]      ; because call of functions could erase our registers
    fit_4 rcx               ; makes sizes divides by 4
    fit_4 rax               ; for SSE packed instructions
    mul rcx                 ; mul by 64bit register to store entire result in rax
    mov rdi, [rdi + 8]      ; save pointers to input matrices data
    mov rsi, [rsi + 8]      ; pointer to input matrices are not needed anymore
    
.add_loop:
    movaps xmm0, [rdi + 4 * rax - 16]   ; load 128 bits from aligned memory for first matrix
    movaps xmm1, [rsi + 4 * rax - 16]   ; and for second
    addps xmm1, xmm0                    ; packed add
    movaps [r14 + 4 * rax - 16], xmm1   ; store 128 bits to result
    sub rax, 4                          ; to the next 128 bits!
    jnz .add_loop
    mov rax, r15            ; return pointer to the resulting matrix    

.return:
    pop_x64
    leave 
    ret 

; Matrix matrixTranspose(Matrix a)
; # Allocates new matrix with size (a->cols x a->rows)
;   and elements: result[i][j] = a[j][i]
matrixTranspose:
    enter 0, 0
    push_x64

    mov r15, rdi
    mov edi, [r15 + 4]
    mov esi, [r15]
    call matrixAlloc
    mov r14, rax
    xor rax, rax
    xor rsi, rsi
    mov esi, [r15 + 4]
    mov eax, [r15]
    fit_4 rax
    fit_4 rsi
    push r11
    mov r11, rax
    mul rsi
    mov r15, [r15 + 8]
    mov rbx, [r14 + 8]
    
    mov rcx, rax
.fill:
    mov r13d, dword [r15 + 4 * rcx - 4]
    mov rax, rcx
    dec rax
    xor rdx, rdx
    div rsi
    xchg rax, rdx
    mov r12, rdx
    mul r11
    add rax, r12
    mov dword [rbx + 4 * rax], r13d
    loop .fill
    mov rax, r14

    pop r11

.return:
    pop_x64
    leave
    ret

; Matrix matrixMul(Matrix a, Matrix b)
matrixMul:
    enter 0, 0
    push_x64
        
    ; # Multiplication is correct only if a->cols == b->cols
    ;   If it's true, sizes of resulting matrix will be:
    ;   result->rows = a->rows
    ;   result->cols = b->rows
    mov eax, [rdi + 4]      ; load a->cols
    cmp eax, [rsi + 4]      ; compare with b->cols
    xor rax, rax            ; return NULL if not equals
    jne .return 

    push rdi                ; save pointer to a
    push rsi                ; save pointer to b
    mov rdi, [rdi]          ; 1st argument is a->rows 
    mov rsi, [rsi]          ; 2nd argument if b->rows
    call matrixAlloc        ; allocate resulting matrix
    pop rsi                 ; restore pointer to b
    pop rdi                 ; restore pointer to a
    test rax, rax           ; if matrixAlloc failed
    jz .return              ; return NULL

    xor r13, r13             ; clear high 32 bits
    xor r14, r14            
    xor r15, r15
    mov r13d, [rdi + 4]      ; save a->cols == b->cols
    mov r14d, [rdi]          ; save result's rows
    mov r15d, [rsi]          ; save result's cols
  
    push rax
    push rdi
    
    xchg rdi, rsi
    call matrixTranspose
    mov rsi, rax

    pop rdi 
    pop rax
    
     

    mov rdi, rsi
    call free
         
.return:
    pop_x64
    leave
    ret
