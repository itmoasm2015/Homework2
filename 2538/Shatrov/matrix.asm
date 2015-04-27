default rel

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul 

extern calloc
extern malloc
extern free
extern memcpy

section .text

;; also in System V r8 and r9 is args but there is no functions taking so much arguments
%define Arg1 rdi
%define Arg2 rsi
%define Arg3 rdx
%define Arg4 rcx
%define Res rax
	
	;; System V callee saved registers
%macro begin 0			
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15
%endmacro

%macro end 0
	pop r15
	pop r14
	pop r13 
	pop r12
	pop rbx
	pop rbp
	ret
%endmacro


;; rows and cols in matrix are aligned on 4
struc matrix
	.rows:             	resq 1
	.cols:            	resq 1
	.rows_aligned:     	resq 1
	.cols_aligned:    	resq 1 
	.ptr:               resq 1 
endstruc


%macro align_4 1
   add %1, 3  ; add 11b
   and %1, ~3 ;flush last two binary digits.
%endmacro

	;; aligns stack, and call function with given args
	;; saves registers
	;; result in Res
%macro aligned_call 2
	push Arg1
	mov Arg1, %2
	push rbp
	mov rbp, rsp
	and rsp, ~15	; align the stack 
	call %1
	mov rsp, rbp	; restore stack pointer
	pop rbp
	pop Arg1
%endmacro

;call with 2 args
%macro aligned_call2 3
	push Arg2
	mov Arg2, %3
	aligned_call %1, %2
	pop Arg2
%endmacro

;call with 3 args
%macro aligned_call3 4
	push Arg3
	mov Arg3, %4
	aligned_call2 %1, %2, %3
	pop Arg3
%endmacro




;Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
    begin
    mov r12, Arg1	; save input
    mov r13, Arg2
    aligned_call malloc, matrix_size	; allocate memory for struct
    test Res, Res 
    jz .end 			;allocation failed
    mov r14, Res 		;save struc pointer
    ;;set rows and cols
    mov [r14 + matrix.rows], r12
    mov [r14 + matrix.cols], r13
    align_4 r12		;calculate aligned rows and cols
    align_4 r13
    mov [r14 + matrix.rows_aligned], r12
    mov [r14 + matrix.cols_aligned], r13

    ;; calc needed memory for data
    mov rax, r12
    mul r13
    ;;allocate zero-filled memory for data
    ;;void* calloc (size_t num, size_t size);
    aligned_call2 calloc, rax, 4
    test Res, Res
    jz .calloc_fail 	;allocation failed
    mov [r14 + matrix.ptr], Res
    mov Res, r14		;return pointer to struct
    jmp .end

    .calloc_fail:		;;allocation for data failed, but memory for struc was allocated -> free it
    	aligned_call free, r14
    .end:
    end


;void matrixDelete(Matrix matrx)
matrixDelete:
	begin
	mov r12, [Arg1 + matrix.ptr]
	aligned_call free, r12		;free data
	aligned_call free, Arg1		;free struc
    end

;unsigned int matrixGetRows(Matrix matrix)
matrixGetRows:
    xor Res,  Res
    mov Res, [Arg1 + matrix.rows] ;get rows
    ret

;unsigned int matrixGetCols(Matrix matrix)
matrixGetCols:
    xor Res, Res
    mov Res, [Arg1 + matrix.cols] ;get cols
    ret


;;; get element address in memory 
; Args: matrix, row, col, reg for result
%macro get_address 4
   mov r8, %3
   mov rax, [%1 + matrix.cols_aligned]
   mul %2 
   add rax, r8
   shl rax, 2
   mov %4, [%1 + matrix.ptr]
   add %4, rax 
%endmacro

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;result in xmm0
matrixGet:
	begin
    get_address Arg1, Arg2, Arg3, r12 
    movss xmm0, [r12]    ;store float into xmm0
    end
;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
	begin
    get_address Arg1, Arg2, Arg3, r12
    movss [r12], xmm0   ;set float 
    end

;Matrix matrixCopy(Matrix matrix)
matrixCopy:
    begin
    mov r12, Arg1		;save pointer
    mov Arg1, [r12 + matrix.rows]
    mov Arg2, [r12 + matrix.cols]
    call matrixNew   
    mov r14, Res 					;save pointer to copy

    ;; calc size
    mov r15, [r12 + matrix.cols_aligned]
    mov rax, [r12 + matrix.rows_aligned]
    mul r15
    lea rax, [rax * 4]		;size in bytes   
    mov r12, [r12 + matrix.ptr] 	;pointer to source data
    mov r13, [r14 + matrix.ptr]		;pointer to new matrix data	
    ;;void * memcpy ( void * destination, const void * source, size_t num );
    aligned_call3 memcpy, r13, r12, rax
    mov Res, r14
    end

;Matrix matrixScale(Matrix matrix, float k)
matrixScale:
	begin


	sub rsp, 4
	movss [rsp], xmm0		 ;save k on stack, function call can spoil xmm
	call matrixCopy
	movss xmm1, [rsp]
	add rsp, 4
	pshufd xmm1, xmm1, 0 ;copy low bits to all places

	
	mov r12, Res 		;new Matrix pointer

	mov r14, [r12 + matrix.rows_aligned]
	mov rax, [r12 + matrix.cols_aligned]
	mul r14 		;calculate size
	mov r13, [r12 + matrix.ptr] ; data pointer 

	.loop:
		movups xmm0, [r13]		;take 4 floats
		mulps xmm0, xmm1
		movups [r13], xmm0		;save new value
		lea r13, [r13 + 16]
		sub rax, 4
		jnz .loop

	.end:
	mov Res, r12
    end

;Matrix matrixAdd(Matrix a, Matrix b)
matrixAdd:
    ret

;Matrix matrixMul(Matrix a, Matrix b)
matrixMul:
    ret
