section .text

extern aligned_alloc
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

%macro roundTo4 1
        dec %1
        mov rax, %1
        
        xor rdx, rdx
        push rcx
        mov qword rcx, 4
        div rcx
        pop rcx
        
        sub %1, rdx
        add %1, 4
%endmacro

%macro countSize 3
        push rax
        push rdx
        
        xor rdx, rdx
        mov rax, %2
        mul %3
        mov %1, rax
        
        pop rdx
        pop rax
%endmacro

%macro allocMatrix 2
        push rcx
        countSize rcx, %1, %2

        sal rcx, 2
        add rcx, 16

        push rdi
        push rsi
        
        mov rsi, rcx
        mov rdi, 16
        call aligned_alloc

        pop rsi
        pop rdi
        pop rcx
%endmacro

matrixNew:
        push rsi
        push rdi
;; Rounding sizes
        roundTo4 rsi
        roundTo4 rdi
;; Allocating memory
        allocMatrix rdi, rsi
        countSize rcx, rdi, rsi

        pop rdi
        pop rsi

;; Check if allocation successfull
        test rax, rax
        jz .exit
        
;; Store sizes in struct
        mov [rax], rdi
        mov [rax + 8], rsi

        push rax
;; Fill matrix with zeroes
        lea rdi, [rax + 16]
        xor rax, rax
        cld
        rep stosd
        pop rax

.exit:
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
;; Get rounded amount of columns
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8
;; Save column number
        mov r8, rdx

;; Get index in linear representation
        xor rdx, rdx
        mul rsi
        add rax, r8

        movss xmm0, [rdi + rax * 4]
        ret
        
matrixSet:
;; Get rounded amount of columns
        mov r8, [rdi + 8]
        roundTo4 r8
        mov rax, r8
;; Save column number
        mov r8, rdx
;; Get index in linear representation
        xor rdx, rdx
        mul rsi
        add rax, r8
;; Set value
        movss [rdi + rax * 4], xmm0
        ret
        
matrixScale:
        ret
        
matrixAdd:
        ret
        
matrixMul:
        ret

