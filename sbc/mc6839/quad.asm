* From Appendix A of "Motorola MC6839 Floating Point ROM" manual.
*
* This appendix provides an application example using the MC6839
* Floating Point ROM. The program shown is one that finds the roots to
* quadratic equations of the form ax^2 + bx +c = 0 using the classic
* formula:
*
*                         -b +/- sqrt(b^2 - 4ac)
*                         ----------------------
*                                   2a
*
* Note that the program uses a standard set of macro instructions to set
* up the parameters in the correct calling seuences. Perhaps the easiest
* way to program the MC6839 Floating Point ROM is through the use of
* these macro instructions. Errors are reduced because, once the macro
* instructions are shown to be correct, their internal details can be
* ignored allowing the programmer to concentrate on only the problem at
* hand.
*
* This code example solves the specific case solving x^2 + 2x - 3 = 0
* In this case, a = 1 b = 2 c = -3 and the roots are x = 1 and x = -3.
*
* In 26 byte BCD representation, a, b, and c are:
*
* a =  1:  00  00 00 00 00  00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01  00
* b =  2:  00  00 00 00 00  00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02  00
* c = -3:  00  00 00 00 00  0F  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03  00
*
* The results should be returned stored in a and b as:
*
* a = +1.0000 (first 0F indicates real root)
*          0F 00 00 00  04  00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00  00
* b = - 3.0000 (first 0F indicates real root)
*          0F 00 00 00  04  0F  00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 00 00 00  00
*
* Second example:
* 2x^2 + 3x - 4 = 0  a = 2  b = 3  c = -4
* Solutions are 0.85078 and -2.3508
* 0F 00 00 00 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 08 05 00 07 08 00
* 0F 00 00 00 04 0F 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 03 05 00 08 00
*
  NAM   QUAD
*
  ORG   $1000
*
* HERE IS A SIMPLE EXAMPLE INVOLVING THE QUADRATIC EQUATION THAT
* SHOULD SERVE TO ILLUSTRATE THE USE OF THE MC6839 IN AN ACTUAL
* APPLICATION.
*
* MC6839 ROM DEFINITIONS - ASSUMES ROM IS AT ADDRESS $2000
*
FPREG   EQU      $203D
FPSTAK  EQU      $203F
*
* RMBS FOR THE OPERANDS, BINARY TO DECIMAL CONVERSION BUFFERS,
* AND THE FPCB.
*
*ACOEFF RMB     26              COEFFICIENT A IN AX^2 +BX +C
*BCOEFF RMB     26              COEFFICIENT B
*CCOEFF RMB     26              COEFFICIENT C

* Example using 1, 2, -3
ACOEFF  FCB     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00  BCD 1
BCOEFF  FCB     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00  BCD 2
CCOEFF  FCB     $00,$00,$00,$00,$00,$0F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00  BCD -3

* Example using 2, 3, -4
*ACOEFF FCB     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00  BCD 2
*BCOEFF FCB     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00  BCD 3
*CCOEFF FCB     $00,$00,$00,$00,$00,$0F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00  BCD -4

*
REG1    RMB     4               REGISTER 1
REG2    RMB     4               REGISTER 2
REG3    RMB     4               REGISTER 3
*
FPCB    RMB     4               FLOATING POINT CONTROL BLOCK
*
TWO     FCB     $40,00,00,00    FLOATING PT. CONSTANT TWO
FOUR    FCB     $40,$80,00,00   "        "   "        FOUR

*
*
* HERE ARE THE EQUATES AND MACRO DEFINITIONS TO ACCOMPANY THE
* QUADRATIC EQUATION EXAMPLE OF AN MC6839 APPLICATION.
*
ADD     EQU     $00              OPCODE VALUES
SUB     EQU     $02
MUL     EQU     $04
DIV     EQU     $06
REM     EQU     $08
SQRT    EQU     $12
FINT    EQU     $14
FIXS    EQU     $16
FIXD    EQU     $18
BNDC    EQU     $1C
ABS     EQU     $1E
NEG     EQU     $20
DCBN    EQU     $22
FLTS    EQU     $24
FLTD    EQU     $26
CMP     EQU     $8A
PCMP    EQU     $8E
MOV     EQU     $9A
TCMP    EQU     $CC
TPCMP   EQU     $D0
*
*
* MACRO DEFINITIONS
*
* HERE ARE THE CALLING SEQUENCE MACROS
*
MCALL   MACRO
*
*  MCALL SETS UP A MONADIC REGISTER CALL.
*
*  USAGE: MCALL <INPUT OPERAND>,<OPERATION>,<RESULT>
*
        LEAY    \1,PCR          POINTER TO THE INPUT ARGUMENT
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \3,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     \2              OPCODE
*
        ENDM
*
*
DCALL   MACRO
*
*  DCALL SETS UP A DYADIC REGISTER CALL
*
*  USAGE: DCALL <ARGUMENT #1>,<OPERATION>,<ARGUMENT #2>,<RESULT>
*
        LEAU    \1,PCR          POINTER TO ARGUMENT #1
        LEAY    \3,PCR          POINTER TO ARGUMENT #1
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \4,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     \2              OPCODE
*
        ENDM
*
*
DECBIN  MACRO
*
* DECBIN SETS UP A REGISTER CALL TO THE DECIMAL TO BINARY CONVERSION FUNCTION.
*
* USAGE: DECBIN  <BCD STRING>,<BINARY RESULT>
*
        LEAU    \1,PCR          POINTER TO THE BCD INPUT STRING
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \2,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     DCBN            OPCODE
*
        ENDM
*
*
BINDEC  MACRO
*
* BINDEC SETS UP A REGISTER CALL TO THE BINARY TO DECIMAL CONVERSION FUNCTION.
*
* USAGE: BINDEC <BINARY INPUT>,<BCD RESULT>,<# OF SIGNIFICANT DIGITS RESULT>
*
        LDU     \3              # OF SIGNIFICANT DIGITS IN THE RESULT
        LEAY    \1,PCR          POINTER TO THE BINARY INPUT
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \2,PCR          POINTER TO THE BCD RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     BNDC            OPCODE
*
        ENDM
*
*
QUAD    EQU     *
*
        LDX     #$6F00          INITIALIZE THE STACK POINTER
*
        LEAX    FPCB,PCR
        LDB     #4
WHILE1  CMPB    #0
        BLE     ENDWH1          INITIALIZE STACK FRAME TO
        DECB                    SINGLE, ROUND NEAREST.
        CLR     B,X
        BRA     WHILE1
ENDWH1
*
* CONVERT THE INPUT OPERANDS FROM BCD STRINGS TO THE INTERNAL
* SINGLE BINARY FORM.
*
        DECBIN  ACOEFF,ACOEFF
        DECBIN  BCOEFF,BCOEFF
        DECBIN  CCOEFF,CCOEFF
*
* NOW START THE ACTUAL CALCULATIONS FOR THE QUADRATIC EQUATION
*
        DCALL   BCOEFF,MUL,BCOEFF,REG1  CALCULATE B^2
        DCALL   ACOEFF,MUL,CCOEFF,REG2  CALCULATE AC
        DCALL   REG2,MUL,FOUR,REG2      CALCULATE 4AC
        DCALL   REG1,SUB,REG2,REG1      CALCULATE B^2 - 4AC
*
* CHECK RESULT OF B^2 - 4AC TO SEE IF ROOTS ARE REAL OR IMAGINARY
*
        LDA     REG1,PCR
        LBLT    ELSE1                 SIGN IS POSITIVE; ROOTS REAL
        MCALL   REG1,SQRT,REG1        CALCULATE SQRT(B^2 - 4AC)
        DCALL   ACOEFF,MUL,TWO,REG2   CALCULATE 2A
        MCALL   BCOEFF,NEG,BCOEFF     NEGATE B
*
        DCALL   BCOEFF,ADD,REG1,REG3  CALCULATE -B + SQRT(B^2 - 4AC)
        DCALL   REG3,DIV,REG2,REG3    CALCULATE (-N + SQRT(B^2 - 4AC))/2A
        BINDEC  REG3,ACOEFF,#5        CONVERT RESULT TO DECIMAL
*
        DCALL   BCOEFF,SUB,REG1,REG3  CALCULATE -B - SQRT(B^2 -4AC)
        DCALL   REG3,DIV,REG2,REG3    CALCULATE (-B + SQRT(B^2 - 4AC))/2A
        BINDEC  REG3,BCOEFF,#5        CONVERT RESULT TO DECIMAL
*
        LDA     #$FF                  SENTINEL SIGNALING THAT ROOTS ARE REAL
        STA     CCOEFF,PCR
        LBRA    ENDIF1
*
*                                     SIGN IS NEGATIVE; ROOTS IMAGINARY
ELSE1   MCALL   REG1,ABS,REG1         MAKE SIGN POSITIVE
        MCALL   REG1,SQRT,REG1        CALCULATE SQRT(B^2 - 4AC)
        DCALL   ACOEFF,MUL,TWO,REG2   CALCULATE 2A
        DCALL   REG1,DIV,REG2,REG1    CALCULATE (SQRT(B^2 - 4AC))/2A
*
        DCALL   BCOEFF,DIV,REG2,REG2  CALCULATE -B/2A
        MCALL   REG2,NEG,REG2
*
        BINDEC  REG1,BCOEFF,#5        CONVERT -B/2A TO DECIMAL
        BINDEC  REG2,ACOEFF,#5        CONVERT (SQRT(B^2 - 4AC))/2A
*
        CLR     CCOEFF,PCR            SENTINEL SIGNALLING IMAGINARY ROOTS
*
ENDIF1
       NOP                            CAN SET A BREAKPOINT HERE FOR TESTING
       NOP
       RTS
