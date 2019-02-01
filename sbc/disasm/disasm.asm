;
; 6809 Disassembler
;
; Copyright (C) 2019 by Jeff Tranter <tranter@pobox.com>
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;
; Revision History
; Version Date         Comments
; 0.0     29-Jan-2019  First version started, based on 6502 code
;
; To Do:
; - implement all addressing modes
; - make code position independent
; - hook up as external command to ASSIST09

; Character defines

EOT     EQU     $04             ; String terminator
LF      EQU     $0A             ; Line feed
CR      EQU     $0D             ; Carriage return
SP      EQU     $20             ; Space

; ASSIST09 SWI call numbers

INCHNP  EQU     0               ; INPUT CHAR IN A REG - NO PARITY
OUTCH   EQU     1               ; OUTPUT CHAR FROM A REG
PDATA1  EQU     2               ; OUTPUT STRING
PDATA   EQU     3               ; OUTPUT CR/LF THEN STRING
OUT2HS  EQU     4               ; OUTPUT TWO HEX AND SPACE
OUT4HS  EQU     5               ; OUTPUT FOUR HEX AND SPACE
PCRLF   EQU     6               ; OUTPUT CR/LF
SPACE   EQU     7               ; OUTPUT A SPACE
MONITR  EQU     8               ; ENTER ASSIST09 MONITOR
VCTRSW  EQU     9               ; VECTOR EXAMINE/SWITCH
BRKPT   EQU     10              ; USER PROGRAM BREAKPOINT
PAUSE   EQU     11              ; TASK PAUSE FUNCTION

; Start address
        ORG     $1000

; Variables

ADDR    RMB     2               ; Current address to disassemble
OPCODE  RMB     1               ; Opcode of instruction
AM      RMB     1               ; Addressing mode of instruction
OPTYPE  RMB     1               ; Instruction type
LEN     RMB     1               ; Length of instruction
TEMP    RMB     2               ; Temp variable (used by print routines)
TEMP1   RMB     2               ; Temp variable

; Instructions. Matches indexes into entries in table MENMONICS.

OP_INV   EQU    $00
OP_ABX   EQU    $01
OP_ADCA  EQU    $02
OP_ADCB  EQU    $03
OP_ADDA  EQU    $04
OP_ADDB  EQU    $05
OP_ADDD  EQU    $06
OP_ANDA  EQU    $07
OP_ANDB  EQU    $08
OP_ANDCC EQU    $09
OP_ASL   EQU    $0A
OP_ASLA  EQU    $0B
OP_ASLB  EQU    $0C
OP_ASR   EQU    $0D
OP_ASRA  EQU    $0E
OP_ASRB  EQU    $0F
OP_BCC   EQU    $10
OP_BCS   EQU    $11
OP_BEQ   EQU    $12
OP_BGE   EQU    $13
OP_BGT   EQU    $14
OP_BHI   EQU    $15
OP_BHS   EQU    $16
OP_BITA  EQU    $17
OP_BITB  EQU    $18
OP_BLE   EQU    $19
OP_BLO   EQU    $1A
OP_BLS   EQU    $1B
OP_BLT   EQU    $1C
OP_BMI   EQU    $1D
OP_BNE   EQU    $1E
OP_BPL   EQU    $1F
OP_BRA   EQU    $20
OP_BRN   EQU    $21
OP_BSR   EQU    $22
OP_BVC   EQU    $23
OP_BVS   EQU    $24
OP_CLR   EQU    $25
OP_CLRA  EQU    $26
OP_CLRB  EQU    $27
OP_CMPA  EQU    $28
OP_CMPB  EQU    $29
OP_CMPD  EQU    $2A
OP_CMPS  EQU    $2B
OP_CMPU  EQU    $2C
OP_CMPX  EQU    $2D
OP_CMPY  EQU    $2E
OP_COMA  EQU    $2F
OP_COMB  EQU    $30
OP_CWAI  EQU    $31
OP_DAA   EQU    $32
OP_DEC   EQU    $33
OP_DECA  EQU    $34
OP_DECB  EQU    $35
OP_EORA  EQU    $36
OP_EORB  EQU    $37
OP_EXG   EQU    $38
OP_INC   EQU    $39
OP_INCA  EQU    $3A
OP_INCB  EQU    $3B
OP_JMP   EQU    $3C
OP_JSR   EQU    $3D
OP_LBCC  EQU    $3E
OP_LBCS  EQU    $3F
OP_LBEQ  EQU    $40
OP_LBGE  EQU    $41
OP_LBGT  EQU    $42
OP_LBHI  EQU    $43
OP_LBHS  EQU    $44
OP_LBLE  EQU    $45
OP_LBLO  EQU    $46
OP_LBLS  EQU    $47
OP_LBLT  EQU    $48
OP_LBMI  EQU    $49
OP_LBNE  EQU    $4A
OP_LBPL  EQU    $4B
OP_LBRA  EQU    $4C
OP_LBRN  EQU    $4D
OP_LBSR  EQU    $4E
OP_LBVC  EQU    $4F
OP_LBVS  EQU    $50
OP_LDA   EQU    $51
OP_LDB   EQU    $52
OP_LDD   EQU    $53
OP_LDS   EQU    $54
OP_LDU   EQU    $55
OP_LDX   EQU    $56
OP_LDY   EQU    $57
OP_LEAS  EQU    $58
OP_LEAU  EQU    $59
OP_LEAX  EQU    $5A
OP_LEAY  EQU    $5B
OP_LSL   EQU    $5C
OP_LSLA  EQU    $5D
OP_LSLB  EQU    $5E
OP_LSR   EQU    $5F
OP_LSRA  EQU    $60
OP_LSRB  EQU    $61
OP_MUL   EQU    $62
OP_NEG   EQU    $63
OP_NEGA  EQU    $64
OP_NEGB  EQU    $65
OP_NOP   EQU    $66
OP_ORA   EQU    $67
OP_ORB   EQU    $68
OP_ORCC  EQU    $69
OP_PSHS  EQU    $6A
OP_PSHU  EQU    $6B
OP_PULS  EQU    $6C
OP_PULU  EQU    $6D
OP_ROL   EQU    $6E
OP_ROLA  EQU    $6F
OP_ROLB  EQU    $70
OP_ROR   EQU    $71
OP_RORA  EQU    $72
OP_RORB  EQU    $73
OP_RTI   EQU    $74
OP_RTS   EQU    $75
OP_SBCA  EQU    $76
OP_SBCB  EQU    $77
OP_SEX   EQU    $78
OP_STA   EQU    $79
OP_STB   EQU    $7A
OP_STD   EQU    $7B
OP_STS   EQU    $7C
OP_STU   EQU    $7D
OP_STX   EQU    $7E
OP_STY   EQU    $7F
OP_SUBA  EQU    $80
OP_SUBB  EQU    $81
OP_SUBD  EQU    $82
OP_SWI   EQU    $83
OP_SWI2  EQU    $84
OP_SWI3  EQU    $85
OP_SYNC  EQU    $86
OP_TFR   EQU    $87
OP_TST   EQU    $88
OP_TSTA  EQU    $89
OP_TSTB  EQU    $8A

; Addressing Modes. OPCODES table lists these for each instruction.
; LENGTHS lists the instruction length for each addressing mode.
; Need to distinguish relative modes that are 2 and 3 (long) bytes.
; Some immediate are 2 and some 3 bytes.
; CWAI is only exception to inherent which is 2 bytes rather than 1.
; Indexed modes can be longer depending on postbyte.
; Page 2 and 3 opcodes are one byte longer (prefixed by 10 or 11)

AM_INVALID      EQU     0       ; $01 (1)
AM_INHERENT     EQU     1       ; RTS (1)
AM_INHERENT2    EQU     2       ; CWAI $AA (2)
AM_IMMEDIATE    EQU     3       ; LDA #$12 (2)
AM_IMMEDIATE2   EQU     4       ; LDD #$1234 (3)
AM_DIRECT       EQU     5       ; LDA $12 (2)
AM_EXTENDED     EQU     6       ; LDA $1234 (3)
AM_RELATIVE     EQU     7       ; BSR $1234 (2)
AM_RELATIVE2    EQU     8       ; LBSR $1234 (3)
AM_INDEXED      EQU     9       ; LDA 0,X (2+)

; *** CODE ***

; Main program, for test purposes.

MAIN:   LDX     #MAIN           ; Address to start disassembly (here)
        STX     ADDR            ; Store it
DIS:    JSR     DISASM          ; Do disassembly of one instruction
        BRA     DIS             ; Go back and repeat

; *** Utility Functions ***
; Some of these call ASSIST09 ROM monitor routines.

; Print CR/LF to the console.
; Registers affected: none
PrintCR:
        PSHS    A               ; Save A
        LDA     #CR
        JSR     PrintChar
        LDA     #LF
        JSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print dollar sign to the console.
; Registers affected: none
PrintDollar:
        PSHS    A               ; Save A
        LDA     #'$
        JSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print space sign to the console.
; Registers affected: none
PrintSpace:
        PSHS    A               ; Save A
        LDA     #SP
        JSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print several space characters.
; A contains number of spaces to print.
; Registers affected: none
PrintSpaces:
        PSHS    A               ; Save registers used
PS1:    CMPA    #0              ; Is count zero?
        BEQ     PS2             ; Is so, done
        JSR     PrintSpace      ; Print a space
        DECA                    ; Decrement count
        BRA     PS1             ; Check again
PS2:    PULS    A               ; Restore registers used
        RTS

; Print character to the console
; A contains character to print.
; Registers affected: none
PrintChar:
        SWI                     ; Call ASSIST09 monitor function
        FCB     OUTCH           ; Service code byte
        RTS

; Print a byte as two hex digits followed by a space.
; A contains byte to print.
; Registers affected: none
PrintByte:
        PSHS    A,B,X           ; Save registers used
        STA     TEMP            ; Needs to be in memory so we can point to it
        LEAX    TEMP,PCR        ; Get pointer to it
        SWI                     ; Call ASSIST09 monitor function
        FCB     OUT2HS          ; Service code byte
        PULS    X,B,A           ; Restore registers used
        RTS

; Print a word as four hex digits followed by a space.
; X contains word to print.
; Registers affected: none
PrintAddress:
        PSHS    A,B,X           ; Save registers used
        STX     TEMP            ; Needs to be in memory so we can point to it
        LEAX    TEMP,PCR        ; Get pointer to it
        SWI                     ; Call ASSIST09 monitor function
        FCB     OUT4HS          ; Service code byte
        PULS    X,B,A           ; Restore registers used
        RTS

; Disassemble instruction at address ADDR. On return, ADDR points to
; next instruction so it can be called again.
; Typical output:
;
;1237  12           NOP
;1238  86 55        LDA   #$55
;1234  1A 00        ORCC  #$00
;1234  7E 12 34     JMP   $1234
;123A  10 FF 12 34  STS   $1234
;101C  A6 8D 02 14  LDA   $1234,PCR
;1020  A6 9F 12 34  LDA   [$1234]

DISASM: LDX     ADDR           ; Get address of instruction
        LDB     ,X             ; Get instruction op code
        STB     OPCODE         ; Save the op code

        CLRA                   ; Clear MSB of D
        TFR     D,X            ; Put op code in X
        LDB     OPCODES,X      ; Get opcode type from table
                               ; TODO: Handle page 2/3 16-bit opcodes prefixed with 10/11
        STB     OPTYPE         ; Store it
        LDB     OPCODE         ; Get op code again
        TFR     D,X            ; Put opcode in X
        LDB     MODES,X        ; Get addressing mode type from table
        STB     AM             ; Store it
        TFR     D,X            ; Put addressing mode in X
        LDB     LENGTHS,X      ; Get instruction length from table
                               ; TODO: Adjust length for possible indexed addressing
        STB     LEN            ; Store it

; Print address followed by a space
        LDX     ADDR
        JSR     PrintAddress
        
; Print one more space

        JSR     PrintSpace

; Print the op code bytes based on the instruction length

        LDB     LEN             ; Number of bytes in instruction
        LDX     ADDR            ; Pointer to start of instruction
opby:   LDA     ,X+             ; Get instruction byte and increment pointer
        JSR     PrintByte       ; Print it, followed by a space
        DECB                    ; Decrement byte count
        BNE     opby            ; Repeat until done

; Print needed remaining spaces to pad out to correct column

        LDX     #PADDING        ; Pointer to start of lookup table
        LDA     LEN             ; Number of bytes in instruction
        DECA                    ; Subtract 1 since table starts at 1, not 0
        LDA     A,X             ; Get number of spaces to print
        JSR     PrintSpaces

; Get the mnemonic

; Print mnemonic (4 chars)

        LDB     OPTYPE          ; Get instruction type to index into table
        LDA     #4              ; Want to multiply by 4
        MUL                     ; Multiply, result in D
        LDX     #MNEMONICS      ; Pointer to start of table
        STA     TEMP1           ; Save value of A
        LDA     D,X             ; Get first char of mnemonic
        JSR     PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get second char of mnemonic
        JSR     PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get third char of mnemonic
        JSR     PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get fourth char of mnemonic
        JSR     PrintChar       ; Print it

; Display any operands based on addressing mode

; Print final CR

        JSR     PrintCR

; Update address to next instruction

        CLRA                    ; Clear MSB of D
        LDB     LEN             ; Get length byte in LSB of D
        ADDD    ADDR            ; Add to address
        STD     ADDR            ; Write new address

; Return
        RTS

; *** DATA

; Table of instruction strings. 4 bytes per table entry
MNEMONICS:
        FCC     "??? "          ; $00
        FCC     "ABX "          ; $01
        FCC     "ADCA"          ; $02
        FCC     "ADCB"          ; $03
        FCC     "ADDA"          ; $04
        FCC     "ADDB"          ; $05
        FCC     "ADDD"          ; $06
        FCC     "ANDA"          ; $07
        FCC     "ANDB"          ; $08
        FCC     "ANDC"          ; $09 Should really  be "ANDCC" 
        FCC     "ASL "          ; $0A
        FCC     "ASLA"          ; $0B
        FCC     "ASLB"          ; $0C
        FCC     "ASR "          ; $0D
        FCC     "ASRA"          ; $0E
        FCC     "ASRB"          ; $0F
        FCC     "BCC "          ; $10
        FCC     "BCS "          ; $11
        FCC     "BEQ "          ; $12
        FCC     "BGE "          ; $13
        FCC     "BGT "          ; $14
        FCC     "BHI "          ; $15
        FCC     "BHS "          ; $16
        FCC     "BITA"          ; $17
        FCC     "BITB"          ; $18
        FCC     "BLE "          ; $19
        FCC     "BLO "          ; $1A
        FCC     "BLS "          ; $1B
        FCC     "BLT "          ; $1C
        FCC     "BMI "          ; $1D
        FCC     "BNE "          ; $1E
        FCC     "BPL "          ; $1F
        FCC     "BRA "          ; $20
        FCC     "BRN "          ; $21
        FCC     "BSR "          ; $22
        FCC     "BVC "          ; $23
        FCC     "BVS "          ; $24
        FCC     "CLR "          ; $25
        FCC     "CLRA"          ; $26
        FCC     "CLRB"          ; $27
        FCC     "CMPA"          ; $28
        FCC     "CMPB"          ; $29
        FCC     "CMPD"          ; $2A
        FCC     "CMPS"          ; $2B
        FCC     "CMPU"          ; $2C
        FCC     "CMPX"          ; $2D
        FCC     "CMPY"          ; $2E
        FCC     "COMA"          ; $2F
        FCC     "COMB"          ; $30
        FCC     "CWAI"          ; $31
        FCC     "DAA "          ; $32
        FCC     "DEC "          ; $33
        FCC     "DECA"          ; $34
        FCC     "DECB"          ; $35
        FCC     "EORA"          ; $36
        FCC     "EORB"          ; $37
        FCC     "EXG "          ; $38
        FCC     "INC "          ; $39
        FCC     "INCA"          ; $3A
        FCC     "INCB"          ; $3B
        FCC     "JMP "          ; $3C
        FCC     "JSR "          ; $3D
        FCC     "LBCC"          ; $3E
        FCC     "LBCS"          ; $3F
        FCC     "LBEQ"          ; $40
        FCC     "LBGE"          ; $41
        FCC     "LBGT"          ; $42
        FCC     "LBHI"          ; $43
        FCC     "LBHS"          ; $44
        FCC     "LBLE"          ; $45
        FCC     "LBLO"          ; $46
        FCC     "LBLS"          ; $47
        FCC     "LBLT"          ; $48
        FCC     "LBMI"          ; $49
        FCC     "LBNE"          ; $4A
        FCC     "LBPL"          ; $4B
        FCC     "LBRA"          ; $4C
        FCC     "LBRN"          ; $4D
        FCC     "LBSR"          ; $4E
        FCC     "LBVC"          ; $4F
        FCC     "LBVS"          ; $50
        FCC     "LDA "          ; $51
        FCC     "LDB "          ; $52
        FCC     "LDD "          ; $53
        FCC     "LDS "          ; $54
        FCC     "LDU "          ; $55
        FCC     "LDX "          ; $56
        FCC     "LDY "          ; $57
        FCC     "LEAS"          ; $58
        FCC     "LEAU"          ; $59
        FCC     "LEAX"          ; $5A
        FCC     "LEAY"          ; $5B
        FCC     "LSL "          ; $5C
        FCC     "LSLA"          ; $5C
        FCC     "LSLB"          ; $5E
        FCC     "LSR "          ; $5F
        FCC     "LSRA"          ; $60
        FCC     "LSRB"          ; $61
        FCC     "MUL "          ; $62
        FCC     "NEG "          ; $63
        FCC     "NEGA"          ; $64
        FCC     "NEGB"          ; $65
        FCC     "NOP "          ; $66
        FCC     "ORA "          ; $67
        FCC     "ORB "          ; $68
        FCC     "ORCC"          ; $69
        FCC     "PSHS"          ; $6A
        FCC     "PSHU"          ; $6B
        FCC     "PULS"          ; $6C
        FCC     "PULU"          ; $6D
        FCC     "ROL "          ; $6E
        FCC     "ROLA"          ; $6F
        FCC     "ROLB"          ; $70
        FCC     "ROR "          ; $71
        FCC     "RORA"          ; $72
        FCC     "RORB"          ; $73
        FCC     "RTI "          ; $74
        FCC     "RTS "          ; $75
        FCC     "SBCA"          ; $76
        FCC     "SBCB"          ; $77
        FCC     "SEX "          ; $78
        FCC     "STA "          ; $79
        FCC     "STB "          ; $7A
        FCC     "STD "          ; $7B
        FCC     "STS "          ; $7C
        FCC     "STU "          ; $7D
        FCC     "STX "          ; $7E
        FCC     "STY "          ; $7F
        FCC     "SUBA"          ; $80
        FCC     "SUBB"          ; $81
        FCC     "SUBD"          ; $82
        FCC     "SWI "          ; $83
        FCC     "SWI2"          ; $84
        FCC     "SWI3"          ; $85
        FCC     "SYNC"          ; $86
        FCC     "TFR "          ; $87
        FCC     "TST "          ; $88
        FCC     "TSTA"          ; $89
        FCC     "TSTB"          ; $8A

; Lengths of instructions given an addressing mode. Matches values of
; AM_* Indexed addessing instructions lenth can increase due to post
; byte.
LENGTHS:
        FCB     1               ; 0 AM_INVALID
        FCB     1               ; 1 AM_INHERENT
        FCB     2               ; 2 AM_INHERENT2
        FCB     2               ; 3 AM_IMMEDIATE
        FCB     3               ; 4 AM_IMMEDIATE2
        FCB     2               ; 5 AM_DIRECT
        FCB     3               ; 6 AM_EXTENDED
        FCB     2               ; 7 AM_RELATIVE
        FCB     3               ; 8 AM_RELATIVE2
        FCB     2               ; 9 AM_INDEXED

; Lookup table to return needed remaining spaces to print to pad out
; instruction to correct column in disassembly.
; # bytes: 1 2 3 4
; Padding: 9 6 3 1
PADDING:
        FCB     9, 6, 3, 1

; Opcodes. Listed in order indexed by op code. Defines the mnemonic.
OPCODES:
        FCB     OP_NEG          ; 00
        FCB     OP_INV          ; 01
        FCB     OP_INV          ; 02
        FCB     OP_COMB         ; 03
        FCB     OP_LSR          ; 04
        FCB     OP_INV          ; 05
        FCB     OP_ROR          ; 06
        FCB     OP_ASR          ; 07
        FCB     OP_ASL          ; 08 OR LSL
        FCB     OP_ROL          ; 09
        FCB     OP_DEC          ; 0A
        FCB     OP_INV          ; 0B
        FCB     OP_INC          ; 0C
        FCB     OP_TST          ; 0D
        FCB     OP_JMP          ; 0E
        FCB     OP_CLR          ; 0F

        FCB     OP_INV          ; 10 Page 2 extended opcodes (see other table)
        FCB     OP_INV          ; 11 Page 3 extended opcodes (see other table)
        FCB     OP_NOP          ; 12
        FCB     OP_SYNC         ; 13
        FCB     OP_INV          ; 14
        FCB     OP_INV          ; 15
        FCB     OP_LBRA         ; 16
        FCB     OP_LBSR         ; 17
        FCB     OP_INV          ; 18
        FCB     OP_DAA          ; 19
        FCB     OP_ORCC         ; 1A
        FCB     OP_INV          ; 1B
        FCB     OP_ANDCC        ; 1C
        FCB     OP_SEX          ; 1D
        FCB     OP_EXG          ; 1E
        FCB     OP_TFR          ; 1F

        FCB     OP_BRA          ; 20
        FCB     OP_INV          ; 21
        FCB     OP_INV          ; 22
        FCB     OP_INV          ; 23
        FCB     OP_INV          ; 24
        FCB     OP_INV          ; 25
        FCB     OP_INV          ; 26
        FCB     OP_INV          ; 27
        FCB     OP_INV          ; 28
        FCB     OP_INV          ; 29
        FCB     OP_INV          ; 2A
        FCB     OP_INV          ; 2B
        FCB     OP_INV          ; 2C
        FCB     OP_INV          ; 2D
        FCB     OP_INV          ; 2E
        FCB     OP_INV          ; 2F

        FCB     OP_INV          ; 30
        FCB     OP_INV          ; 31
        FCB     OP_INV          ; 32
        FCB     OP_INV          ; 33
        FCB     OP_INV          ; 34
        FCB     OP_INV          ; 35
        FCB     OP_INV          ; 36
        FCB     OP_INV          ; 37
        FCB     OP_INV          ; 38
        FCB     OP_INV          ; 39
        FCB     OP_INV          ; 3A
        FCB     OP_INV          ; 3B
        FCB     OP_INV          ; 3C
        FCB     OP_INV          ; 3D
        FCB     OP_INV          ; 3E
        FCB     OP_INV          ; 3F

        FCB     OP_INV          ; 40
        FCB     OP_INV          ; 41
        FCB     OP_INV          ; 42
        FCB     OP_INV          ; 43
        FCB     OP_INV          ; 44
        FCB     OP_INV          ; 45
        FCB     OP_INV          ; 46
        FCB     OP_INV          ; 47
        FCB     OP_INV          ; 48
        FCB     OP_INV          ; 49
        FCB     OP_INV          ; 4A
        FCB     OP_INV          ; 4B
        FCB     OP_INV          ; 4C
        FCB     OP_INV          ; 4D
        FCB     OP_INV          ; 4E
        FCB     OP_INV          ; 4F

        FCB     OP_INV          ; 50
        FCB     OP_INV          ; 51
        FCB     OP_INV          ; 52
        FCB     OP_INV          ; 53
        FCB     OP_INV          ; 54
        FCB     OP_INV          ; 55
        FCB     OP_INV          ; 56
        FCB     OP_INV          ; 57
        FCB     OP_INV          ; 58
        FCB     OP_INV          ; 59
        FCB     OP_INV          ; 5A
        FCB     OP_INV          ; 5B
        FCB     OP_INV          ; 5C
        FCB     OP_INV          ; 5D
        FCB     OP_INV          ; 5E
        FCB     OP_INV          ; 5F

        FCB     OP_INV          ; 60
        FCB     OP_INV          ; 61
        FCB     OP_INV          ; 62
        FCB     OP_INV          ; 63
        FCB     OP_INV          ; 64
        FCB     OP_INV          ; 65
        FCB     OP_INV          ; 66
        FCB     OP_INV          ; 67
        FCB     OP_INV          ; 68
        FCB     OP_INV          ; 69
        FCB     OP_INV          ; 6A
        FCB     OP_INV          ; 6B
        FCB     OP_INV          ; 6C
        FCB     OP_INV          ; 6D
        FCB     OP_INV          ; 6E
        FCB     OP_INV          ; 6F

        FCB     OP_INV          ; 70
        FCB     OP_INV          ; 71
        FCB     OP_INV          ; 72
        FCB     OP_INV          ; 73
        FCB     OP_INV          ; 74
        FCB     OP_INV          ; 75
        FCB     OP_INV          ; 76
        FCB     OP_INV          ; 77
        FCB     OP_INV          ; 78
        FCB     OP_INV          ; 79
        FCB     OP_INV          ; 7A
        FCB     OP_INV          ; 7B
        FCB     OP_INV          ; 7C
        FCB     OP_INV          ; 7D
        FCB     OP_INV          ; 7E
        FCB     OP_INV          ; 7F

        FCB     OP_INV          ; 80
        FCB     OP_INV          ; 81
        FCB     OP_INV          ; 82
        FCB     OP_INV          ; 83
        FCB     OP_INV          ; 84
        FCB     OP_INV          ; 85
        FCB     OP_INV          ; 86
        FCB     OP_INV          ; 87
        FCB     OP_INV          ; 88
        FCB     OP_INV          ; 89
        FCB     OP_INV          ; 8A
        FCB     OP_INV          ; 8B
        FCB     OP_INV          ; 8C
        FCB     OP_INV          ; 8D
        FCB     OP_LDX          ; 8E
        FCB     OP_INV          ; 8F

        FCB     OP_INV          ; 90
        FCB     OP_INV          ; 91
        FCB     OP_INV          ; 92
        FCB     OP_INV          ; 93
        FCB     OP_INV          ; 94
        FCB     OP_INV          ; 95
        FCB     OP_INV          ; 96
        FCB     OP_INV          ; 97
        FCB     OP_INV          ; 98
        FCB     OP_INV          ; 99
        FCB     OP_INV          ; 9A
        FCB     OP_INV          ; 9B
        FCB     OP_INV          ; 9C
        FCB     OP_INV          ; 9D
        FCB     OP_INV          ; 9E
        FCB     OP_INV          ; 9F

        FCB     OP_INV          ; A0
        FCB     OP_INV          ; A1
        FCB     OP_INV          ; A2
        FCB     OP_INV          ; A3
        FCB     OP_INV          ; A4
        FCB     OP_INV          ; A5
        FCB     OP_INV          ; A6
        FCB     OP_INV          ; A7
        FCB     OP_INV          ; A8
        FCB     OP_INV          ; A9
        FCB     OP_INV          ; AA
        FCB     OP_INV          ; AB
        FCB     OP_INV          ; AC
        FCB     OP_INV          ; AD
        FCB     OP_INV          ; AE
        FCB     OP_INV          ; AF

        FCB     OP_INV          ; B0
        FCB     OP_INV          ; B1
        FCB     OP_INV          ; B2
        FCB     OP_INV          ; B3
        FCB     OP_INV          ; B4
        FCB     OP_INV          ; B5
        FCB     OP_INV          ; B6
        FCB     OP_INV          ; B7
        FCB     OP_INV          ; B8
        FCB     OP_INV          ; B9
        FCB     OP_INV          ; BA
        FCB     OP_INV          ; BB
        FCB     OP_INV          ; BC
        FCB     OP_JSR          ; BD
        FCB     OP_INV          ; BE
        FCB     OP_STX          ; BF

        FCB     OP_INV          ; C0
        FCB     OP_INV          ; C1
        FCB     OP_INV          ; C2
        FCB     OP_INV          ; C3
        FCB     OP_INV          ; C4
        FCB     OP_INV          ; C5
        FCB     OP_INV          ; C6
        FCB     OP_INV          ; C7
        FCB     OP_INV          ; C8
        FCB     OP_INV          ; C9
        FCB     OP_INV          ; CA
        FCB     OP_INV          ; CB
        FCB     OP_INV          ; CC
        FCB     OP_INV          ; CD
        FCB     OP_INV          ; CE
        FCB     OP_INV          ; CF

        FCB     OP_INV          ; D0
        FCB     OP_INV          ; D1
        FCB     OP_INV          ; D2
        FCB     OP_INV          ; D3
        FCB     OP_INV          ; D4
        FCB     OP_INV          ; D5
        FCB     OP_INV          ; D6
        FCB     OP_INV          ; D7
        FCB     OP_INV          ; D8
        FCB     OP_INV          ; D9
        FCB     OP_INV          ; DA
        FCB     OP_INV          ; DB
        FCB     OP_INV          ; DC
        FCB     OP_INV          ; DD
        FCB     OP_INV          ; DE
        FCB     OP_INV          ; DF

        FCB     OP_INV          ; E0
        FCB     OP_INV          ; E1
        FCB     OP_INV          ; E2
        FCB     OP_INV          ; E3
        FCB     OP_INV          ; E4
        FCB     OP_INV          ; E5
        FCB     OP_INV          ; E6
        FCB     OP_INV          ; E7
        FCB     OP_INV          ; E8
        FCB     OP_INV          ; E9
        FCB     OP_INV          ; EA
        FCB     OP_INV          ; EB
        FCB     OP_INV          ; EC
        FCB     OP_INV          ; ED
        FCB     OP_INV          ; EE
        FCB     OP_INV          ; EF

        FCB     OP_INV          ; F0
        FCB     OP_INV          ; F1
        FCB     OP_INV          ; F2
        FCB     OP_INV          ; F3
        FCB     OP_INV          ; F4
        FCB     OP_INV          ; F5
        FCB     OP_INV          ; F6
        FCB     OP_INV          ; F7
        FCB     OP_INV          ; F8
        FCB     OP_INV          ; F9
        FCB     OP_INV          ; FA
        FCB     OP_INV          ; FB
        FCB     OP_INV          ; FC
        FCB     OP_INV          ; FD
        FCB     OP_INV          ; FE
        FCB     OP_INV          ; FF

; Table of addressing modes. Listed in order indexed by op code.
MODES:
        FCB     AM_DIRECT       ; 00
        FCB     AM_INHERENT     ; 01
        FCB     AM_INHERENT     ; 02
        FCB     AM_DIRECT       ; 03
        FCB     AM_DIRECT       ; 04
        FCB     AM_DIRECT       ; 05
        FCB     AM_DIRECT       ; 06
        FCB     AM_DIRECT       ; 07
        FCB     AM_DIRECT       ; 08
        FCB     AM_DIRECT       ; 09
        FCB     AM_DIRECT       ; 0A
        FCB     AM_DIRECT       ; 0B
        FCB     AM_DIRECT       ; 0C
        FCB     AM_DIRECT       ; 0D
        FCB     AM_DIRECT       ; 0E
        FCB     AM_DIRECT       ; 0F

        FCB     AM_INHERENT     ; 10 Page 2 extended opcodes (see other table)
        FCB     AM_INHERENT     ; 11 Page 3 extended opcodes (see other table)
        FCB     AM_INHERENT     ; 12
        FCB     AM_INHERENT     ; 13
        FCB     AM_DIRECT       ; 14
        FCB     AM_DIRECT       ; 15
        FCB     AM_RELATIVE2    ; 16
        FCB     AM_RELATIVE2    ; 17
        FCB     AM_DIRECT       ; 18
        FCB     AM_INHERENT     ; 19
        FCB     AM_IMMEDIATE    ; 1A
        FCB     AM_DIRECT       ; 1B
        FCB     AM_IMMEDIATE    ; 1C
        FCB     AM_INHERENT     ; 1D
        FCB     AM_IMMEDIATE    ; 1E
        FCB     AM_IMMEDIATE    ; 1F

        FCB     AM_RELATIVE     ; 20
        FCB     AM_INHERENT     ; 21
        FCB     AM_INHERENT     ; 22
        FCB     AM_INHERENT     ; 23
        FCB     AM_INHERENT     ; 24
        FCB     AM_INHERENT     ; 25
        FCB     AM_INHERENT     ; 26
        FCB     AM_INHERENT     ; 27
        FCB     AM_INHERENT     ; 28
        FCB     AM_INHERENT     ; 29
        FCB     AM_INHERENT     ; 2A
        FCB     AM_INHERENT     ; 2B
        FCB     AM_INHERENT     ; 2C
        FCB     AM_INHERENT     ; 2D
        FCB     AM_INHERENT     ; 2E
        FCB     AM_INHERENT     ; 2F

        FCB     AM_INHERENT     ; 30
        FCB     AM_INHERENT     ; 31
        FCB     AM_INHERENT     ; 32
        FCB     AM_INHERENT     ; 33
        FCB     AM_INHERENT     ; 34
        FCB     AM_INHERENT     ; 35
        FCB     AM_INHERENT     ; 36
        FCB     AM_INHERENT     ; 37
        FCB     AM_INHERENT     ; 38
        FCB     AM_INHERENT     ; 39
        FCB     AM_INHERENT     ; 3A
        FCB     AM_INHERENT     ; 3B
        FCB     AM_INHERENT     ; 3C
        FCB     AM_INHERENT     ; 3D
        FCB     AM_INHERENT     ; 3E
        FCB     AM_INHERENT     ; 3F

        FCB     AM_INHERENT     ; 40
        FCB     AM_INHERENT     ; 41
        FCB     AM_INHERENT     ; 42
        FCB     AM_INHERENT     ; 43
        FCB     AM_INHERENT     ; 44
        FCB     AM_INHERENT     ; 45
        FCB     AM_INHERENT     ; 46
        FCB     AM_INHERENT     ; 47
        FCB     AM_INHERENT     ; 48
        FCB     AM_INHERENT     ; 49
        FCB     AM_INHERENT     ; 4A
        FCB     AM_INHERENT     ; 4B
        FCB     AM_INHERENT     ; 4C
        FCB     AM_INHERENT     ; 4D
        FCB     AM_INHERENT     ; 4E
        FCB     AM_INHERENT     ; 4F


        FCB     AM_INHERENT     ; 50
        FCB     AM_INHERENT     ; 51
        FCB     AM_INHERENT     ; 52
        FCB     AM_INHERENT     ; 53
        FCB     AM_INHERENT     ; 54
        FCB     AM_INHERENT     ; 55
        FCB     AM_INHERENT     ; 56
        FCB     AM_INHERENT     ; 57
        FCB     AM_INHERENT     ; 58
        FCB     AM_INHERENT     ; 59
        FCB     AM_INHERENT     ; 5A
        FCB     AM_INHERENT     ; 5B
        FCB     AM_INHERENT     ; 5C
        FCB     AM_INHERENT     ; 5D
        FCB     AM_INHERENT     ; 5E
        FCB     AM_INHERENT     ; 5F


        FCB     AM_INHERENT     ; 60
        FCB     AM_INHERENT     ; 61
        FCB     AM_INHERENT     ; 62
        FCB     AM_INHERENT     ; 63
        FCB     AM_INHERENT     ; 64
        FCB     AM_INHERENT     ; 65
        FCB     AM_INHERENT     ; 66
        FCB     AM_INHERENT     ; 67
        FCB     AM_INHERENT     ; 68
        FCB     AM_INHERENT     ; 69
        FCB     AM_INHERENT     ; 6A
        FCB     AM_INHERENT     ; 6B
        FCB     AM_INHERENT     ; 6C
        FCB     AM_INHERENT     ; 6D
        FCB     AM_INHERENT     ; 6E
        FCB     AM_INHERENT     ; 6F


        FCB     AM_INHERENT     ; 70
        FCB     AM_INHERENT     ; 71
        FCB     AM_INHERENT     ; 72
        FCB     AM_INHERENT     ; 73
        FCB     AM_INHERENT     ; 74
        FCB     AM_INHERENT     ; 75
        FCB     AM_INHERENT     ; 76
        FCB     AM_INHERENT     ; 77
        FCB     AM_INHERENT     ; 78
        FCB     AM_INHERENT     ; 79
        FCB     AM_INHERENT     ; 7A
        FCB     AM_INHERENT     ; 7B
        FCB     AM_INHERENT     ; 7C
        FCB     AM_INHERENT     ; 7D
        FCB     AM_INHERENT     ; 7E
        FCB     AM_INHERENT     ; 7F


        FCB     AM_INHERENT     ; 80
        FCB     AM_INHERENT     ; 81
        FCB     AM_INHERENT     ; 82
        FCB     AM_INHERENT     ; 83
        FCB     AM_INHERENT     ; 84
        FCB     AM_INHERENT     ; 85
        FCB     AM_INHERENT     ; 86
        FCB     AM_INHERENT     ; 87
        FCB     AM_INHERENT     ; 88
        FCB     AM_INHERENT     ; 89
        FCB     AM_INHERENT     ; 8A
        FCB     AM_INHERENT     ; 8B
        FCB     AM_INHERENT     ; 8C
        FCB     AM_INHERENT     ; 8D
        FCB     AM_IMMEDIATE2   ; 8E
        FCB     AM_INHERENT     ; 8F


        FCB     AM_INHERENT     ; 90
        FCB     AM_INHERENT     ; 91
        FCB     AM_INHERENT     ; 92
        FCB     AM_INHERENT     ; 93
        FCB     AM_INHERENT     ; 94
        FCB     AM_INHERENT     ; 95
        FCB     AM_INHERENT     ; 96
        FCB     AM_INHERENT     ; 97
        FCB     AM_INHERENT     ; 98
        FCB     AM_INHERENT     ; 99
        FCB     AM_INHERENT     ; 9A
        FCB     AM_INHERENT     ; 9B
        FCB     AM_INHERENT     ; 9C
        FCB     AM_INHERENT     ; 9D
        FCB     AM_INHERENT     ; 9E
        FCB     AM_INHERENT     ; 9F


        FCB     AM_INHERENT     ; A0
        FCB     AM_INHERENT     ; A1
        FCB     AM_INHERENT     ; A2
        FCB     AM_INHERENT     ; A3
        FCB     AM_INHERENT     ; A4
        FCB     AM_INHERENT     ; A5
        FCB     AM_INHERENT     ; A6
        FCB     AM_INHERENT     ; A7
        FCB     AM_INHERENT     ; A8
        FCB     AM_INHERENT     ; A9
        FCB     AM_INHERENT     ; AA
        FCB     AM_INHERENT     ; AB
        FCB     AM_INHERENT     ; AC
        FCB     AM_INHERENT     ; AD
        FCB     AM_INHERENT     ; AE
        FCB     AM_INHERENT     ; AF


        FCB     AM_INHERENT     ; B0
        FCB     AM_INHERENT     ; B1
        FCB     AM_INHERENT     ; B2
        FCB     AM_INHERENT     ; B3
        FCB     AM_INHERENT     ; B4
        FCB     AM_INHERENT     ; B5
        FCB     AM_INHERENT     ; B6
        FCB     AM_INHERENT     ; B7
        FCB     AM_INHERENT     ; B8
        FCB     AM_INHERENT     ; B9
        FCB     AM_INHERENT     ; BA
        FCB     AM_INHERENT     ; BB
        FCB     AM_INHERENT     ; BC
        FCB     AM_EXTENDED     ; BD
        FCB     AM_INHERENT     ; BE
        FCB     AM_EXTENDED     ; BF


        FCB     AM_INHERENT     ; C0
        FCB     AM_INHERENT     ; C1
        FCB     AM_INHERENT     ; C2
        FCB     AM_INHERENT     ; C3
        FCB     AM_INHERENT     ; C4
        FCB     AM_INHERENT     ; C5
        FCB     AM_INHERENT     ; C6
        FCB     AM_INHERENT     ; C7
        FCB     AM_INHERENT     ; C8
        FCB     AM_INHERENT     ; C9
        FCB     AM_INHERENT     ; CA
        FCB     AM_INHERENT     ; CB
        FCB     AM_INHERENT     ; CC
        FCB     AM_INHERENT     ; CD
        FCB     AM_INHERENT     ; CE
        FCB     AM_INHERENT     ; CF


        FCB     AM_INHERENT     ; D0
        FCB     AM_INHERENT     ; D1
        FCB     AM_INHERENT     ; D2
        FCB     AM_INHERENT     ; D3
        FCB     AM_INHERENT     ; D4
        FCB     AM_INHERENT     ; D5
        FCB     AM_INHERENT     ; D6
        FCB     AM_INHERENT     ; D7
        FCB     AM_INHERENT     ; D8
        FCB     AM_INHERENT     ; D9
        FCB     AM_INHERENT     ; DA
        FCB     AM_INHERENT     ; DB
        FCB     AM_INHERENT     ; DC
        FCB     AM_INHERENT     ; DD
        FCB     AM_INHERENT     ; DE
        FCB     AM_INHERENT     ; DF


        FCB     AM_INHERENT     ; E0
        FCB     AM_INHERENT     ; E1
        FCB     AM_INHERENT     ; E2
        FCB     AM_INHERENT     ; E3
        FCB     AM_INHERENT     ; E4
        FCB     AM_INHERENT     ; E5
        FCB     AM_INHERENT     ; E6
        FCB     AM_INHERENT     ; E7
        FCB     AM_INHERENT     ; E8
        FCB     AM_INHERENT     ; E9
        FCB     AM_INHERENT     ; EA
        FCB     AM_INHERENT     ; EB
        FCB     AM_INHERENT     ; EC
        FCB     AM_INHERENT     ; ED
        FCB     AM_INHERENT     ; EE
        FCB     AM_INHERENT     ; EF


        FCB     AM_INHERENT     ; F0
        FCB     AM_INHERENT     ; F1
        FCB     AM_INHERENT     ; F2
        FCB     AM_INHERENT     ; F3
        FCB     AM_INHERENT     ; F4
        FCB     AM_INHERENT     ; F5
        FCB     AM_INHERENT     ; F6
        FCB     AM_INHERENT     ; F7
        FCB     AM_INHERENT     ; F8
        FCB     AM_INHERENT     ; F9
        FCB     AM_INHERENT     ; FA
        FCB     AM_INHERENT     ; FB
        FCB     AM_INHERENT     ; FC
        FCB     AM_INHERENT     ; FD
        FCB     AM_INHERENT     ; FE
        FCB     AM_INHERENT     ; FF

; Special table for page 2 instructions prefixed by $10.

;0x1021 :  [ 4, "lbrn", "rel16", pcr      ],
;0x1022 :  [ 4, "lbhi", "rel16", pcr      ],
;0x1023 :  [ 4, "lbls", "rel16", pcr      ],
;0x1024 :  [ 4, "lbcc", "rel16", pcr      ],
;0x1024 :  [ 4, "lbhs", "rel16", pcr      ],
;0x1025 :  [ 4, "lbcs", "rel16", pcr      ],
;0x1025 :  [ 4, "lblo", "rel16", pcr      ],
;0x1026 :  [ 4, "lbne", "rel16", pcr      ],
;0x1027 :  [ 4, "lbeq", "rel16", pcr      ],
;0x1028 :  [ 4, "lbvc", "rel16", pcr      ],
;0x1029 :  [ 4, "lbvs", "rel16", pcr      ],
;0x102a :  [ 4, "lbpl", "rel16", pcr      ],
;0x102b :  [ 4, "lbmi", "rel16", pcr      ],
;0x102c :  [ 4, "lbge", "rel16", pcr      ],
;0x102d :  [ 4, "lblt", "rel16", pcr      ],
;0x102e :  [ 4, "lbgt", "rel16", pcr      ],
;0x102f :  [ 4, "lble", "rel16", pcr      ],
;0x103f :  [ 2, "swi2", "inherent"        ],
;0x1083 :  [ 4, "cmpd", "imm16"           ],
;0x108c :  [ 4, "cmpy", "imm16"           ],
;0x108e :  [ 4, "ldy",  "imm16"           ],
;0x1093 :  [ 3, "cmpd", "direct"          ],
;0x109c :  [ 3, "cmpy", "direct"          ],
;0x109e :  [ 3, "ldy",  "direct"          ],
;0x109f :  [ 3, "sty",  "direct"          ],
;0x10a3 :  [ 3, "cmpd", "indexed"         ],
;0x10ac :  [ 3, "cmpy", "indexed"         ],
;0x10ae :  [ 3, "ldy",  "indexed"         ],
;0x10af :  [ 3, "sty",  "indexed"         ],
;0x10b3 :  [ 4, "cmpd", "extended"        ],
;0x10bc :  [ 4, "cmpy", "extended"        ],
;0x10be :  [ 4, "ldy",  "extended"        ],
;0x10bf :  [ 4, "sty",  "extended"        ],
;0x10ce :  [ 4, "lds",  "imm16"           ],
;0x10de :  [ 3, "lds",  "direct"          ],
;0x10df :  [ 3, "sts",  "direct"          ],
;0x10ee :  [ 3, "lds",  "indexed"         ],
;0x10ef :  [ 3, "sts",  "indexed"         ],
;0x10fe :  [ 4, "lds",  "extended"        ],
;0x10ff :  [ 4, "sts",  "extended"        ],

; Special table for page 3 instructions prefixed by $11.

;0x113f :  [ 2, "swi3", "inherent"        ],
;0x1183 :  [ 4, "cmpu", "imm16"           ],
;0x118c :  [ 4, "cmps", "imm16"           ],
;0x1193 :  [ 3, "cmpu", "direct"          ],
;0x119c :  [ 3, "cmps", "direct"          ],
;0x11a3 :  [ 3, "cmpu", "indexed"         ],
;0x11ac :  [ 3, "cmps", "indexed"         ],
;0x11b3 :  [ 4, "cmpu", "extended"        ],
;0x11bc :  [ 4, "cmps", "extended"        ],
