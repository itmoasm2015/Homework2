;; Convenience macros

;; mpush - pushes multiple values on stack
;; in given order
%macro mpush 1-*
%rep  %0
              push  %1              
%rotate 1
%endrep
%endmacro

;; mpop - pops values from the stack to registers
;; in reversed order.
%macro  mpop 1-*
%rep %0
%rotate -1
              pop   %1              
%endrep
%endmacro

%macro  madd 2-*
%assign x %1
%rep %0-1
%rotate -1
              add   %1, x
%endrep
%endmacro

;; save registers and allocate stack space
%macro CDECL_ENTER 2
              mpush rbp, rbx, r12, r13, r14, r15
              enter %1, %2
%endmacro

;; restore registers and clean stack space
%macro CDECL_RET 0
              leave
              mpop  rbp, rbx, r12, r13, r14, r15
              ret
%endmacro

;; round number up by 4
%macro ROUND_4 1
              add   %1, 3
              and   %1, -4
%endmacro

;; CODE STARTS HERE ;;
              
section .text

extern aligned_alloc
extern free

global matrixNew, matrixDelete, matrixGetRows, matrixGetCols, matrixGet, matrixSet, matrixScale, matrixAdd, matrixMul

;; struct Matrix {
;;     uint64_t rows;
;;     uint64_t cols;
;;     float data[] __attribute__ ((aligned (16)));
;; };
              struc matrix
.rows:        resq  1
.cols:        resq  1
.data:       
              endstruc 
              
;; Matrix matrixNewRaw(unsigned int rows, unsigned int cols);
;; 
;; Allocates a new matrix of rows*cols size, does not zeroing out the data.
;;
;; @param RDI unsigned int rows -- num of rows
;; @param RSI unsigned int cols -- num of cols
;; @return RAX void* -- pointer to matrix struct
;; @return RCX unsigned int -- size of matrix (align(rows) * align(cols))
matrixNewRaw:    
              CDECL_ENTER 0, 0
              mov   r8, rdi         ; Save real rows
              mov   r9, rsi         ; and cols values

              ROUND_4 rdi           ; Round rows and cols up to 4
              ROUND_4 rsi           ; so rows*cols will divide by 16
              
              mov   rax, rdi
              mul   rsi             ; RAX has matrix size

              mpush rax, r8, r9     ; save our data
              
              mov   rdi, 16
              lea   rsi, [rax*4 + matrix_size] ; 16 bytes in front of data for cols and rows
              call  aligned_alloc

              test  rax, rax        ; Halt in case of allocation error
              jz    .return

              mpop  rcx, r8, r9     ; Restore our data (matrix size in RCX now)

              mov   [rax], r8       
              mov   [rax + matrix.cols], r9
.return:      
              CDECL_RET
            
;; @cdecl64            
;; Matrix matrixNew(unsigned int rows, unsigned int cols);
;; 
;; Allocates a new matrix of rows*cols size, filled with zeroes.
;;
;; @param RDI unsigned int rows -- num of rows
;; @param RSI unsigned int cols -- num of cols
;; @return RAX void* -- pointer to matrix struct
matrixNew:
              call  matrixNewRaw
              lea   rdi, [rax + matrix.data]

              mov   r8, rax          ; Save RAX because we need it to zero out data
              xor   rax, rax
              cld                    ; Clear direction flag just in case

              rep   stosd
              mov   rax, r8          ; Restore RAX
              ret
;; @cdecl64
;; void matrixDelete(Matrix matrix);
;;
;; free()'s memory, allocated for matrix
;;
;; @param RDI void* matrix -- matrix address
matrixDelete:
              call  free
              ret

              
;; @cdecl64
;; unsigned int matrixGetRows(Matrix matrix);
;;
;; Returns rows count of matrix
;;
;; @param RDI void* matrix -- matrix address
;; @return RAX unsigned int -- rows count
matrixGetRows:
              mov   rax, [rdi]
              ret


;; @cdecl64
;; unsigned int matrixGetCols(Matrix matrix);
;;
;; Returns cols count of matrix
;;
;; @param RDI void* matrix -- matrix address
;; @return RAX unsigned int -- cols count
matrixGetCols:
              mov   rax, [rdi + matrix.cols]
              ret


;; @cdecl64
;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;;
;; Gets matrix[rows][cols]
;;
;; @param RDI void* matrix -- matrix address
;; @param RSI unsigned int row -- row index
;; @param RDX unsigned int col -- col index
;; @return XMM0 float -- corresponding matrix element
matrixGet:
              lea   rax, [rsi*4]
              mov   r8, [rdi]
              mul   r8              
              lea   rax, [rax + rdi + matrix_size] ; Now address of necessary row beginning is written into RAX (matrix + 16 + row * sizeof(float) * matrix->rows)

              movss xmm0, [rax + rdx*4]
              ret


;; @cdecl64
;; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;;
;; Sets matrix[rows][cols]
;;
;; @param RDI void* matrix -- matrix address
;; @param RSI unsigned int row -- row index
;; @param RDX unsigned int col -- col index
;; @param XMM0 float value -- a value to set
matrixSet:
              lea   rax, [rsi*4]
              mov   r8, [rdi]
              mul   r8
              lea   rax, [rax + rdi + matrix_size] ; Now address of necessary row beginning is written into RAX (matrix + 16 + row * sizeof(float) * matrix->rows)

              movss [rax + rdx*4], xmm0 
              ret


;; @cdecl64
;; Matrix matrixScale(Matrix matrix, float value);
;;
;; Multiply every matrix element by value 
;;
;; @param RDI void* matrix -- matrix address
;; @param XMM0 float value -- a value to Multiply
;; @return RAX void* -- pointer to a scaled matrix
matrixScale:
              push rdi               ; Save input matrix address

              mov    rsi, [rdi + matrix.cols] ; Pass arguments
              mov    rdi, [rdi]               ; to matrixNewRaw
              call   matrixNewRaw             ; RAX = matrix pointer, RCX - matrix scaled size

              shufps xmm0, xmm0, 0   ; Spread the 0th element of xmm0 (it's passed value) all over the xmm0 ([a, b, c, d] -> [a, a, a, a])

              pop    rdi                      ; Restore input matrix address
              add    rdi, matrix.data         ; Set RDI to the beginning of input matrix
              lea    rsi, [rax + matrix.data] ; Set RSI to the beginning of output matrix

              shr    rcx, 2          ; Divide by 4 to use DEC instead of SUB
.mul_loop:
              movaps xmm1, [rdi]     ; Perform multiplication
              mulps  xmm1, xmm0
              movaps [rsi], xmm1

              madd   16, rdi, rsi    ; and shift all the indices
              dec    rcx
              jnz    .mul_loop

              ret


;; @cdecl64
;; Matrix matrixAdd(Matrix a, Matrix b);
;;
;; Sums 2 matrices. 
;;
;; @param RDI void* a -- first summand
;; @param RSI void* b -- second summand
;; @return RAX void* -- pointer to a sum
matrixAdd:
              mov    r8, [rdi]                   ; a.rows
              mov    r9, [rdi + matrix.cols]     ; a.cols
              mov    r10, [rsi]                  ; b.rows
              mov    r11, [rsi + matrix.cols]    ; b.cols

              xor    rax, rax        ; return NULL by default
              cmp    r8, r10         ; Compare dimensions
              jne    .return         ; of matrices

              cmp    r9, r11         ; and return NULL
              jne    .return         ; if they don't match

              mpush  rdi, rsi        ; Save summands addresses

              mov    rdi, r8
              mov    rsi, r9
              call matrixNewRaw

              mpop   rdi, rsi        ; Restore summand addresses
              push   rax             ; and save new matrix address

              madd   matrix_size, rdi, rsi, rax
              shr    rcx, 2          ; Divide by 4 to use DEC instead of SUB 
.sum_loop:    
              movaps xmm0, [rdi]
              movaps xmm1, [rsi]
              addps  xmm0, xmm1
              movaps [rax], xmm0

              madd   16, rdi, rsi, rax
              dec    rcx
              jnz    .sum_loop

              pop    rax             ; Restore new matrix address
.return:
              ret