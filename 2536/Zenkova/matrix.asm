section .text

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
global matrixClone
global matrixTranspose

;we need number to be rounded to the nearest greater 4-divisible
%macro align_by_4 1 ;((x + 3) / 4) * 4
	add %1, 3
	shr %1, 2
	shl %1, 2
%endmacro

;rows and columns are stored aligned by 4
;so we can use them in SSE (vector) instructions
struc Matrix
	cells:			resq 1 ;pointer to float array of values
	rows:			resq 1 ;number of rows
	columns:		resq 1 ;number of columns
	aligned_rows:		resq 1 ;aligned number of rows
	aligned_columns:	resq 1 ;aligned number of columns
endstruc

;Matrix matrixNew(unsigned int rows, unsigned int columns)
;
;creates: new instance of Matrix
;
;takes: RDI - number of rows
;	RSI - number of columns
;
;returns: RAX - pointer to created Matrix, if succeded, and null instead

matrixNew:
	push rdi ;save needed registers
	push rsi

	mov rdi, Matrix_size 
	call malloc ;allocate memory for new Matrix
	
	mov rcx, rax ;malloc saves pointer to allocated space in rax, let's store it in rcx
	pop rsi
	pop rdi
	
	mov [rax+rows], rdi ;initialize matrix parameters
	mov [rax+columns], rsi 
	
	align_by_4 rdi ;align rows
	align_by_4 rsi ;align colums

	mov [rax+aligned_rows], rdi ;initialize aligned matrix parameters
	mov [rax+aligned_columns], rsi
	
	imul rdi, rsi ;define aligned matrix size
	mov rsi, 4 ;sizeof float
	push rcx
	
	call calloc ;allocate exact memory space for matrix
	
	pop rcx
	
	mov [rcx+cells], rax ;calloc uses rax in the same way as malloc, so we have pointer to allocated space or null, if allocation failed, in rax

	mov rax, rcx ;in rcx we stored pointer to Matrix, so let's move it to rax and return as result
	
	ret


 

