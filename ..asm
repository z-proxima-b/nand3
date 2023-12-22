@256
D=A
@SP
M=D
@Sys.init
0; JMP
// function ["entry point"]
(Sys.init)
// function ["init locals"]
D=0
@LCL
A=M
// function ["finished init locals"]
// push ["constant", "4000"]
@4000
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "0"]
@0
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "5000"]
@5000
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "1"]
@1
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// function ["push nArgs (0)"]
// function ["push return address (RETURN1)"]
@RETURN1
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push LCL"]
@LCL
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push ARG"]
@ARG
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push THIS"]
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push THAT"]
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["reposition ARG"]
@5
D=A
@nArgs
D=D+A
@R14
M=D
@ARG
M=M-D
@SP
D=M
@LCL
M=D
@Sys.main
0; JMP
(RETURN1)
// pop ["temp", "1"]
@1
D=A
@R5
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
(LOOP)
@LOOP
0; JEQ
// function ["entry point"]
(Sys.main)
// function ["init locals"]
D=0
@LCL
A=M
@SP
A=M
M=D
@SP
M=M+1
@SP
A=M
M=D
@SP
M=M+1
@SP
A=M
M=D
@SP
M=M+1
@SP
A=M
M=D
@SP
M=M+1
@SP
A=M
M=D
@SP
M=M+1
// function ["finished init locals"]
// push ["constant", "4001"]
@4001
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "0"]
@0
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "5001"]
@5001
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "1"]
@1
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "200"]
@200
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["local", "1"]
@1
D=A
@LCL
A=M
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "40"]
@40
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["local", "2"]
@2
D=A
@LCL
A=M
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "6"]
@6
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["local", "3"]
@3
D=A
@LCL
A=M
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "123"]
@123
D=A
@SP
A=M
M=D
@SP
M=M+1
// function ["push nArgs (1)"]
@0
D=A
@ARG
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push return address (RETURN2)"]
@RETURN2
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push LCL"]
@LCL
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push ARG"]
@ARG
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push THIS"]
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["push THAT"]
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
// function ["reposition ARG"]
@5
D=A
@nArgs
D=D+A
@R14
M=D
@ARG
M=M-D
@SP
D=M
@LCL
M=D
@Sys.add12
0; JMP
(RETURN2)
// pop ["temp", "0"]
@0
D=A
@R5
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["local", "0"]
@0
D=A
@LCL
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push ["local", "1"]
@1
D=A
@LCL
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push ["local", "2"]
@2
D=A
@LCL
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push ["local", "3"]
@3
D=A
@LCL
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push ["local", "4"]
@4
D=A
@LCL
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
//add
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
A=M
M=M+D
@SP
M=M+1
//add
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
A=M
M=M+D
@SP
M=M+1
//add
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
A=M
M=M+D
@SP
M=M+1
//add
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
A=M
M=M+D
@SP
M=M+1
// function ["save FRAME to a temp"]
@LCL
D=M
@R13
M=D
// function ["save return addr to a temp"]
@R13
D=M
@5
A=D-A
D=M
@RET
M=D
// function ["put return value into *ARG"]
@SP
M=M-1
@SP
A=M
D=M
@ARG
A=M
M=D
// function ["set SP to ARG+1"]
@ARG
D=M
D=D+1
@SP
M=D
// function ["set THAT to one above FRAME (LCL)"]
@R13
D=M
@1
A=D-A
D=M
@THAT
M=D
// function ["set THIS to 2 above FRAME (LCL)"]
@R13
D=M
@2
A=D-A
D=M
@THIS
M=D
// function ["set ARG to 3 above FRAME (LCL)"]
@R13
D=M
@3
A=D-A
D=M
@ARG
M=D
// function ["set LCL to 4 above FRAME (LCL)"]
@R13
D=M
@4
A=D-A
D=M
@LCL
M=D
// function ["set JUMP to return address "]
@RET
A=M
0; JMP
// function ["entry point"]
(Sys.add12)
// function ["init locals"]
D=0
@LCL
A=M
// function ["finished init locals"]
// push ["constant", "4002"]
@4002
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "0"]
@0
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["constant", "5002"]
@5002
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop ["pointer", "1"]
@1
D=A
@THIS
A=A+D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@R13
A=M
M=D
// push ["argument", "0"]
@0
D=A
@ARG
A=M
A=A+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push ["constant", "12"]
@12
D=A
@SP
A=M
M=D
@SP
M=M+1
//add
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
A=M
M=M+D
@SP
M=M+1
// function ["save FRAME to a temp"]
@LCL
D=M
@R13
M=D
// function ["save return addr to a temp"]
@R13
D=M
@5
A=D-A
D=M
@RET
M=D
// function ["put return value into *ARG"]
@SP
M=M-1
@SP
A=M
D=M
@ARG
A=M
M=D
// function ["set SP to ARG+1"]
@ARG
D=M
D=D+1
@SP
M=D
// function ["set THAT to one above FRAME (LCL)"]
@R13
D=M
@1
A=D-A
D=M
@THAT
M=D
// function ["set THIS to 2 above FRAME (LCL)"]
@R13
D=M
@2
A=D-A
D=M
@THIS
M=D
// function ["set ARG to 3 above FRAME (LCL)"]
@R13
D=M
@3
A=D-A
D=M
@ARG
M=D
// function ["set LCL to 4 above FRAME (LCL)"]
@R13
D=M
@4
A=D-A
D=M
@LCL
M=D
// function ["set JUMP to return address "]
@RET
A=M
0; JMP
