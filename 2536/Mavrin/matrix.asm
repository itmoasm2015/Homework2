section .text

extern malloc
extern free
extern calloc

global matrixNew
global matrixDelete
global matrixGetRows
global matrixGetCols
global matrixGet
global matrixSet
global matrixScale
global matrixAdd
global matrixMul


;we need to align rows and columns to the nearest greter 4-div number
;it make possible to use SSE instructions
%macro alignByFour 1
  add %1, 3
  shr %1, 2
  shl %1, 2
%endmacro

%macro getElement 3 ; (matrix, row, column)
  imul %2, [%1+alignedColumns]
  add %2, %3
  shl %2, 2
  
  mov rax, [%1 + elements]
  add rax, %2
%endmacro

;we need to reserve some memory for getting elemets and properties of matrix
;---
;special offer - 64 bits to everyone!
;---
struc Matrix
  elements: resq 1
  rows: resq 1
  columns: resq 1
  alignedRows: resq 1
  alignedColumns: resq 1
endstruc
;Matrix matrixNew(unsigned int rows, unsigned int cols)
;in ->  rdi = number of rows
;       rsi = number if cols
;out <- rax = pointer to matrix (if matrix created)
;             null (else)
matrixNew:
  push rdi
  push rsi
  
  mov rdi, Matrix_size
  call malloc ; allocate memory for size of struct
  pop rsi
  pop rdi
  
  mov [rax + rows], rdi; save number of rows
  mov [rax + columns], rsi; and columns
  
  alignByFour rdi
  alignByFour rsi
  
  mov [rax + alignedRows], rdi ; and aligned too
  mov [rax + alignedColumns], rsi
  
  imul rdi, rsi ; size of full matrix
  mov rsi, 4 ; floatsize
  mov rcx, rax
  push rcx
  
  call calloc ;allocate zero-initialazed memory ((rows*colums) float)
  
  pop rcx
  mov [rcx + elements], rax; save point to elements of matrix
  mov rax, rcx
  
  ret
  
;void matrixDelete(Matrix matrix)
;in -> rdi = pointer to matrix which we want to delete
;out <- nope
matrixDelete:
  push rdi
  mov rdi, [rdi+elements]
  call free ;delete matrix elements
  pop rdi
  call free ;delete all structure
  ret

;unsigned int matrixGetRows(Matrix matrix)
;in -> rdi = pointer to matrix
;out <- rax = number of rows
matrixGetRows:
  mov rax, [rdi + rows]
  ret

;unsigned int matrixGetCols(Matrix matrix)
;in->rdi = pointer to matrix
;out<-rax = number of cols
matrixGetCols:
  mov rax, [rdi + columns]
  ret

;float matrixGet(Matrix matrix, unsigned int row, unsigned int col)
;in ->  rdi = pointer to matrix
;       rsi = row
;       rdx = col
;out <- xmm0 = matrix[row][col]
matrixGet:
  getElement rdi, rsi, rdx ;rax = matrix[rsi][rdx]
  movss xmm0, [rax]
  ret

;void matrixSet(Matrix matrix, unsigned int row, unsigned int col, float value)
;in ->  rdi = pointer to matrix
;       rsi = row
;       rdx = col
;       xmm0 = value(will be set to matrix[row][col])
;out <- nope
matrixSet:
  getElement rdi, rsi, rdx ;rax = matrix[rsi][rdx]
  movss [rax], xmm0
  ret
  
matrixClone:
  push rbx
  mov rbx, rdi; save matrix pointer
  mov rdi, [rbx + rows]; number of rows
  mov rsi, [rbx + columns]; end columns
  
  call matrixNew; rax point to new matrix 
  
  mov rcx, [rax + alignedColumns]
  imul rcx, [rax + alignedRows] ; number of elements in matrix
  
  mov rdi, [rax + elements] ; clone
  mov rsi, [rbx + elements] ; source
  rep movsd; copy from source to clone while count < rcx
  pop rbx
  ret

;Matrix matrixScale(Matrix matrix, float k)
;in ->  rdi = pointer to matrix
;       xmm0 = k
;out <- rax - pointer to new matrix(result of scaling by k)
matrixScale:
  push rbx
  shufps xmm0, xmm0, 0; xmm0 = k => xmm0 = (k, k, k, k)
  call matrixClone ; create new matrix. rax - pointer
  mov rbx, [rax + elements] ;point to matrix elements
  mov rcx, [rax + alignedColumns]
  imul rcx, [rax + alignedRows] ; number of elements
  
.scaleLoop:
  movups xmm1, [rbx]; take one element from matrix
  mulps xmm1, xmm0 ; element *= k
  movups [rbx], xmm1 ; set new value of element
  lea rbx, [rbx+16] ; go to next
  sub rcx, 4 ; counter--
  jnz .scaleLoop ; while counter > 0
  pop rbx
  ret
  
;Matrix matrixAdd(Matrix a, Matrix b)
;in ->  rdi = pointer to matrix A
;       rsi = pointer to matrix B
;out <- rax = pointer to matrix C=A+B(if it possible)
matrixAdd:
  ;matrixes can be added only if they have same size(same width and same height)
  mov r8, [rdi+columns] ;if getCols(a)!=getCols(b)
  mov r9, [rsi+columns]; add(a, b) is impossible
  cmp r8, r9
  jne .error
  
  mov r8, [rdi+rows]; if getRows(a)!=getRows(b)
  mov r9, [rsi+rows]; add(a, b) is impossible
  cmp r8, r9
  jne .error
  
  push rsi
  call matrixClone; create new matrix, rax - pointer
  pop rsi
  mov rcx, [rax+alignedRows]
  imul rcx, [rax+alignedColumns]; number of elements
  
  mov r8, [rax+elements];pointer to elements of clone of first matrix
  mov r9, [rsi+elements];pointer to elements of second matrix

.loopAdd:
  movups xmm0, [r8]; take element from first one (a)
  movups xmm1, [r9]; take elements from second one (b)
  addps xmm0, xmm1
  movups [r8], xmm0; save a+b to matrix
  lea r8, [r8+16] ; go to next
  lea r9, [r9+16] ; go to next
  sub rcx, 4 ; while rcx > 0
  jnz .loopAdd
  ret

.error:
  xor rax, rax
  ret ; return 0
  
;Matrix matrixMul(Matrix a, Matrix b)
;in ->  rdi = pointer to matrix A
;       rsi = pointer to matrix B
;out <- rax = pointer to matrix C=A*B(if it possible)
matrixMul:
  ;to be continued...