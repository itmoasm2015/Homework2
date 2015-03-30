global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet

extern aligned_alloc
extern free

section .text

; matrixNew(unsigned int, unsigned int)
; creates matrix, filled by zeros
matrixNew:
	enter 0, 0
	mov rax, rdi

	add rax, 3
	and rax, ~3

	mov r13, rdi
	mov rbx, rsi

	add rsi, 3
	and rsi, ~3


	mul rsi
	mov r12, rax
	sal rax, 2

	mov rdi, 16
	add rax, 16
	mov rsi, rax
	call aligned_alloc
	mov rdx, rax
	mov [rax], r13
	mov [rax + 8], rbx

	mov rcx, r12
	lea rdi, [rax + 16]
	xor rax, rax

	rep stosd
	mov rax, rdx

	leave
	ret

matrixDelete:
	call free
	ret

matrixGetRows:
	mov rax, [rdi]
	ret

matrixGetCols:
	mov rax, [rdi + 8]
	ret

matrixGet:
	enter 0, 0
	mov rcx, [rdi + 8]
	add rcx, 3
	and rcx, ~3

	mov rax, rsi
	mul rcx
	add rax, rdx
	movss xmm0, [rdi + 16 + rax * 4]
	leave
	ret

matrixSet:
	enter 0, 0
	mov rcx, [rdi + 8]
	add rcx, 3
	and rcx, ~3

	mov rax, rsi
	mul rcx
	add rax, rdx
	movss [rdi + 16 + rax * 4], xmm0
	leave
	ret
