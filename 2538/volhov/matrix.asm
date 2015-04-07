;;; Matrix is {rows, columns, ⌈rows⌉, ⌈columns⌉, data}, where:
;;; rows, columns:     4 + 4 bytes (two ints)
;;; ⌈rows⌉, ⌈columns⌉: 4 + 4 bytes (two ints)
;;; data:              ⌈rows⌉×⌈columns⌉×4 bytes (4 for float).
;;; (⌈a⌉ = min{x | x≥a && x%4==0}
global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixSet
global matrixGet
global matrixScale
global matrixAdd
global matrixMul

extern aligned_alloc
extern free

;;; Matrix matrixNew(unsigned int rows, unsigned int cols);
matrixNew:
        mov     r8, rdi
        mov     r9, rsi

        ;; complement rdi to 4 if needed
        mov     rax, rdi
        mov     rcx, 4
        xor     rdx, rdx
        div     rcx
        mov     rbx, 4
        sub     rbx, rdx
        add     rdi, rbx

        ;; complement rsi to 4 if needed
        mov     rax, rsi
        mov     rcx, 4
        xor     rdx, rdx
        div     rcx
        mov     rbx, 4
        sub     rbx, rdx
        add     rsi, rbx

        ;; store for metadata
        push    rsi
        push    rdi

        ;; compute size of matrix and call calloc
        mov     rax, rdi
        mul     rsi             ; get size of matrix
        mov     r10, 4
        mul     r10             ; each element is 4B float
        add     rax, 4          ; for 4 numbers of metadata
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
        cmp     rsi, r8d
        jg      .failure
        cmp     rdx, r9d
        jg      .failure

        fld1                    ;return 1 for lulz

        jmp     .return
        .failure
        mov     rax, [0]
        .return



;;; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
matrixSet:

;;; Matrix matrixScale(Matrix matrix, float k)
matrixScale:

;;; Matrix matrixAdd(Matrix a, Matrix b);
matrixAdd:

;;; Matrix matrixMul(Matrix a, Matrix b);
matrixMul:
