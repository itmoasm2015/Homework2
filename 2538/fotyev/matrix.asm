section .text

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



extern malloc
extern free


; SYSTEM V calling convention
;; volatile        
%define Arg1 rdi
%define Arg2 rsi
%define Arg3 rdx
%define Arg4 rcx
%define Arg5 r8
%define Arg6 r9
%define ArgR rax
%define T1 r10
%define T2 r11
;; non volatile
%define R1 r12
%define R2 r13
%define R3 r14
%define R4 r15
%define R5 rbx
%define R1D r12d
%define R2D r13d
%define R3D r14d
%define R4D r15d
%define R5D ebx


;;; Push registers R1 - Rn
%macro SAVEREGS1 0
        push R1
%endmacro
%macro SAVEREGS2 0
        SAVEREGS1
        push R2
%endmacro
%macro SAVEREGS3 0
        SAVEREGS2
        push R3
%endmacro
%macro SAVEREGS4 0
        SAVEREGS3
        push R4
%endmacro
%macro SAVEREGS5 0
        SAVEREGS4
        push R5
%endmacro

;;; Pop registers R1 - Rn
%macro RESTOREREGS1 0
        pop R1
%endmacro
%macro RESTOREREGS2 0
        pop R2
RESTOREREGS1
%endmacro
%macro RESTOREREGS3 0
        pop R3
RESTOREREGS2
%endmacro
%macro RESTOREREGS4 0
        pop R4
RESTOREREGS3
%endmacro
%macro RESTOREREGS5 0
        pop R5
RESTOREREGS4
%endmacro
        
        
; +--------+--------------+--------------+-------------------------+
; |name    |size(bytes)   |offset(bytes) |description              |
; +--------+--------------+--------------+-------------------------+
; |rows    |8 (uint)      |0             |                         |
; +--------+--------------+--------------+-------------------------+
; |cols    |8 (uint)      |8             |                         |
; +--------+--------------+--------------+-------------------------+
; |stride  |8 (uint)      |16            |stride=ceil(cols/8)*8    |
; +--------+--------------+--------------+-------------------------+
; |end     |8 (pointer)   |24            |end=this+32+stride*rows*4|
; +--------+--------------+--------------+-------------------------+
; |data    |stride*rows*4 |32            |Must be aligned to 32    |
; |        |              |              |bytes. Element at row i  |
; |        |              |              |and column j has address |
; |        |              |              |this+(32+stride*i+j)*4   |
; +--------+--------------+--------------+-------------------------+
;                                                                   
;                                                                   
;                                                                   
               
%define OFFSET_ROWS   0
%define OFFSET_COLS   8
%define OFFSET_STRIDE 16        
%define OFFSET_END    24
%define OFFSET_DATA   32

%macro GET_STRIDE 2 	;%1 = ceil(%2/8)*8
; %1 = ceil(%2/8)*8 = (floor((%2-1)/8)+1)*8
        mov %1, %2
        dec %1
        shr %1, 3
        inc %1
        shl %1, 3
%endmacro


;;; returns memory aligned to 32 bytes
;;; [ ... | offset(64bits) | data(returned) | ... ]
; void * memalign32(size_t size)
memalign32:
	push rbp ; enter
	mov rbp, rsp
	
        add Arg1, 32
        and rsp, ~15 ; align the stack (substracts 0 or 8 bytes)
	call malloc
	
	mov T1, ArgR ; save to calculate offset later
        test ArgR, ArgR
        jz .out_of_memory ; malloc returned 0
	; malloc always returns memory aligned to 16 bytes
	shr ArgR, 5 ; / 32
	inc ArgR
	shl ArgR, 5 ; * 32
	mov T2, ArgR
	sub T2, T1 ; calculate offset
	mov [ArgR - 8], T2 ; save offset
.out_of_memory:
	mov rsp, rbp ; leave
	pop rbp
	ret
	
;;; void matrixDelete(Matrix matrix);
matrixDelete:
        test Arg1, Arg1
        jz .dont_delete ; matrixDelete(NULL) shouldnt crash

	push rbp ; enter
	mov rbp, rsp
	
	sub Arg1, [Arg1 - 8]; subtract offset
	and rsp, ~15 ; align the stack
        call free
	mov rsp, rbp ; leave
	pop rbp
.dont_delete:
        ret

; returns uninitialized matrix
;; Matrix matrixNewFast(unsigned int rows, unsigned int cols, unsigned stride);
matrixNewFast:
        SAVEREGS4
        mov R1, Arg1
        mov R2, Arg2
        mov R3, Arg3
        ; calculate data size (stride * rows * 4 + OFFSET_DATA)
        mov rax, R3
        shl rax, 2
        mul Arg1
        test rax, rax
        jnz .nonzero
; zero matrix ( rows == 0 or cols == 0)
        mov R3, 8 ; pretend its size is 1 x 8
        mov rax, 8
.nonzero:
        add rax, OFFSET_DATA
        mov R4, rax
        ; allocate memory
;; ArgR = memalign32(rax)
        mov Arg1, rax
        call memalign32
        test ArgR, ArgR
        jz .out_of_memory
	; setup matrix in ArgR
        mov [ArgR + OFFSET_ROWS], R1 ; rows
        mov [ArgR + OFFSET_COLS], R2 ; cols
        mov [ArgR + OFFSET_STRIDE], R3 ; stride
        lea T2, [ArgR + R4]
        mov [ArgR + OFFSET_END], T2 ; end
;done
.out_of_memory:
	RESTOREREGS4
	ret

	

;; Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
	GET_STRIDE Arg3, Arg2
	call matrixNewFast
;; set data to 0
        lea T1, [ArgR + OFFSET_DATA] ; data begin ptr
        mov T2, [ArgR + OFFSET_END] ; data end ptr

	vzeroall
.setzero_loop:
;; TODO unroll ?
; put zeroes
	vmovaps [T1], ymm0
	
	add T1, 8 * 4 ; 256 bits
	cmp T1, T2
	jne .setzero_loop

;; address is in ArgR
	ret



;;; unsigned int matrixGetRows(Matrix matrix);
matrixGetRows:
	mov ArgR, [Arg1 + OFFSET_ROWS]
	ret
;;; unsigned int matrixGetCols(Matrix matrix);
matrixGetCols:
        mov ArgR, [Arg1 + OFFSET_COLS]
        ret
;;;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
matrixGet:
;; matrix[row][col] = *(matrix + OFFSET_DATA + (row * stride + col) * sizeof(float))
	mov rax, [Arg1 + OFFSET_STRIDE] ;stride
        mov T1, Arg3 ; Arg3 = rdx, save it
	mul Arg2 ; rax *= row
	add rax, T1 ; rax += col
        shl rax, 2 ; rax *= 4
	movss xmm0, [Arg1 + OFFSET_DATA + rax]
	ret
;;;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
matrixSet:
        mov rax, [Arg1 + OFFSET_STRIDE] ;stride
        mov T1, Arg3
        mul Arg2 ; rax *= row
        add rax, T1 ; rax += col
        shl rax, 2 ; rax *= 4
        movss [Arg1 + OFFSET_DATA + rax], xmm0
	ret


;;; Matrix matrixScale(Matrix matrix, float k);
matrixScale:
	SAVEREGS2 ; although R2 is not used in this procedure, saving an even number of registers is required to align stack properly
	mov R1, Arg1
	mov Arg1, [R1 + OFFSET_ROWS]
	mov Arg2, [R1 + OFFSET_COLS]
	mov Arg3, [R1 + OFFSET_STRIDE]
	call matrixNewFast
;; pointer to the new matrix is in ArgR

	lea T1, [R1 + OFFSET_DATA] ; void * start
	mov T2, [R1 + OFFSET_END] ; void * end
	lea Arg1, [ArgR + OFFSET_DATA] ; void * out
	

; broadcast multiplier into ymm15
        movss [rsp-4], xmm0
	vzeroall
        vbroadcastss ymm15, [rsp-4]

; unrolled loop, processes 15x256 bits at once
	lea Arg6, [T1 + 8*4*15]
	cmp Arg6, T2
	jae .mul_loop ; if(start + 8 * 15 >= end) goto mul_loop
.unrolled_mul_loop:

%macro LOAD 1 ; ymm%1 = T1[8*%1]
	vmovaps ymm%1, [T1+8*4*%1]
%endmacro
%macro MUL_SCALAR 1 ; ymm%1 *= ymm15
        vmulps ymm%1, ymm%1, ymm15
%endmacro
%macro STORE 1 ; Arg1[8*%1] = ymm%1
        vmovaps [Arg1+8*4*%1], ymm%1
%endmacro
%macro REPEAT_15 1
%assign regn 0
%rep 15
        %1 regn
%assign regn regn+1
%endrep
%endmacro
        REPEAT_15 LOAD
        REPEAT_15 MUL_SCALAR
        REPEAT_15 STORE
        
%undef REPEAT_15

        mov T1, Arg6 ; start += 8 * 15
        add Arg6, 8*4*15
        add Arg1, 8*4*15 ; out += 8 * 15
        cmp Arg6, T2 ; if(start + 8 * 15 >= end) goto mul_loop
        jb .unrolled_mul_loop

.mul_loop: ; simple loop, processes 256 bits (8 floats) at once

        LOAD 0
        MUL_SCALAR 0
        STORE 0
%undef LOAD
%undef MUL_SCALAR
%undef STORE

	
	add T1, 8*4 ; start += 8, out += 8
	add Arg1, 8*4
	cmp T1, T2 ; while(start != end)
	jne .mul_loop

	RESTOREREGS2
	ret
	

;;; Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:
	mov T1, [Arg1 + OFFSET_ROWS] ; rows
	mov T2, [Arg1 + OFFSET_COLS] ; cols
	cmp T1, [Arg2 + OFFSET_ROWS]
	jne incorrect_size
	cmp T2, [Arg2 + OFFSET_COLS]
	jne incorrect_size

        SAVEREGS2
        mov R1, Arg1 ; a
	mov R2, Arg2 ; b

        mov Arg1, T1 ; rows
        mov Arg2, T2 ; cols
	mov Arg3, [R1 + OFFSET_STRIDE] ; stride
        call matrixNewFast
;; new matrix is in ArgR

        vzeroall
        lea T1, [R1 + OFFSET_DATA] ; void * start1
        mov T2, [R1 + OFFSET_END] ; void * end1
	lea Arg2, [R2 + OFFSET_DATA] ; void * start2
        lea Arg1, [ArgR + OFFSET_DATA] ; void * out
        mov Arg6, T1 ; void * start_new

; unrolled loop (8x256bit)
        add Arg6, 8*4*8
        cmp Arg6, T2
        jae .add_loop
.unrolled_add_loop:

%macro LOAD_2 2
        vmovaps ymm%1, [T1+8*4*%1]
	vmovaps ymm%2, [Arg2+8*4*%1]
%endmacro
%macro ADD_2 2
        vaddps ymm%1, ymm%1, ymm%2
%endmacro
%macro STORE 2
        vmovaps [Arg1+8*4*%1], ymm%1
%endmacro

%macro REPEAT_8 1
%assign regn1 0
%assign regn2 8
%rep 8
        %1 regn1, regn2
%assign regn1 regn1+1
%assign regn2 regn2+1
%endrep
%endmacro

        REPEAT_8 LOAD_2
        REPEAT_8 ADD_2
        REPEAT_8 STORE 

%undef LOAD_2
%undef ADD_2
%undef STORE
%undef REPEAT_8


        mov T1, Arg6 ; start1 += 8 * 8
        add Arg2, 8*4*8 ; start2 += 8 * 8
        add Arg1, 8*4*8 ; out += 8 * 8

        add Arg6, 8*4*8
        cmp Arg6, T2
        jb .unrolled_add_loop

.add_loop:
; *Arg1 = *T1 + *Arg2
        
        vmovaps ymm0, [T1]
	vmovaps ymm1, [Arg2]

        vaddps ymm0, ymm0, ymm1
        vmovaps [Arg1], ymm0

        add T1, 8*4 ; start1 += 8
        add Arg2, 8*4 ; start2 += 8
        add Arg1, 8*4 ; out += 8
        cmp T1, T2 ; }while(start1 != end1)
        jne .add_loop

	RESTOREREGS2
        ret

; C = AB
; C[row][col] = inner_product(A[row], (B^T)[col])
;Matrix matrixMul(Matrix a, Matrix b);	
matrixMul:
        mov T1, [Arg1 + OFFSET_ROWS] ; rows1
        mov T2, [Arg1 + OFFSET_COLS] ; cols1
        cmp T2, [Arg2] ; cols1 == rows2
        jne incorrect_size
	SAVEREGS4
	mov R1, Arg1
	mov R2, Arg2
        
	mov Arg1, T1 ; rows
	mov Arg2, [R2 + OFFSET_COLS] ; cols
	mov Arg3, [R2 + OFFSET_STRIDE]
	call matrixNewFast
        test ArgR, ArgR
        jz .out_of_memory
        mov R3, ArgR
; output matrix is now in R3

; ArgR = matrixTranspose(b)
        mov Arg1, R2
        call matrixTranspose
; b is not needed anymore
 
	vzeroall

        
	lea Arg1, [R1 + OFFSET_DATA] ; start_a
        mov R2, Arg1 ; cur_row_start_a
        mov T1, [R1 + OFFSET_STRIDE] ; stride_a = stride_b^t
        
        ; cmp T1, [ArgR + OFFSET_STRIDE] ; assert(a.stride == bt.stride)
        ; jne incorrect_size
        
	lea Arg3, [ArgR + OFFSET_DATA] ; start_b^t
        lea Arg2, [Arg3 + 4 * T1] ; row_end_b^t
	lea Arg4, [R3 + OFFSET_DATA] ; out
        mov R4, [R3 + OFFSET_COLS] ; out_columns
        lea Arg5, [Arg4 + 4 * R4] ; out_row_end
        mov T2, [R3 + OFFSET_STRIDE] ; stride_out
        lea Arg6, [Arg4 + 4 * T2] ; out_next_row


.loop:
; inner product, *Arg4 = Arg1[0] * Arg3[0] + ... 
        vmovaps ymm0, [Arg1]
        vmovaps ymm1, [Arg3]
        vmulps ymm2, ymm0, ymm1
        vaddps ymm3, ymm3, ymm2

        add Arg1, 8*4
        add Arg3, 8*4
        cmp Arg3, Arg2 ; while(col < (b^T).columns)
        jne .loop
; ymm3[0:31] = sum (ymm3)
; https://software.intel.com/en-us/forums/topic/281843
        vhaddps ymm3,ymm3,ymm3
        vhaddps ymm3,ymm3,ymm3
        vperm2f128 ymm4,ymm3,ymm3,0x11
        vaddps ymm3,ymm3,ymm4
; computed 1 cell
        movss [Arg4], xmm3
; next column (out)
        add Arg4, 4 ; out++
 
        vxorps ymm3, ymm3 ; ymm3 = 0
        
; next row (b^t)
        lea Arg2, [Arg3 + 4 * T1] ; row_end
; reset column (a)
        mov Arg1, R2

        cmp Arg4, Arg5 ; while(out != out_row_end)
        jne .loop
; next row (a)
        lea R2, [R2 + 4 * T1]
        mov Arg1, R2
; reset row (b^t)
        lea Arg3, [ArgR + OFFSET_DATA]
        lea Arg2, [Arg3 + 4 * T1] ; row_end

; next row (out)
        mov Arg4, Arg6
        lea Arg6, [Arg4 + 4 * T2] ; out_next_row
        lea Arg5, [Arg4 + 4 * R4] ; out_row_end

        cmp Arg4, [R3 + OFFSET_END] ; while(out != out_end)
        jne .loop

; done
        
; delete b^t
        mov Arg1, ArgR
        call matrixDelete
        
        mov ArgR, R3
.out_of_memory:
	RESTOREREGS4
        ret
        

; Matrix matrixTranspose(Matrix m)
matrixTranspose:
        SAVEREGS4
        mov R1, Arg1
        mov R2, [Arg1 + OFFSET_ROWS] ; rows
        mov R3, [Arg1 + OFFSET_COLS] ; cols
        mov Arg1, R3
        mov Arg2, R2
        call matrixNew
; new matrix is in ArgR
        mov Arg4, [ArgR + OFFSET_STRIDE] ; stride_t
        lea T1, [R1 + OFFSET_DATA] ; start
        lea T2, [T1 + 4 * R3] ; row_end
        
        mov Arg5, [R1 + OFFSET_STRIDE] ; stride
        lea Arg6, [T1 + 4 * Arg5] ; next_row_start
        
        lea Arg1, [ArgR + OFFSET_DATA] ; start_t
        mov Arg2, Arg1 ; cur_column
        lea Arg3, [Arg1 + 4 * R2] ; row_end_t

.loop:
; copy from row to column
        mov dword R4D, [T1]
        add T1, 4 ; column++
        mov dword [Arg2], R4D
        lea Arg2, [Arg2 + 4 * Arg4] ; row++
        cmp T1, T2 ; while(column != num_columns)
        jne .loop
; next row
        mov T1, Arg6
        lea Arg6, [Arg6 + 4 * Arg5] ; next_row_start
        lea T2, [T1 + 4 * R3] ; row_end
;next column
        add Arg1, 4
        mov Arg2, Arg1
        cmp Arg3, Arg1 ; while(column_t != num_rows)
        jne .loop
; done
	RESTOREREGS4
        ret
        
        
incorrect_size:
; return 0
        xor ArgR, ArgR
        ret	
        