import Foreign.Ptr
import Foreign.C.Types

type Matrix = Ptr ()

foreign import ccall unsafe "../../include/matrix.h"
    matrixNew :: CInt -> CInt -> IO Matrix
foreign import ccall unsafe "../../include/matrix.h"
    matrixDelete :: Matrix -> IO ()
foreign import ccall unsafe "../../include/matrix.h"
    matrixGetRows :: Matrix -> IO CInt
foreign import ccall unsafe "../../include/matrix.h"
    matrixGetCols :: Matrix -> IO CInt

main = do
    matrix <- matrixNew 14 15
    rows <- matrixGetRows matrix
    cols <- matrixGetCols matrix
    print (rows, cols)
    matrixDelete matrix
