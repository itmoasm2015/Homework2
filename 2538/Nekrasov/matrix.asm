section .text

default rel

; о структуре матрицы см. стр. 195
; выровненное число = число, округлённое вверх до ближайшего целого числа, кратного 4

extern malloc
extern aligned_alloc
extern free

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixTranspose
global matrixMul

; округляет число вверх до ближайшего целого, кратного 4
; %2 - округляемое число
; %1 - минимум из чисел, больших или равных %2 и кратных 4
%macro ceil 2
	mov	%1, %2
	dec	%1
	shr	%1, 2
	shl	%1, 2
	lea	%1, [%1 + 4]			; %1 <- (%2 - 1) / 4 * 4 + 4
%endmacro

; количество элементов в матрице (включая пустые элементы в конце каждой выровненной строки)
; %1 - указатель на матрицу
; результат в rcx: количество 4-байтовых блоков от начала данных матрицы до конца последней выровненной строки
%macro alsize 1
	xor	rax, rax
	xor	rcx, rcx
	mov	eax, [%1 + 28]
	mov	ecx, [%1 + 16]
	mul	rcx
	mov	rcx, rax
%endmacro

; сохраняет в стек rsi, rdi, rdx, rcx, r8-r11
%macro caller_save 0
	push	r11
	push	r10
	push	r9
	push	r8
	push	rcx
	push	rdx
	push	rdi
	push	rsi
%endmacro

; забирает из стека rsi, rdi, rdx, rcx, r8-r11
%macro caller_take 0
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
	pop	r8
	pop	r9
	pop	r10
	pop	r11
%endmacro

; просто dpps из sse4.1
%macro dpps 3
	mulps	%1, %2
	haddps	%1, %1
	haddps	%1, %1
%endmacro

; создаёт новую матрицу и заполняет её нулями
; edi - количество строк
; esi - количество столбцов
; результат в rax: указатель на созданную матрицу
matrixNew:
	call	matrixAlloc			; создаём новую матрицу
	cmp	rax, 0
	je	.end

	mov	r11, rax
	alsize	r11				; rcx - количество обрабатываемых блоков памяти по 4 байта
	mov	rax, r11

	jrcxz	.end				; пустая матрица не обнуляется
	shr	rcx, 2				; матрица зануляется по 4 элемента
	xorps	xmm0, xmm0			; xmm0 = {0, 0, 0, 0}
	mov	r8, [r11]			; r8 - указатель на начало данных новой матрицы
	.loop:					; обнуляем матрицу
		movaps	[r8], xmm0
		lea	r8, [r8 + 16]
		loop	.loop
.end:
	ret

; удаляет ранее созданную матрицу
; rdi - указатель на удаляемую матрицу
matrixDelete:
	mov	rsi, rdi
	mov	rdi, [rsi]
	caller_save
	call	free				; освобождаем память, выделенную под данные матрицы

	pop	rsi
	mov	rdi, rsi
	push	rsi
	call	free				; освобождаем память, выделенную под структуру матрицы
	caller_take
	ret

; возвращает количество строк в матрице
; rdi - указатель на матрицу
; результат в eax - количество строк в матрице
matrixGetRows:
	mov	eax, [rdi + 16]
	ret

; возвращает количество столбцов в матрице
; rdi - указатель на матрицу
; результат в eax - количество столбцов в матрице
matrixGetCols:
	mov	eax, [rdi + 24]
	ret

; возвращает элемент матрицы
; rdi - указатель на матрицу
; esi - номер строки, в которой находится элемент, начиная с 0
; edx - номер столбца, в котором находится элемент, начиная с 0
; результат в xmm0 - элемент матрицы по данным строке и столбцу
matrixGet:
	and	rsi, 0x00000000FFFFFFFF
	xor	rcx, rcx
	xor	rax, rax			; обнуление верхних 32 бита rsi, rcx и rax
	mov	ecx, edx

	mov	eax, [rdi + 28]
	mul	rsi
	lea	rax, [rax + rcx]		; rax - количество элементов, предшествующих данному (ВырСтб * Стр + Стб)
	mov	r8, [rdi]			; r8 - указатель на начало данных матрицы
	movss	xmm0, [r8 + rax * 4]

	ret

; присваивает значение элементу матрицы
; rdi - указатель на матрицу
; esi - номер строки, в которой находится элемент, начиная с 0
; edx - номер столбца, в котором находится элемент, начиная с 0
; xmm0 - присваиваемое значение
matrixSet:
	and	rsi, 0x00000000FFFFFFFF
	xor	rcx, rcx
	xor	rax, rax			; обнуление верхних 32 бита rsi, rcx и rax
	mov	ecx, edx

	mov	eax, [rdi + 28]
	mul	rsi
	lea	rax, [rax + rcx]		; rax - количество элементов, предшествующих данному (ВырСтб * Стр + Стб)
	mov	r8, [rdi]			; r8 - указатель на начало данных матрицы
	movss	[r8 + rax * 4], xmm0
	
	ret
	
; умножает матрицу на скаляр
; rdi - указатель на матрицу; матрица обязана сохраниться после функции
; xmm0 - скаляр, на который умножается матрица
; результат в eax - новая матрица, полученная умножением матрицы по адресу rdi на скаляр xmm0
matrixScale:
	call	matrixClone			; копирование матрицы в новую
	cmp	rax, 0
	je	.end

	mov	r11, rax
	alsize	r11				; rcx - количество обрабатываемых блоков памяти по 4 байта
	mov	rax, r11

	jrcxz	.end				; пустая матрица не умножается
	shr	rcx, 2				; каждый обрабатываемый 128-битный блок данных содержит 4 элемента матрицы
	mov	r8, [r11]			; r8 - указатель на начало данных результата
	shufps	xmm0, xmm0, 0
	.loop:
		movaps	xmm1, [r8]
		mulps	xmm1, xmm0
		movaps	[r8], xmm1		; ([r8] <-) xmm1 <- xmm1 (<- [r8]) * xmm0: умножение очередного блока данных
		lea	r8, [r8 + 16]		; переход к следующему блоку данных
		loop	.loop
.end:
	ret

; складывает две матрицы одинакового размера
; rdi - указатель на матрицу - первое слагаемое
; rsi - указатель на матрицу - второе слагаемое
; результат в rax - указатель на новую матрицу, являющуюся суммой rdi и rsi, или 0, если количества строк или столбцов в слагаемых не равны
matrixAdd:
	mov	edx, [rdi + 16]
	mov	ecx, [rsi + 16]
	cmp	edx, ecx
	jne	.null				; проверка равенства количества строк
	mov	edx, [rdi + 24]
	mov	ecx, [rsi + 24]
	cmp	edx, ecx
	jne	.null				; проверка равенства количества столбцов

	push	rsi
	call	matrixClone			; копирование первого слагаемого в новую матрицу
	pop	rsi
	cmp	rax, 0
	je	.end

	mov	r11, rax
	alsize	r11				; rcx - количество обрабатываемых блоков памяти по 4 байта
	mov	rax, r11

	jrcxz	.end				; пустые матрицы не складываются
	shr	rcx, 2				; каждый обрабатываемый 128-битный блок данных содержит 4 элемента матрицы
	mov	r8, [rax]
	mov	r9, [rsi]			; r8 - указатель на начало данных результата, r9 - указатель на начало данных второго слагаемого
	.loop:
		movaps	xmm0, [r8]
		movaps	xmm1, [r9]
		addps	xmm0, xmm1
		movaps	[r8], xmm0		; ([r8] <-) xmm0 <- xmm0 (<- [r8]) + xmm1 (<- [r9]): складывание очередных блоков данных
		lea	r8, [r8 + 16]
		lea	r9, [r9 + 16]		; переход к следующим блокам данных
		loop	.loop
	jmp	.end

.null:
	xor	rax, rax
.end:
	ret

; перемножает две матрицы
; rdi - указатель на первую матрицу
; rsi - указатель на вторую матрицу
; результат в eax - указатель на матрицу, полученную перемножением rdi и rsi, или 0, если количество столбцов в rdi не равно количеству строк в rsi
matrixMul:
	push	r15
	push	r14
	push	r13
	push	r12
	push	rbx

	mov	edx, [rdi + 24]
	mov	ecx, [rsi + 16]
	cmp	rdx, rcx
	jne	.null				; возврат 0 в случае несовместимости размеров матриц

	xchg	rdi, rsi
	push	rsi
	call	matrixTranspose			; rsi - первая матрица, rdi - вторая транспонированная матрица
	pop	rsi
	cmp	rax, 0
	je	.end
	mov	rdi, rax

	push	rsi
	push	rdi
	mov	edi, [rdi + 16]
	mov	esi, [rsi + 16]
	and	rdi, 0x00000000FFFFFFFF
	and	rsi, 0x00000000FFFFFFFF
	call	matrixAlloc			; выделение памяти под результат в rax
	mov	r15, [rax + 28]
	pop	rdi
	pop	rsi
	cmp	rax, 0
	je	.end

	mov	r8, [rax]
	mov	r9, [rsi]
	mov	r10, [rdi]
	xor	rdx, rdx
	xor	rcx, rcx
	xor	rbx, rbx
	mov	edx, [rsi + 16]
	mov	ecx, [rdi + 16]
	mov	ebx, [rsi + 28]
	shr	rbx, 2
	
	xor	r11, r11
	.loop1:
		xor	r12, r12
		.loop2:
			xor	r13, r13
			xorps	xmm0, xmm0
			.loop3:
				lea	r14, [rbx * 4]
				imul	r14, r11
				add	r14, r13
				shl	r14, 2
				movaps	xmm1, [r9 + r14]
				lea	r14, [rbx * 4]
				imul	r14, r12
				add	r14, r13
				shl	r14, 2
				movaps	xmm2, [r10 + r14]
				dpps	xmm1, xmm2, 0xF1
				addss	xmm0, xmm1

				inc	r13
				cmp	r13, rbx
				jne	.loop3
			mov	r14, r15
			imul	r14, r11
			add	r14, r12
			movss	[r8 + r14 * 4], xmm0

			inc	r12
			cmp	r12, rcx
			jne	.loop2
		inc	r11
		cmp	r11, rdx
		jne	.loop1
	jmp	.end

.null:
	xor	rax, rax
.end:
	pop	rbx
	pop	r12
	pop	r13
	pop	r14
	pop	r15

	ret

; размещает в памяти матрицу
; edi - количество строк
; esi - количество столбцов
; результат в eax - указатель на созданную матрицу
matrixAlloc:
	and	rdi, 0x00000000FFFFFFFF
	and	rsi, 0x00000000FFFFFFFF		; обнуление верхних 32 бит rsi и rdi
	ceil	r10, rdi			; в r10 заносится выровненное количество строк
	ceil	r11, rsi			; в r11 заносится выровненное количество столбцов

	lea	rax, [r10 * 4]
	mul	r11
	mov	r9, rax
	caller_save
	mov	rsi, r9
	mov	rdi, 16
	call	aligned_alloc			; выделение памяти для данных матрицы
	caller_take
	cmp	rax, 0
	je	.end				; aligned_alloc завершился неудачно

	mov	r8, rax
	caller_save
	mov	rsi, 32
	mov	rdi, 16
	call	aligned_alloc			; выделение памяти для структуры матрицы
	caller_take
	cmp	rax, 0
	je	.end				; aligned_alloc завершился неудачно
						
						; структура создаваемой матрицы:

	mov	[rax], r8			; 0..7:		указатель на данные матрицы
	mov	[rax + 8], r9			; 8..15:	размер памяти, выделенной под данные матрицы, в байтах
	mov	[rax + 16], edi			; 16..19:	количество строк матрицы
	mov	rdi, r10
	mov	[rax + 20], edi			; 24..27:	выровненное количество строк матрицы
	mov	[rax + 24], esi			; 24..27:	количество столбцов матрицы
	mov	rsi, r11
	mov	[rax + 28], esi			; 28..31:	выровненное количество столбцов матрицы

.end:
	ret

; создаёт новую матрицу и копирует туда данные из старой
; rdi - указатель на копируемую матрицу
; результат в eax - скопированная матрица
matrixClone:
	push	rdi
	mov	esi, [rdi + 24]
	mov	edi, [rdi + 16]
	call	matrixAlloc			; создание новой матрицы
	cmp	rax, 0
	jz	.end				; matrixAlloc завершился неудачно
	pop	rdi

	mov	r11, rax
	alsize	r11				; rcx - количество обрабатываемых блоков памяти по 4 байта
	mov	rax, r11

	jecxz	.end				; данные из пустой матрицы не копируются
	shr	rcx, 2				; данные копируются кусками по 4 элемента
	mov	r8, [r11]
	mov	r9, [rdi]			; r8 - указатель на начало данных копируемой матрицы, r9 - новой матрицы
	.loop:
		movaps	xmm1, [r9]
		movaps	[r8], xmm1		; [r8] <- xmm1 <- [r9]
		lea	r8, [r8 + 16]
		lea	r9, [r9 + 16]		; переход к следующим блокам данных
		loop	.loop

.end:
	ret

; создаёт копию матрицы и транспонирует эту копию
; rdi - указатель на транспонируемую матрицу
; результат в eax - транспонированная матрица
matrixTranspose:
	push	r13
	push	r12
	push	rbx

	xor	rdx, rdx
	xor	rsi, rsi
	mov	edx, [rdi + 24]
	mov	esi, [rdi + 16]
	xchg	rdi, rdx
	push	rdx
	call	matrixAlloc			; копирование исходной матрицы
	pop	rdi

	mov	r8, [rax]			; r8 - указатель на начало данных матрицы
	mov	r9, [rdi]
	xor	rbx, rbx
	mov	ebx, [rdi + 28]
	mov	r13, rbx
	xor	rdi, rdi
	mov	edi, [rax + 16]			; edi - количество строк матрицы
	cmp	rdi, 1				; матрица размера 1 совпадает со своей транспозицией
	jle	.end
	
	xor	rsi, rsi
	xor	rbx, rbx
	mov	ebx, [rax + 28]			; esi - выровненный размер строки
	mov	r12, rbx
	mov	esi, [rax + 24]

	xor	rdx, rdx				; начинаем с 1-й строки
	.loop1:
		xor	rcx, rcx
		.loop2:
			mov	r10, r12
			imul	r10, rdx
			add	r10, rcx		; r10 <- rsi * rdx + rcx: элемент ниже главной диагонали
			mov	r11, r13
			imul	r11, rcx
			add	r11, rdx		; r11 <- rsi * rcx + rdx: элемент выше главной диагонали
			movss	xmm0, [r9 + r11 * 4]
			movss	[r8 + r10 * 4], xmm0	; обмен элементов
			inc	rcx
			cmp	rcx, rsi
			jne	.loop2
		inc	rdx
		cmp	rdx, rdi
		jne	.loop1
	jmp	.end
			
.null:
	xor	rax, rax
.end:
	pop	rbx
	pop	r13
	pop	r12

	ret
