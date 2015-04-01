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
              and   %1, -3
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
              
;; @cdecl64
;; Matrix matrixNew(unsigned int rows, unsigned int cols);
;; 
;; Allocates a new matrix of rows*cols size.
;;
;; @param RDI unsigned int rows -- num of rows
;; @param RSI unsigned int cols -- num of cols
;; @return RAX void* -- pointer to matrix struct
matrixNew:    
              CDECL_ENTER 0, 0
              mov   r8, rdi         ; Save real rows
              mov   r9, rsi         ; and cols values

              ROUND_4 rdi           ; Round rows and cols up to 4
              ROUND_4 rsi           ; so rows*cols will divide by 16
              
              mov   rax, rdi
              mul   rsi             ; RAX has matrix size

              mpush rax, r8, r9     ; save our data
              
              mov   rdi, 16
              lea   rsi, [rax + matrix_size] ; 16 bytes in front of data for cols and rows
              call  aligned_alloc

              test  rax, rax        ; Halt in case of allocation error
              jz    .return

              mpop  rcx, r8, r9     ; Restore our data (matrix size in RCX now)

              mov   [rax], r8       
              mov   [rax + matrix.cols], r9

              cld                   ; Clear direction flag just in case
              lea   rdi, [rax + matrix.data]

              mov   rbx, rax        ; Save address in the beginning to zero out RAX
              xor   rax, rax
              rep   stosd           ; Fill data with zeroes
              mov   rax, rbx        ; Restore address
.return:      
              CDECL_RET


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
              mul   r8              ; Now byte offset of necessary row is written into RAX (row * sizeof(float) * matrix.rows)
              movss xmm0, [rdx*4 + rax]
              ret


