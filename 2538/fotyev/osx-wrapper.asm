section .text

global _matrixNew
global _matrixDelete
global _matrixGetRows
global _matrixGetCols
global _matrixGet
global _matrixSet
global _matrixScale
global _matrixAdd
global _matrixMul
global _matrixTranspose

extern matrixNew
extern matrixDelete
extern matrixGetRows
extern matrixGetCols
extern matrixGet
extern matrixSet
extern matrixScale
extern matrixAdd
extern matrixMul
extern matrixTranspose


extern _malloc
extern _free

global malloc
global free

_matrixNew: jmp matrixNew
_matrixDelete: jmp matrixDelete
_matrixGetRows: jmp matrixGetRows
_matrixGetCols: jmp matrixGetCols
_matrixGet: jmp matrixGet
_matrixSet: jmp matrixSet
_matrixScale: jmp matrixScale
_matrixAdd: jmp matrixAdd
_matrixMul: jmp matrixMul
_matrixTranspose: jmp matrixTranspose

malloc: jmp _malloc
free: jmp _free
