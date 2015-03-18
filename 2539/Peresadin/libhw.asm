section .text

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
global matrixTranspose

;Структура матрицы
struc Matrix
    rows:     resq 1
    cols:     resq 1;rows, cols - выровненные размеры матрицы (rows = ceil(initRows/4), cols = ceil(initCols/4))
    data:     resq 1;элементы матрицы
    initRows: resq 1
    initCols: resq 1;initRows, initCols - размеры матрицы
endstruc

;Создает новую матрицу
;Принимает
	;rdi - количество строк матрицы
	;rsi - количество столбцов матрицы
;Возвращает
	;rax - указатель на новую матрицу
matrixNew:
    push rsi;сохраняем регистры
    push rdi
    mov rdi, Matrix_size
    call malloc;создаем структуру матрицы
    pop rdi
    pop rsi
    mov rdx, rax ;rdx - указатель на результирующую структуру
    mov [rax + initRows], rdi
    mov [rax + initCols], rsi;сохраняем размеры матрицы
    
    add rdi, 3
    add rsi, 3
    shr rdi, 2
    shr rsi, 2
    shl rdi, 2
    shl rsi, 2
    ;rdi = ((rdi + 3) / 4)*4, rsi = ((rsi + 3) / 4)*4 - выравниваем размеры
    mov [rax + rows], rdi
    mov [rax + cols], rsi
    ;сохранем их

    imul rdi, rsi
    mov rcx, rdi
    shl rdi, 2
    push rdx
    push rcx
    call malloc;выделяем rdi*rsi - элементов матрицы
    pop rcx
    pop rdx
    mov [rdx + data], rax

    .set_zeroes;заполняем матрицу нулями
        mov dword [rax + 4 * rcx - 4], 0
        loop .set_zeroes
    mov rax, rdx;возвращаем результат
    ret

;Удаляет матрицу
;Принимает
	;rdi - указатель на матрицу
matrixDelete:
    push rdi
    mov rdi, [rdi + data]
    call free;удаляем данные матрицы
    pop rdi
    call free;удаляем структуру матрицы
    ret

;Возвращает количество строк в матрице
;Принимает
	;rdi - указатель на матрицу
;Возращает
	;rax - количество строк в матрице
matrixGetRows:
    mov rax, [rdi + initRows]
    ret

;Возвращает количество столбцов в матрице
;Принимает
	;rdi - указатель на матрицу
;Возвращает
	;rax - количество столбцов в матрице
matrixGetCols:
    mov rax, [rdi + initCols]
    ret

;Возвращает указатель на элемент структуры
;Принимает
	;rdi - указатель на матрицу
	;rsi - номер строки
	;rdx - номер столбца
;Возвращает
	;rax - указатель на rdi[rsi][rdx] элемент матрицы
loadAdress:
    imul rsi, [rdi + cols]
    add rsi, rdx
    shl rsi, 2;rsi - номер ячейки [rsi][rdx] умноженный на 4 (размер float)
    mov rax, [rdi + data];узнаем указатель на данные
    add rax, rsi;складываем указатель на начало данных с номером элемента
    ret
    
;Возвращает элемент матрицы на i, j позиции
;Принимает
	;rdi - указатель на матрицу
	;rsi - номер строки
	;rdx - номер столбца
;Возвращает значение элемента матрицы rdi[rsi][rdx]

matrixGet:
    call loadAdress;получаем указатель на элемент
    movss xmm0, [rax]
    ret

;Присваивает элементу матрицы на i, j позиции значение
;Принимает
	;rdi - указатель на матрицу
	;rsi - номер строки
	;rdx - номер столбца
	;xmm0 - новое значение элемента
matrixSet:
    call loadAdress;получаем указатель на элемент
    movss [rax], xmm0
    ret
    
;Умножает каждый элемент матрицы на k и результат помещает в новую матрицу
;Принимает
	;rdi - указатель на матрицу
	;xmm0 - значение, на которое нужно умножить
;Возвращает
	;rax - указатель на новую матрицу, умноженную на xmm0
matrixScale:
    push rbp
    mov rbp, rdi
    mov rdi, [rbp + initRows]
    mov rsi, [rbp + initCols]
    push rbp
    mov rbp, [rsp + 8];восстанавливаем rbp перед вызовом matrixNew
    sub rsp, 8
    movss [rsp], xmm0;сохраняем xmm0
    call matrixNew;создаем новую матрицу в rax
    movss xmm0, [rsp]
    add rsp, 8
    pop rbp

    mov rcx, [rbp + rows]
    imul rcx, [rbp + cols];считаем кол-во элементов в матрице
    sub rcx, 4
    unpcklps xmm0, xmm0
    unpcklps xmm0, xmm0;xmm0 = k:k:k:k
    mov rbp, [rbp + data];получаем указатель на данные старой матрицы
    mov r8, [rax + data];получаем указатель на данные новой матрицы
    .loop;идем с конца по матрице
        movups xmm1, [rbp + 4 * rcx];загружаем в регистр xmm1 4 очередных числа
        mulps xmm1, xmm0;умножаем каждое из них на k векторной операцией
        movups [r8 + 4 * rcx], xmm1;загружаем результат в новую матрицу
        sub rcx, 4
        jns .loop;rdi - указатель на данные первой матрицы
    pop rbp
    ret
    
;Cкладывает две матрицы и результат помещает в новую матрицу
;Принимает
	;rdi - указатель на первую матрицу
	;rsi - указатель на вторую матрицу
;Возвращает
	;rax - указатель на новую матрицу, которая равна сумме матриц
matrixAdd:
    push rdi
    push rsi
    mov r8, rdi
    mov r9, rsi
    ;проверяем, что размеры матриц равны
    mov rdi, [r8 + initRows]
    cmp rdi, [r9 + initRows]
    jne .error
    mov rsi, [r8 + initCols]
    cmp rsi, [r9 + initCols]
    jne .error
    ;rdi - кол-во строк в новой матрице, rsi - кол-во столбцов в новой матрице
    call matrixNew;создаем новую матрицу такого же размера, как исходные в rax
    pop rsi
    pop rdi
    ;rsi, rdi - указатели на матрицы
    mov rcx, [rdi + rows]
    imul rcx, [rdi + cols];считаем количество элементов в матрице
    sub rcx, 4
    mov rdi, [rdi + data];rdi - указатель на данные первой матрицы
    mov rsi, [rsi + data];rsi - указатель на данные второй матрицы
    mov r10, [rax + data];rax - указатель на данные матрицы-результата
    .loop;бежим с конца по матрицам
        movups xmm0, [rdi + 4 * rcx];загружаем в xmm0 4 очередных числа из первой матрицы
        addps xmm0, [rsi + 4 * rcx];векторно прибавляем к ним 4 числа из второй
        movups [r10 + 4 * rcx], xmm0;сохраняем результат
        sub rcx, 4
        jns .loop;если rcx >= 0 - продолжаем
    ret
    .error;если размеры матрицы не совпадают - возвращаем 0
    xor rax, rax
    ret

;Создает новую матрицу, которая равна транспонированной исходной
;Принимает
	;rdi - указатель на матрицу
;Возвращает
	;rax - указатель на новую транспонированную матрицу
matrixTranspose:
    push rbp
    push rdi
    push rsi

    mov rbp, rdi;rbp - указатель на исходную матрицу
    mov rsi, [rbp + initRows]
    mov rdi, [rbp + initCols]
    push rbp
    mov rbp, [rsp + 24];восстанавливем rbp перед вызовом matrixNew
    call matrixNew;создаем новую матрицу размером (m, n) в rax
    pop rbp
    mov rsi, [rbp + rows]
    mov rdi, [rbp + cols]
    ;rsi, rdi - кол-во строк и столбцов в матрице
    
    mov rbp, [rbp + data];получаем указатель на данные матрицы
    xor r8, r8
    .loop1
        xor r9, r9
        .loop2
			;рассматриваем (r8, r9) - элемент исходной матрицы матрицы и записываем его в (r9, r8) элемент новой матрицы
            mov r10, r9
            imul r10, rsi
            add r10, r8;r10 = r9*m+r8
            shl r10, 2
            movss xmm0, [rbp];rbp - указатель на текущий элемент матрицы (r8 * m + n ~ rbp)
            add r10, [rax + data]
            movss [r10], xmm0;сохраняем в новую матрицу значение
            add rbp, 4;сдвигаем указатель на текущий элемент матрицы
            inc r9;увеличививаем номер столбца
            cmp r9, rdi
            jne .loop2;если рассмотрели все столбцы - останавливаемся
        inc r8;увеличиваем номер строки
        cmp r8, rsi
        jne .loop1
    pop rsi
    pop rdi
    pop rbp
    ret

;Умножает две матрицы и результат помещает в новую матрицу
;Принимает
	;rdi - указатель на первую матрицу
	;rsi - указатель на вторую матрицу
;Возвращает
	;rax - указатель на новую матрицу, которая равна произведению матриц
matrixMul:
    mov rax, [rdi + initCols]
    cmp rax, [rsi + initRows]
    jne .error;проверяем, что матрицы имею соместные размеры (n, m) и (m, k)

    push r12
    push r13
    push r14
    push r15

    mov r13, rdi;r13 - указатель на первую матрицу
    mov r12, rsi;r12 - указатель на вторую матрицу
    mov rdi, [r13 + initRows]
    mov rsi, [r12 + initCols]
    call matrixNew;создаем матрицу размера (n, k)
    mov rdi, r13
    mov rsi, r12
    ;rdi, rsi - указатель на первую матрицу и вторую матрицу, соответственно
    
    push rax
    xchg rsi, rdi
    call matrixTranspose;транспонируме вторую матрицу, чтобы умножать быстрее
    xchg rsi, rdi
    mov rsi, rax
    mov rdx, rsi
    pop rax
    ;rdi - первая матрица
	;rsi - вторая транспонированная матрица
	;rax - матрица-результат
	push rbp
	
    mov rbp, [rax + data]
    mov rcx, [rdi + cols]
    mov r11, [rdi + rows]
    mov r12, [rsi + rows]
    mov rdi, [rdi + data]
    mov rsi, [rsi + data]
    ;rdi, rsi, rbp - указатель на данные первой матрицы, второй матрицы и данные результата, соотвественно
    ;rcx - кол-во столбцов в первой матрице
    ;r11 - кол-во строк в результате
    ;r12 - кол-во столбцов в результате
    xor r8, r8
    .loop1
        xor r9, r9
        mov r15, rsi
        ;r8, r9  ячейка результирующей матрицы, значение которой мы считаем
        ;r14, r15 - указетли на элемент первой и второй матрицы, значение которых нужно перемножить и прибавить к ячейке (r8, r9)
        ;r14 ~ (r8, r10) первой матрицы
        ;r15 ~ (r9, r10) второй транспонированной матрицы
        .loop2
            lea r14, [r8 * 4]
            imul r14, rcx
            add r14, rdi
            ;проинициализировали r14
            xor r10, r10
            xorps xmm0, xmm0;в xmm0 накапливаем сумму, в результате значение xmm0 будет равно значению (r8, r9) ячейки
            .loop3;считаем значение (r8, r9) ячейки матрицы-результата
                movups xmm1, [r14]
                mulps xmm1, [r15]
                ;загружаем соотвествующие значения и перемножаем их векторной операцией
                haddps xmm1, xmm1
                haddps xmm1, xmm1
                ;складываем горизонтально 4 произведения
                addss xmm0, xmm1
                add r14, 4*4
                add r15, 4*4;сдвигаем указатели r14, r15 на следующие элементы
                add r10, 4;
                cmp r10, rcx
                jne .loop3;продолжаем, если просмотрели не все столбцы
            movss [rbp], xmm0;сохраняем результат ячейку (r8, r9)
            add rbp, 4;сдвигаем указатель на ячейку матрицы-результата
            inc r9;увеличиваем номер столбца
            cmp r9, r12
            jne .loop2
        inc r8;увеличиваем номер строки
        cmp r8, r11
        jne .loop1
        
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12

    push rax
    mov rdi, rdx
    call matrixDelete;удаляем транспонированную матрицу
    pop rax

    ret
    .error;если размеры не совместимы - возращаем 0
    xor rax, rax
    ret
