{-# LANGUAGE TupleSections #-}

import Control.Monad

import Foreign.Ptr
import Foreign.C.Types

import System.Random

type Matrix = Ptr ()

foreign import ccall "../../include/matrix.h"
    matrixNew :: CInt -> CInt -> IO Matrix
foreign import ccall "../../include/matrix.h"
    matrixDelete :: Matrix -> IO ()
foreign import ccall "../../include/matrix.h"
    matrixGetRows :: Matrix -> IO CInt
foreign import ccall "../../include/matrix.h"
    matrixGetCols :: Matrix -> IO CInt
foreign import ccall "../../include/matrix.h"
    matrixGet :: Matrix -> CInt -> CInt -> IO CFloat
foreign import ccall "../../include/matrix.h"
    matrixSet :: Matrix -> CInt -> CInt -> CFloat -> IO ()

main = do
    let width = 4
        height = 5
    matrix <- matrixNew width height
    rows <- matrixGetRows matrix
    cols <- matrixGetCols matrix
    print (rows, cols)
    let allIndices = concatMap (\i -> map (, i) [0 .. width - 1]) [0 .. height - 1]
    forM_ allIndices $ \(i, j) -> do
        number <- randomIO
        matrixSet matrix i j number
        print number
    putStrLn ""
    forM_ allIndices $ \(i, j) -> matrixGet matrix i j >>= print
    matrixDelete matrix
