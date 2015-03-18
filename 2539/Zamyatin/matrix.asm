extern 		malloc
extern 		free
global 		hui
global 		matrixNew
global		matrixDelete
global 		matrixGetRows
global 		matrixGetCols
global 		matrixGet
global 		matrixSet
global 		matrixScale
global		matrixAdd
global 		matrixMul

;Matrix matrixNew(unsigned int rows, unsigned int cols);
;void matrixDelete(Matrix matrix);
;unsigned int matrixGetRows(Matrix matrix);
;unsigned int matrixGetCols(Matrix matrix);
;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
;Matrix matrixScale(Matrix matrix, float k);
;Matrix matrixAdd(Matrix a, Matrix b);
;Matrix matrixMul(Matrix a, Matrix b); 
;rdi - rsi - rdx.
;ret - rax

	
;Allocates 8 + n * m * 4 bytes. In first two dwords keeps "n" and "m".
;Returns pointer at begin of data.
;Keeps matrix as N concatenated lines which size is M.
;rdi - n
;rsi - m
matrixNew:
	sub 	rsp, 32
	mov 	[rsp + 16], rsi
	mov 	[rsp + 8], rdi
	imul 	rdi, rsi
	shl 	rdi, 2
	mov 	[rsp + 24], rdi
	add 	rdi, 8
	call 	malloc
	mov 	rdi, [rsp + 24]
	mov 	rsi, [rsp + 8]
	mov 	[rax], esi
	mov 	rsi, [rsp + 16]
	mov 	[rax + 4], esi
	mov 	[rsp + 8], rax
	add 	rax, 8
	mov 	rsi, rdi
	add 	rdi, rax
	test  	rsi, 1 << 2
	jz 		.even
	mov 	qword [rax], 0
	add 	rax, 4
.even:
.fill_zeroes:
	cmp 	rax, rdi
	jz  	.finish
	mov 	qword [rax], 0
	add   	rax, 8
	jmp 	.fill_zeroes
.finish:	
	mov 	rax, [rsp + 8]
	add 	rsp, 32
	ret
	
;In rdi begin of data. 
matrixDelete:
	call 	free
	ret


;rdi - ptr
;ans in rax
matrixGetRows:
	mov 	rax, [rdi]
	ret


;rdi - ptr
;ans in rax
matrixGetCols:
	mov 	rax, [rdi + 4]	
	ret


;rdi - ptr
;rsi - row
;rdx - column
;ans in xmm0
matrixGet:
	imul 	esi, dword [rdi + 4]
	add 	rsi, rdx
	movss 	xmm0, [rdi + rsi*4 + 8] ; movss or movlps?????
	ret



;rdi - ptr
;rsi - row
;rdx - column
;xmm0 - value
matrixSet:
	imul 	esi, dword [rdi + 4]
	add 	rsi, rdx
	movss 	[rdi + rsi*4 + 8], xmm0
	ret

;rdi - ptr
;xmm0 - k
;in rax ptr to new Matrix
matrixScale:
	sub 	rsp, 16
	mov 	[rsp], rdi
	
	mov 	rax, rdi
	mov 	rsi, 0
	mov 	rdi, 0 
	mov 	esi, [rax+4]
	mov 	edi, [rax]

	call 	matrixNew ; in rax new matrix
	mov 	rdi, [rsp]
	add 	rsp, 16 		

	shufps  xmm0, xmm0, 00000000b
	
	mov 	rsi, 0
	mov 	esi, dword [rdi]
	imul 	esi, dword [rdi + 4]
	add 	rdi, 8
	imul 	rsi, 4

	push 	rax
	add 	rax, 8 ; move ptr to start first line
.align:
	test 	rsi, 15
	jz 		.ok_align
	movss 	xmm1, [rdi]
	mulss  	xmm1, xmm0
	movss	[rax], xmm1
	sub 	rsi, 4
	add 	rdi, 4
	add 	rax, 4
	jmp 	.align
.ok_align:
	add  	rsi, rdi
.loop:
	cmp 	rdi, rsi
	jz 		.finish
	movups 	xmm1, [rdi]
	mulps 	xmm1, xmm0
	movups 	[rax], xmm1
	add 	rdi, 4*4
	add 	rax, 4*4
	jmp 	.loop
.finish
	pop 	rax
	ret

;in rdi first ptr
;in rsi second
;if error returns 0
;in rax ans
matrixAdd:
	mov 	eax, [rsi]
	cmp 	[rdi], eax
	mov 	rax, 0
	jnz 	.return
	
	mov 	eax, [rsi + 4]
	cmp 	[rdi + 4], eax
	mov 	rax, 0
	jnz 	.return

	sub 	rsp, 16
	mov 	[rsp], rdi
	mov 	[rsp + 8], rsi
	mov 	rsi, [rdi]
	mov 	rdi, rsi
	shr 	rdi, 32
	shl 	rsi, 32
	shr 	rsi, 32
	xchg    rsi, rdi
	call 	matrixNew ; in rax new matrix
	mov 	rdi, [rsp] ; rdi - ptr to first matrix
	mov 	rdx, [rsp + 8] ; rdx - ptr to second matrix
	add 	rdx, 8
	add 	rsp, 8
	mov 	[rsp], rax	
	add 	rax, 8
	mov 	esi, [rdi]
	imul 	esi, [rdi + 4]
	add 	rdi, 8
	imul 	rsi, 4
.align:
	test 	rsi, 15
	jz 		.ok_align
	movss 	xmm0, [rdi]
	movss   xmm1, [rdx]
	addps	xmm0, xmm1
	movss 	[rax], xmm0
	sub 	rsi, 4
	add 	rdi, 4
	add 	rdx, 4
	add 	rax, 4
	jmp 	.align
.ok_align:
	add  	rsi, rdi
.loop:
	cmp 	rdi, rsi
	jz 		.finish
	movups 	xmm0, [rdi]
	movups 	xmm1, [rdx]
	addps 	xmm0, xmm1
	movups 	[rax], xmm0
	add 	rdi, 4*4
	add 	rdx, 4*4
	add 	rax, 4*4
	jmp 	.loop
.finish	
	pop 	rax
.return:
	ret



; for (int i = 0; i < n1; ++i)
;  for (int j = 0; j < m1; ++j)
;   for (int k = 0; k < m2; ++k)
;    c[i][k] += a[i][k] * b[j][k]	
; 

matrixMul:
	
	mov 	rax, [rsi]
	cmp 	[rdi + 4], eax
	mov 	rax, 0
	jnz 	.return
	
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	sub 	rsp, 40
	mov 	[rsp], rdi
	mov 	[rsp + 8], rsi

	mov 	rax, rdi
	mov 	edi, [rax]
	mov 	rax, rsi
	mov 	esi, [rax + 4]
	call 	matrixNew ; in rax new matrix
	mov 	rdi, [rsp] ; rdi - ptr to first matrix
	mov 	rdx, [rsp + 8] ; rdx - ptr to second matrix
	add 	rsp, 32
	mov 	[rsp], rax	

	mov 	r8, 0

.loop_i:
	cmp 	r8d, [rdi]
	jz 		.finish_i
	mov 	r9, 0
	.loop_j:
		cmp 	r9d, [rdi + 4]
		jz 		.finish_j

		mov 	r10, r8
		imul 	r10d, [rdi + 4]
		add 	r10, 2
		shl 	r10, 2
		add 	r10, rdi
		
		mov 	r12, r8
		imul 	r12d, [rax + 4]
		add 	r12, 2
		shl 	r12, 2
		add 	r12, rax
		
		movss 	xmm0, [r10 + r9 * 4]
		shufps  xmm0, xmm0, 00000000b

		mov 	r11, r9
		imul 	r11d, [rdx + 4]
		add 	r11, 2
		shl 	r11, 2
		add 	r11, rdx

		mov 	rsi, 0
		mov 	esi, [rdx + 4]
		shl 	rsi, 2

		.align:
			test 	rsi, 15
			jz 		.ok_align
			movss   xmm1, [r11]
			mulss	xmm1, xmm0
			movss 	xmm2, [r12]
			addss 	xmm1, xmm2
			movss 	[r12], xmm1
			sub 	rsi, 4
			add 	r11, 4
			add 	r12, 4
			jmp 	.align
		.ok_align:
			add  	rsi, r11

		.final_loop:
			cmp 	rsi, r11
			jz 		.finish_final
			movups 	xmm1, [r11]
			mulps 	xmm1, xmm0
			movups 	xmm3, [r12]
			addps 	xmm1, xmm3
			movups  [r12], xmm1
			add 	r11, 4*4
			add 	r12, 4*4
			jmp 	.final_loop
		.finish_final:

		inc 	r9
		jmp		.loop_j
	.finish_j:
	inc 	r8
	jmp 	.loop_i
.finish_i:
	pop 	rax
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
.return
	ret

section .data
zero: 		dd 		0, 0, 0, 0




