extern malloc
extern free

global matrixNew ;Matrix matrixNew(unsigned int rows, unsigned in cols);
global matrixDelete;void matrixDelete(Matrix matrix);
global matrixGetRows;unsigned int matrixGetRows(Matrix matrix);
global matrixGetCols;unsigned int matrixGetCols(Matrix matrix);
global matrixGet;float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
global matrixSet;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
global matrixScale;Matrix matrixScale(Matrix matrix, float k);
global matrixAdd;Matrix matrixAdd(Matrix a, Matrix b);
global matrixMul;Matrix matrixMul(Matrix a, Matrix b);
global matrixTranspose;Matrix matrixTranspose(Matrix a);
;Для матрицы будем хранить 4 байта на число строк, столбцов и каждую ячейку
;Матрица будет записана конкатенацией чисел n, m и n строк по m ячеек
;Здесь и далее n - число строк, m - число столбцов

;Создаем матрицу (n x m) и инициализируем ее нулями
;rdi - n
;rsi - m
matrixNew:
    push    rbx
    ;В rbx засунем количество ячеек матрицы
    mov     rbx, rdi
    imul    rbx, rsi
    ;Готовимся к malloc
    push    rdi
    push    rsi
    ;В rdi засунем количество памяти для выделения
    mov     rdi, rbx ;Количество ячеек
    add     rdi, 2 ; плюс два числа на хранение размеров
    shl     rdi, 2 ; на все эти числа по 4 байта (2 ^ 2)
    push    rdi
    call    malloc
    pop     rdi
    pop     rsi
    pop     rdi
    ;Теперь, когда память выделена, нужно записать значения
    mov     dword[rax], edi
    mov     dword[rax + 4], esi
    push    rcx ;Использую как счетчик для цикла
    mov     rcx, 0
    .loop:
        mov     dword[rax + rcx * 4 + 8], 0; ячейка с номером rcx
        inc     rcx
        cmp     rcx, rbx
        jne     .loop
    pop     rcx
    pop     rbx
    ret

;Начало матрицы в rdi
;Используем free() для матрицы
matrixDelete:
    push    rdi ;Можно не делать, но мне так спокойней:)
    call    free
    pop     rdi
    ret

;Начало матрицы в rdi
;Вернем количество строк, которое хранится в 0..7 байтах матрицы
matrixGetRows:
    mov     rax, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     eax, dword[rdi]
    ret

;Начало матрицы в rdi
;Вернем количество строк, которое хранится в 8..15 байтах матрицы
matrixGetCols:
    mov     rax, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     eax, dword[rdi + 4]
    ret

;Начало матрицы в rdi, row в rsi, col в rdx
;Вернем 8 байт с началом в (16 + row * m + col)-ом байте матрицы
matrixGet:
    push    rbx ;Вычислим сюда row * m + col
    mov     rbx, rsi ;rbx = rsi -> rbx == row
    imul    ebx, dword[rdi + 4] ;rbx *= m -> rbx == row * m
    add     rbx, rdx ;rbx += col -> rbx == row * m + col
    movss   xmm0, dword[rdi + 8 + rbx * 4] ;Не забываем, что возвращаемое значение вещественное
    pop     rbx
    ret

;Начало матрицы в rdi, row в rsi, col в rdx, value в xmm0
;Вернем 8 байт с началом в (16 + row * m + col)-ом байте матрицы
matrixSet:
    push    rbx ;Вычислим сюда row * m + col
    mov     rbx, rsi ;rbx = rsi -> rbx == row
    imul    ebx, dword[rdi + 4] ;rbx *= m -> rbx == row * m
    add     rbx, rdx ;rbx += col -> rbx == row * m + col
    movss   dword[rdi + 8 + rbx * 4], xmm0 ;Не забываем, что храним в вещественных числах
    pop     rbx
    ret

;Начало матрицы в rdi, k в xmm0
;Вернем указатель на начало новой матрицы
matrixScale:
    push    rbx
    mov     rbx, rdi ;Запомним начало матрицы, так как rdi понадобится нам для matrixNew
    push    rdi ;Готовимся к вызову matrixNew
    push    rsi
    mov     rdi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     rsi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     edi, dword[rbx]
    mov     esi, dword[rbx + 4]
    call    matrixNew ;в rax теперь начало новой матрицы, которая заполнена нулями
    pop     rsi
    pop     rdi
    ;В rbx засунем количество ячеек матрицы
    mov     rbx, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     ebx, dword[rdi]
    imul    ebx, dword[rdi + 4]
    push    rcx ;Использую как счетчик для цикла
    ;Делаем из xmm2 (k, k, k, k)-вектор из четырех float-ов
    movss   xmm2, xmm0 ; (x, x, x, k), x означает что-то неизвестное
    unpcklps xmm2, xmm2 ; (x, x, k, k)
    unpcklpd xmm2, xmm2 ; (k, k, k, k)
    ; теперь возьмем все блоки по 4 и умножим векторно, а остальные пройдем "в лоб"
    mov     rcx, 4
    cmp     rcx, rbx ;смотрим есть ли хотя бы четыре блока
    jge     .rest ; если нет, то следующий цикл не нужен
    .loop: ;для удобства кода я могу не обработать даже 4 последнии ячейки. Ну как бы иначе цикл надо хитрить
        movups  xmm1, [rdi + rcx * 4 - 8] ; Адрес начала нового блока
        mulps   xmm1, xmm2
        movups  [rax + rcx * 4 - 8], xmm1 ; Адрес соответствующей ячейки в новой матрице
        add     rcx, 4 ; Ибо 4 float-а за раз
        cmp     rcx, rbx
        jl      .loop
    .rest:
        sub     rcx, 4  ;откатываемся назад, чтобы узнать какие ячейки мы не забили
        ; Осталось ячеек rbx - rcx штук, [rdi + 8 + rcx * 4] - начало первой
    .rest1:
        movss   xmm1, [rdi + 8 + rcx * 4] ; адрес недобработанной ячейки
        mulss   xmm1, xmm2
        movss   [rax + 8 + rcx * 4], xmm1 ; Адрес соответствующей ячейки в новой матрице
        inc     rcx
        cmp     rcx, rbx
        jne     .rest1
    .continue:
    pop     rcx
    pop     rbx
    ret

;Начало первой матрицы в rdi, начало второй в rsi
;Вернем указатель на начало новой матрицы
matrixAdd:
    push    r10
    push    r11
    mov     r10, qword[rdi] ;Копируем в r10 сразу 8 байт, содержащих в себе количество строк и столбцов первой матрицы
    mov     r11, qword[rsi] ;Тоже самое тут
    cmp     r10, r11 ; Сравним количество строк и столбцов матриц
    jne     .fail ; Если не равны, то считать ничего дальше не надо, просто идем в условие вернуть null
    push    rbx
    push    rcx
    mov     rbx, rdi ;Запомним начало первой матрицы, так как rdi понадобится нам для matrixNew
    mov     rcx, rsi ;Запомним начало второй матрицы, так как rsi понадобится нам для matrixNew
    push    rdi ;Готовимся к вызову matrixNew
    push    rsi
    mov     rdi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     rsi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     edi, dword[rbx]
    mov     esi, dword[rbx + 4]
    call    matrixNew ;в rax теперь начало новой матрицы, которая заполнена нулями
    pop     rsi
    pop     rdi
    ;В rbx засунем количество ячеек матрицы
    mov     rbx, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     ebx, dword[rdi]
    imul    ebx, dword[rdi + 4]
    ; Возьмем все блоки по 4 и умножим векторно, а остальные пройдем "в лоб"
    mov     rcx, 4 ;Использую как счетчик для цикла, пушить не надо как в matrixScale потому что я его уже запушил
    cmp     rcx, rbx ;смотрим есть ли хотя бы четыре блока
    jge     .rest ; если нет, то следующий цикл не нужен
    .loop: ;для удобства кода я могу не обработать даже 4 последнии ячейки. Ну как бы иначе цикл надо хитрить
        movups  xmm1, [rdi + rcx * 4 - 8] ; Адрес начала нового блока
        movups  xmm2, [rsi + rcx * 4 - 8]
        addps   xmm1, xmm2
        movups  [rax + rcx * 4 - 8], xmm1 ; Адрес соответствующей ячейки в новой матрице
        add     rcx, 4 ; Ибо 4 float-а за раз
        cmp     rcx, rbx
        jl      .loop
    .rest:
    sub     rcx, 4  ;откатываемся назад, чтобы узнать какие ячейки мы не забили
    ; Осталось ячеек rbx - rcx штук, [rdi + 8 + rcx * 4] - начало первой
    .rest1:
        movss   xmm1, [rdi + 8 + rcx * 4] ; адрес недобработанной ячейки
        movss   xmm2, [rsi + 8 + rcx * 4]
        addss   xmm1, xmm2
        movss   [rax + 8 + rcx * 4], xmm1 ; Адрес соответствующей ячейки в новой матрице
        inc     rcx
        cmp     rcx, rbx
        jne     .rest1
    pop     rcx
    pop     rbx
    jmp     .return ;если мы тут, значит все прошло хорошо, значит нужно обойти присвоение ответу null
    .fail:
    mov     rax, 0
    .return:
    pop     r10
    pop     r11
    ret


;Начало матрицы в rdi
;Вернем указатель на начало новой матрицы
matrixTranspose:
    push    rbx
    mov     rbx, rdi ;Запомним начало матрицы, так как rdi понадобится нам для matrixNew
    push    rdi ;Готовимся к вызову matrixNew
    push    rsi
    mov     rdi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     rsi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     edi, dword[rbx + 4]
    mov     esi, dword[rbx]
    call    matrixNew ;в rax теперь начало новой матрицы, которая заполнена нулями при этом она размера (m x n)
    pop     rsi
    pop     rdi
    push    rcx
    mov     rcx, 0
    .loopstr: ;перебираем строки
        mov     rbx, 0
        .loopel: ; перебираем столбцы
            push    rdx ;Вычислим сюда row * m + col
            mov     rdx, rcx
            imul    edx, dword[rdi + 4] ;Все также как в matrixGet
            add     rdx, rbx
            movss   xmm0, dword[rdi + 8 + rdx * 4] ;Не забываем, что храним в вещественных числах
            mov     rdx, 0 ;Вычислим сюда col * n + row, то бишь координаты в транспонированной матрице
            mov     rdx, rbx
            imul    edx, dword[rdi] ;Все также как в matrixGet
            add     rdx, rcx
            movss   dword[rax + 8 + rdx * 4], xmm0
            pop     rdx
            inc     rbx
            cmp     ebx, dword[rdi + 4]
            jne     .loopel
        inc     rcx
        cmp     ecx, dword[rdi]
        jne     .loopstr
    pop     rcx
    pop     rbx
    ret

;Начало первой матрицы в rdi, начало второй в rsi
;Пусть первая размера (n x m), вторая (m x q)
;Вернем указатель на начало новой матрицы
matrixMul:
    push    r10
    push    r11
    mov     r10d, dword[rdi + 4] ;Копируем в r10 количество столбцов первой матрицы
    mov     r11d, dword[rsi] ;А в r11 количество строк второй
    cmp     r10, r11 ; Сравним количество строк и столбцов матриц
    jne     .fail ; Если не равны, то считать ничего дальше не надо, просто идем в условие вернуть null
    ;Чтобы умножение можно было хоть как-то соптимизировать, транспонируем вторую матрицу и будем умножать строку на строку
    push    rdi
    mov     rdi, rsi
    call    matrixTranspose ;в rax теперь начало новой матрицы, которая является транспонированной второй
    pop     rdi
    push    r15
    mov     r15, rax ;Перекинем в r15 указатель на транспонированную матрицу, так как rax нам еще много где понадобится
    push    rbx
    push    rcx
    mov     rbx, rdi ;Запомним начало первой матрицы, так как rdi понадобится нам для matrixNew
    mov     rcx, rsi ;Запомним начало второй матрицы, так как rsi понадобится нам для matrixNew
    push    rdi ;Готовимся к вызову matrixNew
    push    rsi
    mov     rdi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     rsi, 0 ;Зануляем регистр, чтобы потом в старших байтах ничего лишнего не вылезло
    mov     edi, dword[rbx] ;n
    mov     esi, dword[rcx + 4] ;q
    call    matrixNew ;в rax теперь начало новой матрицы, которая заполнена нулями и имеет размер (n x q)
    pop     rsi
    pop     rdi
    push    r9
    mov     r9, 0
    mov     r9d, [rdi + 4] ;m
    mov     rcx, 0
    .loop1: ; цикл по строкам первой матрицы
        mov     rbx, 0
        .loop2: ; цикл по строкам второй матрицы
            xorps   xmm0, xmm0
            xorps   xmm1, xmm1 ; Зануляем регистры, ноль подавать не очень ясно как, зато ясно как проксорить

            push    r12 ;Вычислим сюда позицию в первой матрице [rdi + 8 + row1 * m * 4]
            mov     r12, rcx
            imul    r12, r9
            shl     r12, 2
            add     r12, rdi
            add     r12, 8

            push    r13 ;Вычислим сюда позицию в транспонированной второй матрице [r15 + 8 + row2 * m * 4]
            mov     r13, rbx
            imul    r13, r9
            shl     r13, 2
            add     r13, r15
            add     r13, 8

            ;дальше идут циклы сформированные по тому же принципу, что в matrixAdd и matrixScale
            push    r14
            mov     r14, 4
            cmp     r14, r9 ;смотрим есть ли хотя бы четыре блока
            jge     .rest ; если нет, то следующий цикл не нужен
            .loop: ;для удобства кода я могу не обработать даже 4 последнии ячейки. Ну как бы иначе цикл надо хитрить
                movups  xmm2, [r12] ; Адрес начала нового блока
                movups  xmm3, [r13]
                mulps   xmm2, xmm3
                addps   xmm0, xmm2
                add     r14, 4 ; Ибо 4 float-а за раз
                add     r12, 16
                add     r13, 16
                cmp     r14, r9
                jl      .loop
            .rest:
                sub     r14, 4  ;откатываемся назад, чтобы узнать какие ячейки мы не забили
                ; Осталось ячеек rbx - rcx штук, [rdi + 8 + rcx * 4] - начало первой
            .rest1:
                movss   xmm2, dword[r12] ; адрес недобработанной ячейки
                movss   xmm3, dword[r13]
                mulss   xmm2, xmm3
                addps   xmm1, xmm2
                inc     r14
                add     r12, 4
                add     r13, 4
                cmp     r14, r9
                jne     .rest1
            ; Теперь сложим все значения xmm0 и xmm1
            haddps  xmm0, xmm0
            haddps  xmm0, xmm0 ;тут надо сделать два раза, потому что эта забавная операция очень хитрая)
            addps   xmm1, xmm0
            ;Копипаста matrixSet
            mov     r14, rcx
            imul    r14d, dword[rax + 4]
            add     r14, rbx
            movss   dword[rax + 8 + r14 * 4], xmm1
            pop     r14
            pop     r13
            pop     r12
            inc     rbx
            cmp     ebx, dword[r15]
            jne     .loop2
        inc     rcx
        cmp     ecx, dword[rdi]
        jne     .loop1
    ;нужно удалить транспанированную матрицу
    push    rax ; Мда, кто б мог подумать, что free попортит мне rax
    push    rdi
    mov     rdi, r15
    call    matrixDelete
    pop     rdi
    pop     rax
    pop     r9
    pop     rcx
    pop     rbx
    pop     r15
    jmp     .return ;если мы тут, значит все прошло хорошо, значит нужно обойти присвоение ответу null
    .fail:
    mov     rax, 0
    .return:
    pop     r11
    pop     r10
    ret
