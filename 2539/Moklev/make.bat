yasm -fwin64 -gdwarf2 C:\asm\Homework2\2539\Moklev\matrix.asm -o C:\asm\Homework2\2539\Moklev\matrix.o && C:\TDM-GCC-64\bin\gcc.exe C:\asm\Homework2\2539\Moklev\matrix.o C:\asm\Homework2\2539\Moklev\test.c -g -std=c99 -o test.exe && test.exe