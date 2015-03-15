extern calloc, free
	
global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul

;;; round up to the nearest multiple of 4
%macro upto4 1
	sub %1, 1
	and %1, ~3		; zero last two bits
	add %1, 4
%endmacro

matrixNew:	
	;; rdi=0:rows
	;; rsi=0:cols

	sub rsp, 8
	mov [rsp], edi
	mov [rsp+4], esi
	;; [rsp] = cols:rows

	;; TODO
	upto4 rsi		; rsi = ⟦cols⟧⁴
	mov rax, rdi		; rax = 0:rows
	mul rsi			; rax = rows*⟦cols⟧⁴
	mov rdi, rax		; rdi = rows*⟦cols⟧⁴
	mov rsi, 4		; rsi = 4

	;; rdi = rows*⟦cols⟧⁴
	;; rsi = 4
	call calloc
	;; rax = *values

	pop rdx
	;; rdx = cols:rows

	;; rax=*values
	;; rdx=cols:rows
	ret

matrixDelete:
	;; rdi=*values
	;; rsi=cols:rows
	jmp free

matrixGetRows:
	;; rdi=*values
	;; rsi=cols:rows
	mov eax, esi
	;; rax = 0:rows
	ret

matrixGetCols:
	;; rdi=*values
	;; rsi=cols:rows
	mov rax, rsi
	shr rax, 32
	;; rax = 0:cols
	ret

matrixGet:
	;; rdi=*values
	;; rsi=cols:rows
	;; rdx=0:row
	;; rcx=0:col
	shr rsi, 32		; rsi = cols
	upto4 rsi		; rsi = ⟦cols⟧⁴

	mov eax, edx		; rax = 0:row
	mul rsi			; rax = row*⟦cols⟧⁴
	add rcx, rax		; rcx = row*⟦cols⟧⁴ + col
	movss xmm0, [rdi+4*rcx]	; xmm0 = [values + 4*row*⟦cols⟧⁴ + 4*col]
	ret

matrixSet:
	;; rdi=*values
	;; rsi=cols:rows
	;; rdx=0:row
	;; rcx=0:col
	;; xmm0=value
	shr rsi, 32		; rsi = cols
	upto4 rsi		; rsi = ⟦cols⟧⁴

	mov eax, edx		; rax = 0:row
	mul rsi			; rax = row*⟦cols⟧⁴
	add rcx, rax		; rcx = row*⟦cols⟧⁴ + col
	movss [rdi+4*rcx], xmm0	; [values + 4*row*⟦cols⟧⁴ + 4*col] = xmm0
	ret
	
matrixScale:	
	;; rdi=*values
	;; rsi=cols:rows
	;; xmm0=0:0:0:k

	push rbx
	push r12
	push rsi

	mov r12, rdi		; r12 = *values

	mov eax, esi		; rax=0:rows

	shr rsi, 32		; rsi = 0:cols
	upto4 rsi		; rsi = ⟦cols⟧⁴
	
	mul rsi			; rax = rows*⟦cols⟧⁴
	mov rbx, rax		; rbx = rows*⟦cols⟧⁴

	;; allocate new matrix
	mov rdi, rax		; rdi = rows*⟦cols⟧⁴
	mov rsi, 4		; rsi = 4
	;; rdi=rows*⟦cols⟧⁴
	;; rsi=4
	call calloc
	;; rax=*new_values

	;; clone k
				; xmm0 = 0:0:0:k
	movsldup xmm0, xmm0	; xmm0 = 0:0:k:k
	unpcklps xmm0, xmm0	; xmm0 = k:k:k:k
	
.loop:
	sub rbx, 4
	jnge .end

	movups xmm1, [r12+4*rbx]
	mulps xmm1, xmm0
	movups [rax+4*rbx], xmm1
	jmp .loop
.end:
	pop rdx			; rdx=cols:rows

	pop r12
	pop rbx

	;; rax=*new_values
	;; rdx=cols:rows
	ret
	
matrixAdd:	
	;; rdi=*values1
	;; rsi=cols1:rows1
	;; rdx=*values2
	;; rcx=cols2:rows2

	cmp rsi, rcx
	je .dims_are_ok
.dims_are_bad:
	xor rax, rax
	xor rdx, rdx
	ret
	
.dims_are_ok:	
	push rbx
	push r12
	push r13

	push rsi		; [rsp] = cols:rows

	mov r12, rdi		; r12 = values1
	mov r13, rdx		; r13 = values2

	mov eax, esi		; rax=0:rows

	shr rsi, 32		; rsi = 0:cols
	upto4 rsi		; rsi = ⟦cols⟧⁴
	
	mul rsi			; rax = rows*⟦cols⟧⁴
	mov rbx, rax		; rbx = rows*⟦cols⟧⁴

	;; allocate new matrix
	mov rdi, rax		; rdi = rows*⟦cols⟧⁴
	mov rsi, 4		; rsi = 4
	;; rdi=rows*⟦cols⟧⁴
	;; rsi=4
	call calloc
	;; rax=*new_values
	
.loop:
	sub rbx, 4
	jnge .end

	movups xmm0, [r12+4*rbx]
	movups xmm1, [r13+4*rbx]
	addps xmm0, xmm1
	movups [rax+4*rbx], xmm0
	jmp .loop
.end:
	pop rdx			; rdx=cols:rows

	pop r13
	pop r12
	pop rbx

	;; rax=*new_values
	;; rdx=cols:rows
	ret
