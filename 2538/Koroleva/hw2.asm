extern aligned_alloc	; берем извне функции, которые нам понадобятся
extern free

global matrixNew			; указываем, что эти функции могут вызываться вне нашего кода
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul


; Моя структура Matrix выглядит следующим образом:
; Это указатель на область памяти, где в первых 8ми битах лежит количество строк в матрице,
;																			во вторых 8ми битах лежит количество столбцов в матрице,
;								а дальше - матрица, выровненная по ширине и высоте до делящегося на 4 значения,
;								чтобы удобнее было работать с SSE.

; Matrix matrixNew(unsigned int rows, unsigned int cols);
; Функция возвращает указатель на новую матрицу размера rows * cols.
matrixNew:
	enter 0,0

	push r12				; запоминаем регистры, которые не стоило бы портить.
	push rdi
	push rsi

	add rdi, 3			; выравниваем высоту.
	and rdi, ~3

	add rsi, 3			; выравниваем ширину.
	and rsi, ~3

	xor rdx, rdx		; зануляем rdx, чтобы ничего не вышло ненужного при умножении.
	mov rax, rdi		
	mul rsi					; теперь в rax лежит количество элементов в матрице в целом.

	mov r12, rax		; запомним это число в r12,
	shl rax, 2			; а потом умножим на 4
	add rax, 16			; и прибавим 16, чтобы узнать, а сколько всего байт займет наша будущая матрица.

	mov rdi, 16
	mov rsi, rax

	call aligned_alloc	; вызовем aligned_alloc выровненный по 16 байт.
	pop rsi
	pop rdi

	test rax, rax				; если aligned_alloc отработал с ошибкой, просто выйдем,
	jz .ret

	mov [rax], rdi			; а иначе, как и обещали, запишем в первые 16 байт ширину и высоту.
	mov [rax + 8], rsi
											; а все остальное забьем нулями.
	dec r12							; r12 - теперь указатель на текущий элемент матрицы.
	
.set_0_loop
	cmp r12, 0					; пока мы не прошли все элементы
	jl .ret

	mov dword[rax + r12 * 4 + 16], 0	; забиваем текущий элемент нулями.

	dec r12
	jmp .set_0_loop
	
.ret
	pop r12
	leave
	ret

; void matrixDelete(Matrix matrix)
; Функция удаляет переданную ей матрицу...

matrixDelete:

	call free						; ... и говорит сама за себя.
	ret

; unsigned int matrixGetRows(Matrix matrix);
; Функция возвращает высоту матрицы.
matrixGetRows:
	enter 0,0

	mov rax, [rdi]  ; высота у нас лежит непосредственно по указателю на матрицу.

	leave
	ret

; unsigned int matrixGetCols(Matrix matrix);
; Функция возвращает ширину матрицы.
matrixGetCols:
	enter 0,0

	mov rax, [rdi + 8]	; ширина лежит за высотой, а именно через 8 байт.

	leave
	ret

; float matrixGet(Matrix matrix, unsigned int row, unsigned int col);
; Функция возвращает значение, которое лежит в матрице на строке row и в столбце col
matrixGet:
	enter 0,0
	
	mov r8, [rdi]				; в r8 - высота матрицы, в r9 - ширина.
	mov r9, [rdi + 8]

	add r9, 3			;	выравниваем ширину. Высоту в данной функции можно не выравнивать.
	and r9, ~3

	xor rdx, rdx
	mov rax, r9		; ищем координату нужного элемента в линейной памяти
	mul rsi
	add rax, rdx

	movss xmm0, [rdi + rax * 4 + 16]	; записываем его в ответ. 
																		; Он типа float, поэтому в xmm0 и используя movss.

	leave
	ret


; void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value);
; Функция записывает в матрицу в строку row и в столбец col значение value.
matrixSet:
	enter 0,0
	
	mov r8, [rdi]				; в r8 высота матрицы
	mov r9, [rdi + 8]		; в r9 ширина матрицы

	add r9, 3						; выравниваем ширину. Высоту тут тоже не надо выравнивать.
	and r9, ~3

	xor rdx, rdx				
	mov rax, r9					; ищем координату нужного элемента в линейной памяти.
	mul rsi
	add rax, rdx

	movss dword[rdi + rax * 4 + 16], xmm0	; и записываем его туда.

	leave
	ret

; Matrix matrixScale(Matrix matrix, float k);
; Функция возвращает матрицу, которая является результатом умножения текущей
;		матрицы на скаляр. Начальная матрица не меняется.

matrixScale:
	enter 0,0

	mov r8, [rdi]				; в r8 высота матрицы
	mov r9, [rdi + 8]		; в r9 ширина матрицы

	push rdi						; запомним указатель на полученную матрицу, он нам пригодится.

	mov rdi, r8					;создадим матрицу такой же высоты и ширины
	mov rsi, r9

	push r8							; запомним регистры, которые могут попортиться.
	push r9
	call matrixNew			; указатель на ответ теперь лежит в rax.
	pop r9
	pop r8

	pop rdi
	
	push rax						; запомним его, он нам пригодится.

	add r8, 3						;	выровняем ширину и высоту.
	and r8, ~3
	add r9, 3
	and r9, ~3

	mov rax, r8					; начиная с последних четырех элементов, пойдем к первым
	mul r9 							; умножая их на скаляр по 4
	sub rax, 4

	mov rcx, rax				; счетчик номера элементов теперь в rcx, а rax снова указывает
											;						на матрицу овтета.
	pop rax

	pshufd xmm1, xmm0, 0	; раскопируем нулевой элемент xmm0 на все элементы xmm1
.scale_loop
	cmp rcx, 0
	jl .ret

	movaps xmm0, [rdi + rcx * 4 + 16]	; в xmm0 положим 4 текущих элемента матрицы	
	mulps xmm0, xmm1									; домножим поэлементно на xmm1
	movaps [rax + rcx * 4 + 16], xmm0	; положим в то же место в ответе
	sub rcx, 4												; перейдем к следующим 4 элементам.
	jmp .scale_loop

.ret
	leave
	ret

; Matrix matrixAdd(Matrix a, Matrix b);
; Функция записывает в новую матрицу результат сложения двух данных, не меняя их.
matrixAdd:
	enter 0,0
	mov rax, 0						; ответ по-умолчанию.

	mov r8, [rdi]					; в r8 высота матриц.
	mov r9, [rdi + 8]			; в r9 ширина матриц.

	cmp r8, [rsi]					; Если внезапно они оказались разных размеров - очень жаль.
	jne .ret

	cmp r9, [rsi + 8]
	jne .ret

	push rsi							; запомним указатели на исходные матрицы.
	push rdi
	push r8								; запомним регистры, которые могут попортиться.
	push r9

	mov rdi, r8						; создадим новую матрицу такого же размера.
	mov rsi, r9

	call matrixNew
	
	pop r9
	pop r8
	pop rdi
	pop rsi
	
	push rax							; указатель на ответ теперь в rax, запомним его.
	
	add r8, 3							; выравниваем ширину и высоту
	and r8, ~3
	add r9, 3
	and r9, ~3

	mov rax, r8						; находим количество элементов в матрицах
	mul r9 
	sub rax, 4						; начиная с последних четырех, придем к первым.

	mov rcx, rax					; rcx - счетсик текущего элемента.
	pop rax								; rax снова указывает на ответ.

.add_loop
	cmp rcx, 0
	jl .ret

	movaps xmm0, [rdi + rcx * 4 + 16]		; в xmm0 текущие 4 элемента первой матрицы.
	addps xmm0, [rsi + rcx * 4 + 16]		; прибавим к ним попарно текущие элементы второй.
	movaps [rax + rcx * 4 + 16], xmm0		; запишем в то же место в ответ.
	sub rcx, 4													; перейдем к следующим 4м элементам.
	jmp .add_loop

.ret
	leave
	ret

; Matrix transpose(Matrix matrix);
; Вспомогательная функция, которая транспонирует данную, не меняя ее.

transpose:
	enter 0,0

	push rbx							; мы обязаны сохранять rbx, если будем его портить.
	
	mov r8, rdi						; r8 - указатель на исходную матрицу	
	mov rdi, [r8 + 8]			; в rdi - ее ширина
	mov rsi, [r8]					; в rsi - ее высота

	push r8								; запомним регистры, которые могут попортиться.
	call matrixNew				; делаем новую матрицу с перевернутымии размерами.
	pop r8
	
	mov r9, rax						; r9 - указатель на ответ.

	add rdi, 3						; выровняем ширину и высоту
	and rdi, ~3						;      (ну или наоборот для транспонированной матрицы...)

	add rsi, 3	
	and rsi, ~3

	mov r10, 0						; r10 - счетчик строк для исходной матрицы.
.first_loop
	cmp r10, rsi
	jge .ret
	mov r11, 0						; r11 - счетчик столбцов для исходной матрицы.

.second_loop
	cmp r11, rdi
	jge .end_first_loop

	xor rdx, rdx				; вычисляем координату текущего элемента исходной матрицы
	mov rax, r10				; 											в линейной памяти
	mul rdi
	add rax, r11

	mov rcx, rax				; кладем ее в rcx

	xor rdx, rdx				; вычисляем координату текущего элемента транспонированной
	mov rax, r11				;									матрицы в линейной памяти
	mul rsi
	add rax, r10				; она останется в rax

	mov ebx, dword[r8 + rcx * 4 + 16]		; перекладываем значение из исходной
	mov dword[r9 + rax * 4 + 16], ebx		;				в транспонированную

	inc r11
	jmp .second_loop

.end_first_loop
	inc r10
	jmp .first_loop

.ret	
  mov rax, r9					; записываем ответ
	pop rbx
	leave
	ret

; Matrix matrixMul(Matrix a, Matrix b);
; Функция возвращает матрицу, являющуюся произведением данных двух, не меняя их.
matrixMul:
	enter 0,0

	push r12						; запомним регистры, которые стоит сохранить, по конвенции.
	push r13	
	push r14
	mov r14, 0					; в r14 будет ответ. По-умолчанию - 0

	mov r8, [rsi + 8]			; r8 - ширина второй матрицы
	mov r9, [rsi]					; r9 - высота второй матрицы
	mov r10, [rdi]				; r10 - высота первой матрицы
	mov r11, [rdi + 8]		; r11 - ширина первой матрицы

	cmp r11, r9						; если матрицы неподходящих размеров - очень жаль
	jne .ret
							
	add r11, 3						; выровняем размеры матриц.
	and r11, ~3						; r11 = r9, раз уж мы здесь. 
												; А значит далее будем пользоваться r11,
												;				а r9 нещадно портить.

	add r10, 3
	and r10, ~3

	add r8, 3
	and r8, ~3

	push rdi							; запомним все, что может попортиться в matrixNew и transpose.
	push r11
	push r10
	push r8

	mov rdi, rsi					; транспонируем вторую матрицу.
	call transpose
	mov rcx, rax					; теперь rcx показывает на транспонированную матрицу.

	cmp rcx, 0
	je .ret								; если не получилось транспонировать - очень жаль.

	pop r8								; извлечем размеры ответа из стека
	pop r10

	mov rdi, r10					; запишем их в аргументы для matrixNew
	mov rsi, r8

	push r10							; запихнем обратно в стек
	push r8
	push rcx

	call matrixNew				; сделаем матрицу для ответа
	mov r14, rax					; как мы помним, на нее должен показывать r14

	pop rcx								
	pop r8
	pop r10
	pop r11
	pop rdi

	cmp r14, 0						; если не срослось с выделением памяти под ответ - очень жаль.
	je .ret
												; тройной цикл для бегания по элементам двух матриц. 
												; мы бегаем по строчкам первой матрицы и транспонированной
												; их размеры теперь [r10 * r11] [r8 * r11]
	dec r10								; r10 - счетчик строк первой матрицы
.first_loop
	cmp r10, 0
	jl .end
	
	mov r12, 0						; r12 - счетчик строк транспонированной матрицы
.second_loop
	cmp r12, r8
	jge .end_first_loop

	mov r13, 0						; r13 - счетчик столбцов обеих матриц
	xorps xmm0, xmm0			; в xmm0 - сумма поэлементных произведений строк двух матриц
.third_loop
	cmp r13, r11
	jge .end_second_loop

	xor rdx, rdx				; координату текущей четверки элементов первой матрицы в студию!
	mov rax, r10
	mul r11
	add rax, r13
	mov rsi, rax				; она будет в rsi

	xor rdx, rdx				; координату текущей четверки элементов второй матрицы в студию!
	mov rax, r12
	mul r11
	add rax, r13
	mov r9, rax					; она будет в r9
	
	movaps xmm1, [rdi + rsi * 4 + 16]	; в xmm1 будет первая четверка.
	dpps xmm1, [rcx + r9 * 4 + 16], 10001111b ; сделаем скалярное произведение со второй
																						; запишем в первый элемент xmm1
	addps xmm0, xmm1	; сложим с текущей суммой по строке

	add r13, 4				; идем по строке по 4 элемента
	jmp .third_loop

.end_second_loop
	xor rdx, rdx		; найдем куда записать получившееся число в ответной матрице
	mov rax, r10
	mul r8
	add rax, r12
	mov rsi, rax
	movss [r14 + rsi * 4 + 16], xmm0	; и запишем!

	inc r12
	jmp .second_loop

.end_first_loop
	dec r10
	jmp .first_loop
	
.end
	mov rdi, rcx
	call matrixDelete				; убьем транспонированную матрицу.

.ret
	mov rax, r14						; запишем ответ в rax

	pop r14									; вынем все остатки из стека.
	pop r13
	pop r12

	leave										; мы великолепны.
	ret











