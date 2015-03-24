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

; Матрицу храним так: 4 бита на число строк, 4 бита на число столбцов, затем по 4 бита на каждую ячейку.
; Далее n -- число строк, m -- число столбцов.
; Ячейки будут записаны построчно, ячейка (x, y) будет записана на позиции x * m + y


; Matrix matrixNew(int n, int m);
; Создает матрицу размера n * m и заполняет нулями
matrixNew:
    push rbx ; значение rbx не должно поменяться
    
    ; rdi -- число строк (n)
    ; rsi -- число столбцов (m)
    
    mov rbx, rdi 
    imul rbx, rsi ; посчитали размер матрицы (n * m)
    
    ; сохраняем rdi и rsi 
    push rdi
    push rsi
    
    ; подготавливаем аргумент для вызова malloc
    mov rdi, rbx
    add rdi, 2
    shl rdi, 2 ; rdi = (n * m + 2) * 4
    
    push rdi
    call malloc
    pop rdi
    
    ; вернули значения rdi и rsi
    pop rsi
    pop rdi
    
    ; в первые ячейки памяти запишем размеры матрицы
    mov [rax], edi
    mov [rax + 4], esi
    
    ; заполним матрицу нулями
    xor rcx, rcx ; rcx -> 0
    .loop:
        mov dword [rax + rcx * 4 + 8], 0
        inc rcx
        cmp rcx, rbx
        jne .loop

    pop rbx ; вернули старое значение rbx
    ret


; void matrixDelete(Matrix a);
; Освобождает память, которую занимала матрица
matrixDelete:
    push rdi
    call free
    pop rdi
    ret


; void matrixSet(Matrix a, int x, int y, float val);
; Сделать значение в ячейке (x, y) равным val
matrixSet:
    ; посчитаем в rax номер нужной ячейки
    xor rax, rax        ; rax = 0
    mov eax, esi        ; rax = x
    imul eax, [rdi + 4] ; rax = x * m
    add eax, edx        ; rax = x * m + y

    movss [rdi + rax * 4 + 8], xmm0
    ret


; float matrixGet(Matrix a, int x, int y);
; Возвращает значение ячейки (x, y)
matrixGet:
    ; также, как и в matrixSet
    xor rax, rax
    mov eax, esi
    imul eax, [rdi + 4]
    add eax, edx

    movss xmm0, [rdi + rax * 4 + 8]
    ret


; int matrixGetRows(Matrix a);
; Возвращает число строк матрицы
matrixGetRows:
    mov eax, [rdi]
    ret


; int matrixGetCols(Matrix a);
; Возвращает число столбцов матрицы
matrixGetCols:
    mov eax, [rdi + 4]
    ret


; Matrix matrixAdd(Matrix a, Matrix b);
; Складывает две матрицы и в ответ выдает новую матрицу (значения в старых матрицах не изменяются)
matrixAdd:
    ; сперва проверим, одинаковые ли размеры у матриц
    ; если нет -- вернем 0 (NULL)
    mov rax, [rdi]
    mov rcx, [rsi]
    cmp rax, rcx
    jne .fail

    ; запишем в rcx <-- n, rdx <-- m
    xor rcx, rcx
    mov ecx, [rdi]
    xor rdx, rdx
    mov edx, [rdi + 4]

    ; подготовим аргументы для вызова matrixNew
    push rdi
    push rsi
    
    mov rdi, rcx
    mov rsi, rdx

    call matrixNew

    mov rcx, rdi
    mov rdx, rsi
    
    pop rdi
    pop rsi

    ; сейчас в rax -- новая матрица, старые в rdi и rsi

    ; положим в r8 число элементов матрицы 
    mov r8, rcx
    imul r8, rdx

    ; сперва, пройдемся блоками по 4 ячейки, делая модные операции
    ; затем уже во втором цикле добьем остаток
    xor rcx, rcx
    .loopBegin:
        add rcx, 4
        cmp rcx, r8
        jg .loopEnd
        ; сейчас сложим ячейки rcx - 4, rcx - 3, rcx - 2, rcx - 1
        movups xmm0, [rdi + rcx * 4 - 8]
        movups xmm1, [rsi + rcx * 4 - 8]
        addps xmm0, xmm1
        movups [rax + rcx * 4 - 8], xmm0
        jmp .loopBegin
    .loopEnd:

    sub rcx, 4
    
    .loop2Begin:
        cmp rcx, r8
        je .loop2End
        ; здесь же сложим ячейки с номером rcx
        movss xmm0, [rdi + rcx * 4 + 8]
        addss xmm0, [rsi + rcx * 4 + 8]
        movss [rax + rcx * 4 + 8], xmm0
        inc rcx
        jmp .loop2Begin
    .loop2End:

    jmp .return
.fail:
    mov rax, 0
.return:
    ret


; Matrix matrixScale(Matrix a, float val);
; Умножает все элементы матрицы на скаляр, в ответ выдает новую матрицу (значения старой не изменяются)
matrixScale:
    ; код будет очень похож на matrixAdd
    ; опять, запишем rcx := n, rdx := m
    xor rcx, rcx
    mov ecx, [rdi]
    xor rdx, rdx
    mov edx, [rdi + 4]

    ; снова подготовим аргументы и вызовем matrixNew
    push rdi
    push rsi
    
    mov rdi, rcx
    mov rsi, rdx

    call matrixNew

    mov rcx, rdi
    mov rdx, rsi
    
    pop rsi
    pop rdi

    ; и снова, новая матрица в rax

    mov r8, rcx
    imul r8, rdx

    xor rcx, rcx
    
    ; а вот тут немного магии
    ; xmm0 -- val, а в xmm1 окажется (val,val,val,val) (для векторных операций)
    movss xmm1, xmm0
    unpcklps xmm1, xmm1
    unpcklps xmm1, xmm1
    
    ; такие же циклы, как и в matrixAdd
    .loopBegin:
        add rcx, 4
        cmp rcx, r8
        jg .loopEnd
        movups xmm2, [rdi + rcx * 4 - 8]
        mulps xmm2, xmm1
        movups [rax + rcx * 4 - 8], xmm2
        jmp .loopBegin
    .loopEnd:

    sub rcx, 4
    
    .loop2Begin:
        cmp rcx, r8
        jnl .loop2End
        movss xmm2, [rdi + rcx * 4 + 8]
        mulss xmm2, xmm0
        movss [rax + rcx * 4 + 8], xmm2
        inc rcx
        jmp .loop2Begin
    .loop2End:

    ret


; Matrix matrixMul(Matrix a, Matrix b);
; Перемножает две матрицы и возвращает результат в виде новой матрицы (старые значения не затираются)
;
; Самая сложная функция!
; Сперва, для ускорения (для лучшей работы кеш-а + для модных векторных операций), транспонируем вторую матрицу
; Затем уже, перемножим пары строк
; Тесты показали, что эта реализация работает в 3 раза быстрее реализации на c++
; (реализация на c++ использовала транспонированную матрицу, и была скомпилирована под -O2)
;
; В дальнейших комментариях будет предполагаться, что перемножаются матрицы (n x m) * (m x k)
matrixMul:
    ; если размеры матриц не позволяют их перемножить -- вернем 0 (NULL)
    mov eax, [rdi + 4]
    mov ecx, [rsi]
    cmp eax, ecx
    jne .fail
    
    ; засейвим те регистры, которые в будущем будем использовать
    ; (согласно конвенции, значения в этих регистрах должны остаться неизменны)
    push rbp
    push rbx
    push r12
    push r13
    
    ; отныне первая матрица в r12, вторая в r13
    mov r12, rdi
    mov r13, rsi
    
    ; подготовим аргументы для вызова matrixNew
    ; (нам ведь нужно где-то взять транспонированную матрицу, а менять значения в старой нельзя)
    xor rdi, rdi
    xor rsi, rsi
    
    mov esi, [r13]     ; rsi := m
    mov edi, [r13 + 4] ; rdi := k
    
    call matrixNew
    
    ; успех! положим новую матрицу в r11 (этот регистр далее меняться не будет)
    ; новая матрица имеет размеры (k x m) (или (rdi x rsi))
    mov r11, rax
    
    ; двумя форами без каких либо хитростей перекопируем значения из r13 (второй матрицы)
    xor rcx, rcx
    .forX:
        xor rdx, rdx
        .forY:
            
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
            jne .forY
        inc rcx
        cmp rcx, rdi
        jne .forX

    ; готово! теперь в r11 -- полноценная транспонированная матрица r13
    
    xor rdi, rdi
    mov edi, [r12]     ; rdi := n
    xor rsi, rsi
    mov esi, [r13 + 4] ; rsi := k
    
    
    ; выделим место под матрицу для ответа, ее адрес, как всегда, будет в rax
    push r11 ; (этот пуш нужен лишь для сохранения регистра r11, его может испортить malloc)
    call matrixNew
    pop r11
    
    xor r9, r9
    mov r9d, [r12 + 4] ; r9 := m
    
    ; for rcx = 0 --> n - 1
    xor rcx, rcx
    .for2X:
        ; for rdx = 0 --> k - 1
        xor rdx, rdx
        .for2Y:
            xorps xmm1, xmm1
            xorps xmm2, xmm2
            
            ; здесь будут такие же 2 цикла (в начале по блокам длины 4, затем остаток)
            ; код немного больше, чтобы соптимизировать число операций внутри циклов

            ; rbx и rbp будут ссылаться нужные позиции в rcx-ой и rdx-ой строчках в r12 и r11, соответственно
            
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
            
            ; здесь все произведения сложим в вектор xmm2 (он будет хранить 4 значения)
            .loopBegin:
                add r8, 4
                add rbx, 16
                add rbp, 16
                cmp r8, r9
                jg .loopEnd

                movups xmm0, [rbx]
                movups xmm3, [rbp]
                mulps xmm0, xmm3
                addps xmm2, xmm0

                jmp .loopBegin
            .loopEnd:

            sub r8, 4
            
            ; здесь же, все сложим в регистр xmm1 (только 1 значение)
            .loop2Begin:
                cmp r8, r9
                je .loop2End
                
                movss xmm0, [rbx]
                mulss xmm0, [rbp]
                addss xmm1, xmm0
                
                inc r8
                add rbx, 4
                add rbp, 4
                jmp .loop2Begin
            .loop2End:
            
            ; снова немного магии (сложим все части в xmm2 и добавим в xmm1)
            haddps xmm2, xmm2
            haddps xmm2, xmm2
            addss xmm1, xmm2
            
            ; конец! осталось лишь вычислить номер нужной ячейки (это rcx * k + rdx) и положить туда xmm1
            mov r10, rcx
            imul r10, rsi
            add r10, rdx
            
            movss [rax + r10 * 4 + 8], xmm1
                
            inc rdx
            cmp rdx, rsi
            jne .for2Y
            
        inc rcx
        cmp rcx, rdi
        jne .for2X

    ; матрицы перемножили!

    ; осталось удалить транспонированную матрицу (не потеряв значение rax)
    push rax
    
    mov rdi, r11
    push rdi
    call free
    pop rdi
    
    pop rax
    
    ; и вернуть на свои места те регистры, что использовали
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

; the end

