;;; Matrix is {rows, columns, ⌈rows⌉, ⌈columns⌉, 16b_offset, data}, where:
;;; rows, columns:     4 + 4 bytes (two ints)
;;; ⌈rows⌉, ⌈columns⌉: 4 + 4 bytes (two ints)
;;; data:              ⌈rows⌉×⌈columns⌉×4 bytes (4 for float).
;;; (⌈a⌉ = min{x | x≥a && x%8==0}

;;; I use sse2/avx here
global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixSet
global matrixGet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul

extern aligned_alloc
extern free

%define complement_offset 8     ;8 floats fit into ymm* register
%define metadata_offset 32      ;4 ints + 16b of nothing (for aligning)

;;; Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
        mov     r8, rdi
        mov     r9, rsi

        ;; complement rdi if needed
        mov     rax, rdi
        mov     rcx, complement_offset
        xor     rdx, rdx
        div     rcx
        cmp     rdx, 0
        je      .skip1
        mov     rbx, complement_offset
        sub     rbx, rdx
        add     rdi, rbx
        .skip1

        ;; complement rsi if needed
        mov     rax, rsi
        mov     rcx, complement_offset
        xor     rdx, rdx
        div     rcx
        cmp     rdx, 0
        je      .skip2
        mov     rbx, complement_offset
        sub     rbx, rdx
        add     rsi, rbx
        .skip2

        ;; store for metadata
        push    rsi
        push    rdi

        ;; compute size of matrix and call calloc
        mov     rax, rdi
        mul     rsi             ; get size of matrix
        mov     r10, 4
        mul     r10             ; each element is 4B float
        add     rax, metadata_offset ; for 4 numbers of metadata
        mov     rsi, rax
        push    rdi
        push    rsi
        push    r8
        push    r9
        mov     rdi, 32         ; align of 32 bits is required for movaps
        call    aligned_alloc
        pop     r9
        pop     r8
        pop     rsi
        pop     rdi

        test    rax, rax
        jz      .gotnull

        ;; fill data with zeros
        mov     rcx, rsi
        mov     rdi, rax
        mov     rax, 0
        rep     stosb
        mov     rax, rdi        ; mov rdi+length to rax
        sub     rax, rsi        ; it was spoiled by rep stosd, so sub length

        ;; add metadata
        mov     dword [rax], r8d
        mov     dword [rax+4], r9d
        pop     rdi
        pop     rsi
        mov     dword [rax+8], edi
        mov     dword [rax+12], esi
        jmp     .return

        .gotnull
        pop     rdi
        pop     rsi
        .return
        ret

;;; void matrixDelete(Matrix matrix);
matrixDelete:
        call    free
        ret

matrixGetRows:
        xor     rax, rax
        mov     eax, dword [rdi]
        ret

matrixGetCols:
        xor     rax, rax
        mov     eax, dword [rdi+4]
        ret

;;; float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
matrixGet:
        mov     r8d, dword [rdi]
        mov     r9d, dword [rdi+4]
        cmp     esi, r8d
        jge     .failure
        cmp     edx, r9d
        jge     .failure


        imul    rsi, 4          ; 4 bytes for each float
        imul    rsi, [rdi+12]   ; × ⌈rows⌉

        imul    rdx, 4          ; 4 bytes for each row element
        add     rdi, rsi        ; sum it all
        add     rdi, rdx
        add     rdi, metadata_offset ; skip metadata
        movss   xmm0, [rdi]

        jmp     .return
        .failure
        mov     rax, [0]
        .return
        ret


;;; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:
        mov     r8d, dword [rdi]
        mov     r9d, dword [rdi+4]
        cmp     esi, r8d
        jge     .failure
        cmp     edx, r9d
        jge     .failure


        imul    rsi, 4          ; 4 bytes for each float
        imul    rsi, [rdi+12]   ; × ⌈columns⌉

        imul    rdx, 4          ; 4 bytes for each row element
        add     rdi, rsi        ; sum it all
        add     rdi, rdx
        add     rdi, metadata_offset ; skip metadata
        movss   dword [rdi], xmm0

        jmp     .return
        .failure
        mov     rax, [0]
        .return

        ret

;;; Matrix matrixScale(Matrix matrix, float k)
matrixScale:
        mov     rsi, rdi
        xor     r8, r8
        xor     r9, r9
        mov     r8d, dword[rdi]    ; rows
        mov     r9d, dword[rdi+12] ; ⌈columns⌉
        add     rdi, metadata_offset

        ;; move rows×⌈columns⌉×4 into rax
        mov     rax, r8         ; r8
        mul     r9              ; × r9
        mov     r10, 4
        mul     r10             ; x 4b for float

        ;; add end of matrix to rsi (that is rdi for now)
        add     rsi, metadata_offset
        add     rsi, rax

        ;; move k to 8 cells in ymm1
        sub     rsp, 4
        vmovss  dword[rsp], xmm0
        vbroadcastss ymm1, dword[rsp]
        add     rsp, 4

        ;; for each pack of 8 cells (8 * 32bit = 256bit)
        ;; scale it with ymm1 containing k
        .loop
        vmulps  ymm0, ymm1, [rdi]
        vmovaps [rdi], ymm0
        add     rdi, 32         ; 8b * 4b for float
        cmp     rdi, rsi
        jl      .loop
        ret

;;; Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:
        push    r12

        mov     r10, rdi        ; r10 - matrix a
        mov     r11, rsi        ; r11 - matrix b

        ;; check if a.rows == b.rows
        mov     r8d, dword[r10]
        mov     r9d, dword[r11]
        cmp     r8d, r9d
        jne     .fail

        ;; check if a.cols == b.cols
        mov     r8d, dword[r10+4]
        mov     r9d, dword[r11+4]
        cmp     r8d, r9d
        jne     .fail

        ;; save a, b
        xor     rdi, rdi
        xor     rsi, rsi
        mov     edi, dword[r10]
        mov     esi, dword[r10+4]

        ;; create new matrix of proper size
        push    r10
        push    r11
        call    matrixNew
        pop     r11
        pop     r10

        ;; save new matrix into r12
        mov     r12, rax

        ;; calculate number of elements in matrix
        xor     rax, rax
        mov     eax, dword[r12]   ; move rows
        mul     dword[r12+12]     ; *⌈cols⌉
        mov     ecx, eax
        mov     rax, r12

        ;; skip metadata
        add     r10, metadata_offset
        add     r11, metadata_offset
        add     r12, metadata_offset

        ;; iterate over 8*32b blocks, sum it, put into r12
        .loop
        vmovups ymm1, [r10]
        vmovups ymm2, [r11]
        vaddps  ymm0, ymm1, ymm2
        vmovups [r12], ymm0
        add     r10, 32        ; 8 * 4b for vector of floats
        add     r11, 32        ; -//-
        add     r12, 32        ; -//-
        sub     ecx, complement_offset
        cmp     ecx, 0
        jne     .loop

        jmp     .return
        .fail
        xor     rax, rax
        .return
        pop     r12
        ret

;;; Matrix matrixTranspose(Matrix);
;;; transposes matrix (returns new one)
matrixTranspose:
        ;; copy input matrix to r10
        mov     r10, rdi

        ;; create empty transposed matrix
        mov     esi, dword[rdi]
        mov     edi, dword[rdi+4]
        push    r10
        call    matrixNew
        pop     r10

        ;; save it to r11
        mov     r11, rax

        ;; get ⌈rows⌉, ⌈cols⌉ of new matrix to r8, r9
        xor     r8, r8
        xor     r9, r9
        mov     r8d, dword[r11+8]
        mov     r9d, dword[r11+12]

        ;; mov r10+⌈rows⌉×⌈cols⌉ (end destination of r10) into rdi
        xor     rax, rax
        mov     rax, r8
        mul     r9
        mov     rdi, rax
        add     rdi, r10

        ;; skip metadata
        add     r10, metadata_offset
        add     r11, metadata_offset

        ;; rcx holds new row counter, rbx -- new column
        push    rbx
        xor     rbx, rbx
        xor     rcx, rcx

        ;; by-element copy (I don't know how to use sse/avx here effectively)
        .loop                   ; iterating over rows inside, over columns outside
        mov     esi, dword[r10] ; move float to esi
        add     r10, 4          ; skip this float
        mov     rax, rcx        ; rax -- number of rows
        mul     r9              ; × width_of_row in cells
        shl     rax, 2          ; × 4b
        lea     rax, [rax+4*rbx] ; + column_offset×4
        mov     dword[r11+rax], esi ; move that floats to current new location
        inc     rcx             ; continue to next row
        cmp     rcx, r8
        jl      .loop           ; go to next row if not end

        xor     rcx, rcx
        inc     ebx             ; move to next column
        cmp     rbx, r9
        jl      .loop           ; if not end, loop

        pop     rbx
        mov     rax, r11
        sub     rax, metadata_offset
        ret

;;; Matrix matrixDirectProduct(
matrixDirectProduct:

;;; Matrix matrixMul(Matrix a, Matrix b);
matrixMul:
        push    r12
        push    r13

        ;; save parameter matrices
        mov     r10, rdi
        mov     r11, rsi

        ;; check if a.cols == b.rows
        ;; A should be n×m, B should be m×k
        mov     r8d, dword[r10+4]
        mov     r9d, dword[r11]
        cmp     r8d, r9d
        jne     .fail

        ;; swap r11 with it's transposition
        ;; r11 is k×m now
        mov     rdi, r11
        push    r8
        push    r9
        push    r10
        push    r11
        call    matrixTranspose
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        mov     r11, rax

        ;; create new matrix of size n×k, move it to rax
        mov     edi, dword[r10]
        mov     esi, dword[r11]
        push    r10
        push    r11
        call    matrixNew
        pop     r11
        pop     r10
        mov     r12, rax

        ;; save r12 (result)
        push    r12

        xor     r8, r8
        xor     r9, r9
        mov     r8d, dword[r10+8]  ; r8 is ⌈n⌉
        mov     r9d, dword[r10+12] ; r9 is ⌈m⌉

        ;; r13 holds size of matrix B (⌈k⌉×⌈m⌉)
        xor     eax, eax
        mov     eax, dword[r11+8]
        mul     dword[r11+12]
        mov     r13, rax

        ;; rcx -- counter for ⌈m⌉ elements
        ;; rbx -- counter for ⌈k⌉×⌈m⌉ elements
        ;; rdx -- counter for ⌈n⌉ elements
        xor     rcx, rcx
        xor     rbx, rbx
        xor     rdx, rdx

        ;; add metadata
        add     r10, metadata_offset
        add     r11, metadata_offset
        add     r12, metadata_offset

        sub     rsp, 32         ; reserve 32b for ymm saving
        .loop
        vmovups ymm1, [r10]     ; take 8 floats from the first matrix
        vmovups ymm2, [r11]     ; take 8 floats from the second matrix
        vdpps   ymm0, ymm1, ymm2, 255 ; calculate the dot product of ymm1 and ymm2,
                                ; that is now in ymm0[0:31]+ymm0[128:159]
        vmovups [rsp], ymm0 ; move ymm0 to the stack reserved place
        fld     dword[r12]      ; extract current value from new matrix
        fld     dword[rsp]      ; extract ymm0[0:31]
        fld     dword[rsp+16]   ; extract ymm0[128:159]
        faddp                   ; sum them all
        faddp
        fstp    dword[r12]      ; save to the proper location
        add     r10, 32         ; move to next pack
        add     r11, 32         ; move to next pack
        add     rbx, 8
        add     rcx, 8

        cmp     rcx, r9
        jl      .loop           ; that's the inner loop for 1 row of A (and B)

        sub     r10, r9         ; restore init value of r10 (row start)
        sub     r10, r9         ; ×4 for bytes
        sub     r10, r9
        sub     r10, r9

        add     r12, 4          ; go fill next cell

        xor     rcx, rcx         ; clear rcx counter
        cmp     rbx, r13         ; check if all matrix B was proceeded
        jl      .loop            ; middle loop for iterating over B rows

        lea     r10, [r10+4*r9]

        sub     r11, r13        ; lea r11, [r11-4*r13] doesn't work :(
        sub     r11, r13
        sub     r11, r13
        sub     r11, r13

        xor     rbx, rbx
        inc     rdx
        cmp     rdx, r8         ; check if we just passed through all A rows
        jl      .loop           ; outer loop for iterating over A rows

        ;; restore pointer to start of result matrix
        add     rsp, 32
        pop     rax
        jmp     .return
        .fail
        xor     rax, rax
        .return
        pop     r13
        pop     r12
        ret
