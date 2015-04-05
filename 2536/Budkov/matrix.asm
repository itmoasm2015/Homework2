section .text 
	
	extern malloc
	extern free
	
	global matrixNew
    global matrixDelete
    global matrixSet
    global matrixGet
    global matrixGetRows
    global matrixGetCols
    global matrixAdd
    global matrixScale
    global matrixMul
	
; Matrix in memory: [height,width,cell[0][0],cell[0][1],...]
	
; in: 
;	int n - height
;	int m - width
; out:
;	new Matrix(h*w)
; Create new matrix and put 0 to each cell(height=n,width=m)	
matrixNew:
    push rbx 			
    mov rbx, rdi 		; rdi-matrix height, rsi-matrix width
    imul rbx, rsi 		; matrix size
    push rdi 			
    push rsi 			
    mov rdi, rbx
    add rdi, 2
    shl rdi, 2 			; rdi=4(hw+2)
    push rdi
    call malloc
    pop rdi
    pop rsi				
    pop rdi				
    mov [rax], edi
    mov [rax + 4], esi
						; write 0 to each cell
    xor rcx, rcx 
    .loop:
        mov dword [rax + rcx * 4 + 8], 0
        inc rcx
        cmp rcx, rbx
        jne .loop
    pop rbx 			; return rbx
    ret
    
; in:
;	Matrix a - Matrix to set val
;	int x - position(0..w)
;	int y - position(0..h)
;	float val - value to set in [x][y]
; out:
; 	Set cell of Matrix (a) with position [x][y] = val
matrixSet:
						; calculate rax in [x][y]
    xor rax, rax        ; 0
    mov eax, esi        ; x
    imul eax, [rdi + 4] ; xw
    add eax, edx        ; xw+y
    movss [rdi + rax * 4 + 8], xmm0
    ret
    
; in:
;	Matrix a - Matrix to get value
;	int x - position(0..w)
;	int y - position(0..h)
; out:
;	Get value of cell of Matrix (a) in position [x][y]
matrixGet:
						; calculate rax in [x][y]
    xor rax, rax		; 0
    mov eax, esi		; x
    imul eax, [rdi + 4]	; xw
    add eax, edx		; xw+y
    movss xmm0, [rdi + rax * 4 + 8]
    ret
    
; in:
;	Matrix a - Matrix to delete
; out:
;	Clean memory given to Matrix (a)
matrixDelete:
    push rdi
    call free
    pop rdi
    ret

; in:
;	Matrix a - Matrix to get collumns
; out:
;	Matrix width
matrixGetCols:
    mov eax, [rdi + 4]
    ret

; in:
;	Matrix a - Matrix to get rows
; out:
;	Matrix height
matrixGetRows:
    mov eax, [rdi]
    ret
    
; in:
;	Matrix a - first Matrix
;	Matrix b - second Matrix
; out:
;	NEW Matrix = sum of (a) and (b)
matrixAdd:
    mov rax, [rdi]		; check	Matrix's sizes
    mov rcx, [rsi]
    cmp rax, rcx		
    jne .fail			; if(size(a)!=size(b))
    xor rcx, rcx		
    mov ecx, [rdi]		; rcx=h
    xor rdx, rdx
    mov edx, [rdi + 4]	; rdx=w
    push rdi
    push rsi
    mov rdi, rcx
    mov rsi, rdx
    call matrixNew		; create new Matrix
    mov rcx, rdi
    mov rdx, rsi
    pop rdi
    pop rsi
    mov r8, rcx
    imul r8, rdx		; r8=count of elements
    xor rcx, rcx
    .loop:
        add rcx, 4
        cmp rcx, r8
        jg .end
        movups xmm0, [rdi + rcx * 4 - 8]
        movups xmm1, [rsi + rcx * 4 - 8]
        addps xmm0, xmm1
        movups [rax + rcx * 4 - 8], xmm0
        jmp .loop
    .end:
    sub rcx, 4
    .looop:
        cmp rcx, r8
        je .eend
        movss xmm0, [rdi + rcx * 4 + 8]
        addss xmm0, [rsi + rcx * 4 + 8]
        movss [rax + rcx * 4 + 8], xmm0
        inc rcx
        jmp .looop
    .eend:
    jmp .return
.fail:
    mov rax, 0
.return:
    ret
    
; in:
;	Matrix a - Matrix to multiply
;	float val - scalar to mltiply on
; out:
;	NEW Matrix = each cell of (a) multiplied on (val)
matrixScale:
    xor rcx, rcx
    mov ecx, [rdi]		; rcx=h
    xor rdx, rdx
    mov edx, [rdi + 4]	; rdx=w
    push rdi
    push rsi
    mov rdi, rcx
    mov rsi, rdx
    call matrixNew		; create new Matrix
    mov rcx, rdi
    mov rdx, rsi
    pop rsi
    pop rdi
    mov r8, rcx
    imul r8, rdx		; r8-count of elements
    xor rcx, rcx
    movss xmm1, xmm0	; xmm0-val
    unpcklps xmm1, xmm1
    unpcklps xmm1, xmm1	; xmm1-(val,val,val,val)
    .loop:
        add rcx, 4
        cmp rcx, r8
        jg .end
        movups xmm2, [rdi + rcx * 4 - 8]
        mulps xmm2, xmm1
        movups [rax + rcx * 4 - 8], xmm2
        jmp .loop
    .end:
    sub rcx, 4
    .looop:
        cmp rcx, r8
        jnl .eend
        movss xmm2, [rdi + rcx * 4 + 8]
        mulss xmm2, xmm0
        movss [rax + rcx * 4 + 8], xmm2
        inc rcx
        jmp .looop
    .eend:
    ret
    
; in:
;	Matrix a - first Matrix
;	Matrix b - second Matrix
; out:
;	NEW Matrix = (a) multiplied on (b)
matrixMul:
    mov eax, [rdi + 4]	; check	Matrix's sizes
    mov ecx, [rsi]
    cmp eax, ecx
    jne .fail			; if can't multiply
    push rbp
    push rbx
    push r12
    push r13
    mov r12, rdi		; write Matrix (a) to r12
    mov r13, rsi		; write Matrix (b) to r13
    xor rdi, rdi
    xor rsi, rsi
    mov esi, [r13]      ; rsi=w
    mov edi, [r13 + 4]  ; rdi=w2
					    ; (height*width)*(width*width2)
    call matrixNew		; create new Matrix
    mov r11, rax		; r11=new Matrix(width*width2)   
    xor rcx, rcx		
    .horizontal:		; start: transpose Matrix (b) and write to r11
        xor rdx, rdx
        .vertical:
            mov rbx, rcx
            imul rbx, rsi
            add rbx, rdx
            mov rbp, rdx
            imul rbp, rdi
            add rbp, rcx
            mov r10d, [r13 + rbp * 4 + 8]
            mov [r11 + rbx * 4 + 8], r10d
            inc rdx
            cmp rdx, rsi
            jne .vertical
        inc rcx
        cmp rcx, rdi
        jne .horizontal	; end: r11=transposed(Matrix (b))
    xor rdi, rdi
    mov edi, [r12]      ; rdi=h
    xor rsi, rsi
    mov esi, [r13 + 4]  ; rsi=w2
    push r11
    call matrixNew		; create result Matrix
    pop r11
    xor r9, r9
    mov r9d, [r12 + 4]	; r9=w
    xor rcx, rcx		; strat:multipling
    .rcxInc:			; 0..h-1
        xor rdx, rdx
        .rdxInc:		; 0..w2
            xorps xmm1, xmm1
            xorps xmm2, xmm2
            mov rbx, rcx
            imul rbx, r9
            shl rbx, 2
            add rbx, r12
            sub rbx, 8
            mov rbp, rdx
            imul rbp, r9
            shl rbp, 2
            add rbp, r11
            sub rbp, 8
            xor r8, r8
            .loop:		; start
                add r8, 4
                add rbx, 16
                add rbp, 16
                cmp r8, r9
                jg .end
                movups xmm0, [rbx]
                movups xmm3, [rbp]
                mulps xmm0, xmm3
                addps xmm2, xmm0
                jmp .loop
            .end:		; xmm2=vector of multiplies
            sub r8, 4
            .looop:
                cmp r8, r9
                je .eend
                movss xmm0, [rbx]
                mulss xmm0, [rbp]
                addss xmm1, xmm0
                inc r8
                add rbx, 4
                add rbp, 4
                jmp .looop
            .eend:
            haddps xmm2, xmm2	; add part to part
            haddps xmm2, xmm2	; again
            addss xmm1, xmm2	; add prev sum to xmm1
            mov r10, rcx
            imul r10, rsi
            add r10, rdx
            movss [rax + r10 * 4 + 8], xmm1	; write xmm1 to cell
            inc rdx
            cmp rdx, rsi
            jne .rdxInc
        inc rcx
        cmp rcx, rdi
        jne .rcxInc		; end:multipling
    push rax
    mov rdi, r11
    push rdi
    call free			; delete transposed Matrix
    pop rdi
    pop rax
    mov rdi, r12
    mov rsi, r13
    pop r13
    pop r12
    pop rbx
    pop rbp
    jmp .return
.fail
    mov rax, 0
.return
    ret
