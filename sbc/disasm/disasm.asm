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

; To DO:
; - implement relative
; - rename IMMEDIATE, IMMEDIATE2 to IMMEDIATE8, IMMEDIATE16
; - implement relative2
; - general check of instruction output
; - implement a couple of common indexed addressing modes
; - handle operands for PSHU/PSHS/PULU/PULS
; - handle operands for TFF/EXG
; - handle 10/11 instructions
; - other TODOs in code
; - more indexed addressing modes
; - add keyboard input to continue/cancel a page of disassembly
; - implement all remaining addressing modes
; - do comprehensive check of instruction output
; - make code position independent
; - hook up as external command to ASSIST09
; - add option to suppress data bytes in output (for feeding back into assembler)
; - add option to show invalid opcodes as constants

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
        BRA     MAIN            ; So start address stays constant

; Variables

ADDR    RMB     2               ; Current address to disassemble
OPCODE  RMB     1               ; Opcode of instruction
AM      RMB     1               ; Addressing mode of instruction
OPTYPE  RMB     1               ; Instruction type
POSTBYT RMB     1               ; Post byte (for indexed addressing)
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
OP_COM   EQU    $31
OP_CWAI  EQU    $32
OP_DAA   EQU    $33
OP_DEC   EQU    $34
OP_DECA  EQU    $35
OP_DECB  EQU    $36
OP_EORA  EQU    $37
OP_EORB  EQU    $38
OP_EXG   EQU    $39
OP_INC   EQU    $3A
OP_INCA  EQU    $3B
OP_INCB  EQU    $3C
OP_JMP   EQU    $3D
OP_JSR   EQU    $3E
OP_LBCC  EQU    $3F
OP_LBCS  EQU    $40
OP_LBEQ  EQU    $41
OP_LBGE  EQU    $42
OP_LBGT  EQU    $43
OP_LBHI  EQU    $44
OP_LBHS  EQU    $45
OP_LBLE  EQU    $46
OP_LBLO  EQU    $47
OP_LBLS  EQU    $48
OP_LBLT  EQU    $49
OP_LBMI  EQU    $4A
OP_LBNE  EQU    $4B
OP_LBPL  EQU    $4C
OP_LBRA  EQU    $4D
OP_LBRN  EQU    $4E
OP_LBSR  EQU    $4F
OP_LBVC  EQU    $50
OP_LBVS  EQU    $51
OP_LDA   EQU    $52
OP_LDB   EQU    $53
OP_LDD   EQU    $54
OP_LDS   EQU    $55
OP_LDU   EQU    $56
OP_LDX   EQU    $57
OP_LDY   EQU    $58
OP_LEAS  EQU    $59
OP_LEAU  EQU    $5A
OP_LEAX  EQU    $5B
OP_LEAY  EQU    $5C
OP_LSL   EQU    $5D
OP_LSLA  EQU    $5E
OP_LSLB  EQU    $5F
OP_LSR   EQU    $60
OP_LSRA  EQU    $61
OP_LSRB  EQU    $62
OP_MUL   EQU    $63
OP_NEG   EQU    $64
OP_NEGA  EQU    $65
OP_NEGB  EQU    $66
OP_NOP   EQU    $67
OP_ORA   EQU    $68
OP_ORB   EQU    $69
OP_ORCC  EQU    $6A
OP_PSHS  EQU    $6B
OP_PSHU  EQU    $6C
OP_PULS  EQU    $6D
OP_PULU  EQU    $6E
OP_ROL   EQU    $6F
OP_ROLA  EQU    $70
OP_ROLB  EQU    $71
OP_ROR   EQU    $72
OP_RORA  EQU    $73
OP_RORB  EQU    $74
OP_RTI   EQU    $75
OP_RTS   EQU    $76
OP_SBCA  EQU    $77
OP_SBCB  EQU    $78
OP_SEX   EQU    $79
OP_STA   EQU    $7A
OP_STB   EQU    $7B
OP_STD   EQU    $7C
OP_STS   EQU    $7D
OP_STU   EQU    $7E
OP_STX   EQU    $7F
OP_STY   EQU    $80
OP_SUBA  EQU    $81
OP_SUBB  EQU    $82
OP_SUBD  EQU    $83
OP_SWI   EQU    $84
OP_SWI2  EQU    $85
OP_SWI3  EQU    $86
OP_SYNC  EQU    $87
OP_TFR   EQU    $88
OP_TST   EQU    $89
OP_TSTA  EQU    $8A
OP_TSTB  EQU    $8B

; Addressing Modes. OPCODES table lists these for each instruction.
; LENGTHS lists the instruction length for each addressing mode.
; Need to distinguish relative modes that are 2 and 3 (long) bytes.
; Some immediate are 2 and some 3 bytes.
; Indexed modes can be longer depending on postbyte.
; Page 2 and 3 opcodes are one byte longer (prefixed by 10 or 11)

AM_INVALID      EQU     0       ; $01 (1)
AM_INHERENT     EQU     1       ; RTS (1)
AM_IMMEDIATE    EQU     2       ; LDA #$12 (2)
AM_IMMEDIATE2   EQU     3       ; LDD #$1234 (3)
AM_DIRECT       EQU     4       ; LDA $12 (2)
AM_EXTENDED     EQU     5       ; LDA $1234 (3)
AM_RELATIVE     EQU     6       ; BSR $1234 (2)
AM_RELATIVE2    EQU     7       ; LBSR $1234 (3)
AM_INDEXED      EQU     8       ; LDA 0,X (2+)

; *** CODE ***

; Main program, for test purposes.

MAIN:   LDX     #MAIN           ; Address to start disassembly (here)
        STX     ADDR            ; Store it
DIS:    BSR     DISASM          ; Do disassembly of one instruction
        BRA     DIS             ; Go back and repeat

; *** Utility Functions ***
; Some of these call ASSIST09 ROM monitor routines.

; Print CR/LF to the console.
; Registers affected: none
PrintCR:
        PSHS    A               ; Save A
        LDA     #CR
        BSR     PrintChar
        LDA     #LF
        BSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print dollar sign to the console.
; Registers affected: none
PrintDollar:
        PSHS    A               ; Save A
        LDA     #'$
        BSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print space sign to the console.
; Registers affected: none
PrintSpace:
        PSHS    A               ; Save A
        LDA     #SP
        BSR     PrintChar
        PULS    A               ; Restore A
        RTS

; Print several space characters.
; A contains number of spaces to print.
; Registers affected: none
PrintSpaces:
        PSHS    A               ; Save registers used
PS1:    CMPA    #0              ; Is count zero?
        BEQ     PS2             ; Is so, done
        BSR     PrintSpace      ; Print a space
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

; Print a string.
; X points to start of string to display.
; String must be terminated in EOT character.
; Registers affected: none
PrintString:
        PSHS    X               ; Save registers used
        SWI                     ; Call ASSIST09 monitor function
        FCB     PDATA1          ; Service code byte
        PULS    X               ; Restore registers used
        RTS

; Disassemble instruction at address ADDR. On return, ADDR points to
; next instruction so it can be called again.
; Typical output:
;
;1237  12           NOP
;1299  01           ???               ; INVALID
;1238  86 55        LDA   #$55
;1234  1A 00        ORCC  #$00
;1234  7E 12 34     JMP   $1234
;123A  10 FF 12 34  STS   $1234
;101C  A6 8D 02 14  LDA   $1234,PCR
;1020  A6 9F 12 34  LDA   [$1234]

DISASM: LDX     ADDR            ; Get address of instruction
        LDB     ,X              ; Get instruction op code
        STB     OPCODE          ; Save the op code

        CLRA                    ; Clear MSB of D
        TFR     D,X             ; Put op code in X
        LDB     OPCODES,X       ; Get opcode type from table
                                ; TODO: Handle page 2/3 16-bit opcodes prefixed with 10/11
        STB     OPTYPE          ; Store it
        LDB     OPCODE          ; Get op code again
        TFR     D,X             ; Put opcode in X
        LDB     MODES,X         ; Get addressing mode type from table
        STB     AM              ; Store it
        TFR     D,X             ; Put addressing mode in X
        LDB     LENGTHS,X       ; Get instruction length from table
        STB     LEN             ; Store it

; If addressing mode is indexed, get and save the indexed addressing
; post byte.

        LDA     AM              ; Get addressing mode
        CMPA    #AM_INDEXED     ; Is it indexed mode?
        BNE     NotIndexed      ; Branch if not
        LDX     ADDR            ; Get address of op code
        LDA     1,X             ; Get next byte (the post byte)
        STA     POSTBYT         ; Save it

; Determine number of additional bytes for indexed addressing based on
; postbyte. If most significant bit is 0, there are no additional
; bytes and we can skip the rest of the check.

        BPL     NotIndexed      ; Branch of MSB is zero

; Else if most significant bit is 1, mask off all but low order 5 bits
; and look up length in table.

        ANDA    #%00011111      ; Mask off bits
        LDX     #POSTBYTES      ; Lookup table of lengths
        LDA     A,X             ; Get table entry
        ADDA    LEN             ; Add to instruction length
        STA     LEN             ; Save new length

NotIndexed:

; Print address followed by a space
        LDX     ADDR
        BSR     PrintAddress

; Print one more space

        LBSR    PrintSpace

; Print the op code bytes based on the instruction length

        LDB     LEN             ; Number of bytes in instruction
        LDX     ADDR            ; Pointer to start of instruction
opby:   LDA     ,X+             ; Get instruction byte and increment pointer
        BSR     PrintByte       ; Print it, followed by a space
        DECB                    ; Decrement byte count
        BNE     opby            ; Repeat until done

; Print needed remaining spaces to pad out to correct column

        LDX     #PADDING        ; Pointer to start of lookup table
        LDA     LEN             ; Number of bytes in instruction
        DECA                    ; Subtract 1 since table starts at 1, not 0
        LDA     A,X             ; Get number of spaces to print
        LBSR    PrintSpaces

; Get the mnemonic

; Print mnemonic (4 chars)

        LDB     OPTYPE          ; Get instruction type to index into table
        LDA     #4              ; Want to multiply by 4
                                ; TODO: Probably a more efficient way to do this with shifts
        MUL                     ; Multiply, result in D
        LDX     #MNEMONICS      ; Pointer to start of table
        STA     TEMP1           ; Save value of A
        LDA     D,X             ; Get first char of mnemonic
        LBSR    PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get second char of mnemonic
        LBSR    PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get third char of mnemonic
        LBSR    PrintChar       ; Print it
        LDA     TEMP1           ; Restore value of A
        INCB                    ; Advance pointer
        LDA     D,X             ; Get fourth char of mnemonic
        LBSR    PrintChar       ; Print it

; Display any operands based on addressing mode and call appropriate
; routine. TODO: Could use a lookup table for this.

        LDA     AM              ; Get addressing mode
        CMPA    #AM_INVALID
        BEQ     DO_INVALID
        CMPA    #AM_INHERENT
        BEQ     DO_INHERENT
        CMPA    #AM_IMMEDIATE
        BEQ     DO_IMMEDIATE
        CMPA    #AM_IMMEDIATE2
        BEQ     DO_IMMEDIATE2
        CMPA    #AM_DIRECT
        BEQ     DO_DIRECT
        CMPA    #AM_EXTENDED
        BEQ     DO_EXTENDED
        CMPA    #AM_RELATIVE
        BEQ     DO_RELATIVE
        CMPA    #AM_RELATIVE2
        LBEQ    DO_RELATIVE2
        CMPA    #AM_INDEXED
        LBEQ    DO_INDEXED
        BRA     DO_INVALID      ; Should never be reached

DO_INVALID:                     ; Display "   ; INVALID"
        LDA     #15             ; Want 15 spaces
        LBSR    PrintSpaces
        LEAX    MSG1,PCR
        LBSR    PrintString
        BRA     done

DO_INHERENT:                    ; Nothing else to do
        BRA     done

DO_IMMEDIATE:                   ; Display "  #$nn"
                                ; TODO: Add support for special instructions: PSHS/SHU/PULS/PULU, TFR, EXG
        LDA     #2              ; Two spaces
        LBSR    PrintSpaces
        LDA     #'#             ; Number sign
        LBSR    PrintChar
        LBSR    PrintDollar     ; Dollar sign
        LDX     ADDR            ; Get address of op code
        LDA     1,X             ; Get next byte (immediate data)
        LBSR    PrintByte       ; Print as hex value
        BRA     done

DO_IMMEDIATE2:                  ; Display "  #$nnnn"
        LDA     #2              ; Two spaces
        LBSR    PrintSpaces
        LDA     #'#             ; Number sign
        LBSR    PrintChar
        LBSR    PrintDollar     ; Dollar sign
        LDX     ADDR            ; Get address of op code
        LDA     1,X             ; Get first byte (immediate data MSB)
        LDB     2,X             ; Get second byte (immediate data LSB)
        TFR     D,X             ; Put in X to print
        LBSR    PrintAddress    ; Print as hex value
        BRA     done

DO_DIRECT:                      ; Display "  $nn"
        LDA     #2              ; Two spaces
        LBSR    PrintSpaces
        LBSR    PrintDollar     ; Dollar sign
        LDX     ADDR            ; Get address of op code
        LDA     1,X             ; Get next byte (byte data)
        LBSR    PrintByte       ; Print as hex value
        BRA     done

DO_EXTENDED:                    ; Display "  $nnnn"
        LDA     #2              ; Two spaces
        LBSR    PrintSpaces
        LBSR    PrintDollar     ; Dollar sign
        LDX     ADDR            ; Get address of op code
        LDA     1,X             ; Get first byte (address MSB)
        LDB     2,X             ; Get second byte (address LSB)
        TFR     D,X             ; Put in X to print
        LBSR    PrintAddress    ; Print as hex value
        BRA     done

DO_RELATIVE:                    ; Display "  $nnnn"
        LDA     #2              ; Two spaces
        LBSR    PrintSpaces
        LBSR    PrintDollar     ; Dollar sign

; Effective address for relative branch is address of opcode + (sign extended)offset + 2
; e.g. $1015 + $(FF)FC + 2 = $1013
;      $101B + $(00)27 + 2 = $1044

        LDX     ADDR            ; Get address of op code
        LDB     1,X             ; Get first byte (8-bit branch offset)
        SEX                     ; Sign extent to 16 bits
        ADDD    ADDR            ; Add address of of code
        ADDD    #2              ; Add 2
        TFR     D,X             ; Put in X to print
        LBSR    PrintAddress    ; Print as hex value
        BRA     done

DO_RELATIVE2:
        BRA     done

DO_INDEXED:
        BRA     done

; Print final CR

done:   LBSR    PrintCR

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
        FCC     "COM "          ; $31
        FCC     "CWAI"          ; $32
        FCC     "DAA "          ; $33
        FCC     "DEC "          ; $34
        FCC     "DECA"          ; $35
        FCC     "DECB"          ; $36
        FCC     "EORA"          ; $37
        FCC     "EORB"          ; $38
        FCC     "EXG "          ; $39
        FCC     "INC "          ; $3A
        FCC     "INCA"          ; $3B
        FCC     "INCB"          ; $3C
        FCC     "JMP "          ; $3D
        FCC     "JSR "          ; $3E
        FCC     "LBCC"          ; $3F
        FCC     "LBCS"          ; $40
        FCC     "LBEQ"          ; $41
        FCC     "LBGE"          ; $42
        FCC     "LBGT"          ; $43
        FCC     "LBHI"          ; $44
        FCC     "LBHS"          ; $45
        FCC     "LBLE"          ; $46
        FCC     "LBLO"          ; $47
        FCC     "LBLS"          ; $48
        FCC     "LBLT"          ; $49
        FCC     "LBMI"          ; $4A
        FCC     "LBNE"          ; $4B
        FCC     "LBPL"          ; $4C
        FCC     "LBRA"          ; $4D
        FCC     "LBRN"          ; $4E
        FCC     "LBSR"          ; $4F
        FCC     "LBVC"          ; $50
        FCC     "LBVS"          ; $51
        FCC     "LDA "          ; $52
        FCC     "LDB "          ; $53
        FCC     "LDD "          ; $54
        FCC     "LDS "          ; $55
        FCC     "LDU "          ; $56
        FCC     "LDX "          ; $57
        FCC     "LDY "          ; $58
        FCC     "LEAS"          ; $59
        FCC     "LEAU"          ; $5A
        FCC     "LEAX"          ; $5B
        FCC     "LEAY"          ; $5C
        FCC     "LSL "          ; $5D
        FCC     "LSLA"          ; $5E
        FCC     "LSLB"          ; $5F
        FCC     "LSR "          ; $60
        FCC     "LSRA"          ; $61
        FCC     "LSRB"          ; $62
        FCC     "MUL "          ; $63
        FCC     "NEG "          ; $64
        FCC     "NEGA"          ; $65
        FCC     "NEGB"          ; $66
        FCC     "NOP "          ; $67
        FCC     "ORA "          ; $68
        FCC     "ORB "          ; $69
        FCC     "ORCC"          ; $6A
        FCC     "PSHS"          ; $6B
        FCC     "PSHU"          ; $6C
        FCC     "PULS"          ; $6D
        FCC     "PULU"          ; $6E
        FCC     "ROL "          ; $6F
        FCC     "ROLA"          ; $70
        FCC     "ROLB"          ; $71
        FCC     "ROR "          ; $72
        FCC     "RORA"          ; $73
        FCC     "RORB"          ; $74
        FCC     "RTI "          ; $75
        FCC     "RTS "          ; $76
        FCC     "SBCA"          ; $77
        FCC     "SBCB"          ; $78
        FCC     "SEX "          ; $79
        FCC     "STA "          ; $7A
        FCC     "STB "          ; $7B
        FCC     "STD "          ; $7C
        FCC     "STS "          ; $7D
        FCC     "STU "          ; $7E
        FCC     "STX "          ; $7F
        FCC     "STY "          ; $80
        FCC     "SUBA"          ; $81
        FCC     "SUBB"          ; $82
        FCC     "SUBD"          ; $83
        FCC     "SWI "          ; $84
        FCC     "SWI2"          ; $85
        FCC     "SWI3"          ; $86
        FCC     "SYNC"          ; $87
        FCC     "TFR "          ; $88
        FCC     "TST "          ; $89
        FCC     "TSTA"          ; $8A
        FCC     "TSTB"          ; $8B

; Lengths of instructions given an addressing mode. Matches values of
; AM_* Indexed addessing instructions lenth can increase due to post
; byte.
LENGTHS:
        FCB     1               ; 0 AM_INVALID
        FCB     1               ; 1 AM_INHERENT
        FCB     2               ; 2 AM_IMMEDIATE
        FCB     3               ; 3 AM_IMMEDIATE2
        FCB     2               ; 4 AM_DIRECT
        FCB     3               ; 5 AM_EXTENDED
        FCB     2               ; 6 AM_RELATIVE
        FCB     3               ; 7 AM_RELATIVE2
        FCB     2               ; 8 AM_INDEXED

; Lookup table to return needed remaining spaces to print to pad out
; instruction to correct column in disassembly.
; # bytes: 1 2 3 4
; Padding: 9 6 3 0
PADDING:
        FCB     10, 7, 4, 1

; Lookup table to return number of additional bytes for indexed
; addressing based on low order 5 bits of postbyte. Based on
; detailed list of values below.

POSTBYTES:
        FCB     0, 0, 0, 0, 0, 0, 0, 0
        FCB     1, 2, 0, 0, 1, 2, 0, 0
        FCB     0, 0, 0, 0, 0, 0, 0, 0
        FCB     1, 2, 0, 0, 1, 2, 0, 2

; Pattern:  # Extra bytes:
; --------  --------------
; 0XXXXXXX   0
; 1XX00000   0
; 1XX00001   0
; 1XX00010   0
; 1XX00011   0
; 1XX00100   0
; 1X000101   0
; 1XX00110   0
; 1XX00111   0 (INVALID)
; 1XX01000   1
; 1XX01001   2
; 1XX01010   0 (INVALID)
; 1XX01011   0
; 1XX01100   1
; 1XX01101   2
; 1XX01110   0 (INVALID)
; 1XX01111   0 (INVALID)
; 1XX10000   0 (INVALID)
; 1XX10001   0
; 1XX10010   0 (INVALID)
; 1XX10011   0
; 1XX10100   0
; 1XX10101   0
; 1XX10110   0
; 1XX10111   0 (INVALID)
; 1XX11000   1
; 1XX11001   2
; 1XX11010   0 (INVALID)
; 1XX11011   0
; 1XX11100   1
; 1XX11101   2
; 1XX11110   0 (INVALID)
; 1XX11111   2

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
        FCB     OP_BRN          ; 21
        FCB     OP_BHI          ; 22
        FCB     OP_BLS          ; 23
        FCB     OP_BHS          ; 24
        FCB     OP_BLO          ; 25
        FCB     OP_BNE          ; 26
        FCB     OP_BEQ          ; 27
        FCB     OP_BVC          ; 28
        FCB     OP_BVS          ; 29
        FCB     OP_BPL          ; 2A
        FCB     OP_BMI          ; 2B
        FCB     OP_BGE          ; 2C
        FCB     OP_BLT          ; 2D
        FCB     OP_BGT          ; 2E
        FCB     OP_BLE          ; 2F

        FCB     OP_LEAX         ; 30
        FCB     OP_LEAY         ; 31
        FCB     OP_LEAS         ; 32
        FCB     OP_LEAU         ; 33
        FCB     OP_PSHS         ; 34
        FCB     OP_PULS         ; 35
        FCB     OP_PSHU         ; 36
        FCB     OP_PULU         ; 37
        FCB     OP_INV          ; 38
        FCB     OP_RTS          ; 39
        FCB     OP_ABX          ; 3A
        FCB     OP_RTI          ; 3B
        FCB     OP_CWAI         ; 3C
        FCB     OP_MUL          ; 3D
        FCB     OP_INV          ; 3E
        FCB     OP_SWI          ; 3F

        FCB     OP_NEGA         ; 40
        FCB     OP_INV          ; 41
        FCB     OP_INV          ; 42
        FCB     OP_COMA         ; 43
        FCB     OP_LSRA         ; 44
        FCB     OP_INV          ; 45
        FCB     OP_RORA         ; 46
        FCB     OP_ASRA         ; 47
        FCB     OP_ASLA         ; 48
        FCB     OP_ROLA         ; 49
        FCB     OP_DECA         ; 4A
        FCB     OP_INV          ; 4B
        FCB     OP_INCA         ; 4C
        FCB     OP_TSTA         ; 4D
        FCB     OP_INV          ; 4E
        FCB     OP_CLRA         ; 4F

        FCB     OP_NEGB         ; 50
        FCB     OP_INV          ; 51
        FCB     OP_INV          ; 52
        FCB     OP_COMB         ; 53
        FCB     OP_LSRB         ; 54
        FCB     OP_INV          ; 55
        FCB     OP_RORB         ; 56
        FCB     OP_ASRB         ; 57
        FCB     OP_ASLB         ; 58
        FCB     OP_ROLB         ; 59
        FCB     OP_DECB         ; 5A
        FCB     OP_INV          ; 5B
        FCB     OP_INCB         ; 5C
        FCB     OP_TSTB         ; 5D
        FCB     OP_INV          ; 5E
        FCB     OP_CLRB         ; 5F

        FCB     OP_NEG          ; 60
        FCB     OP_INV          ; 61
        FCB     OP_INV          ; 62
        FCB     OP_COM          ; 63
        FCB     OP_LSR          ; 64
        FCB     OP_INV          ; 65
        FCB     OP_ROR          ; 66
        FCB     OP_ASR          ; 67
        FCB     OP_ASL          ; 68
        FCB     OP_ROL          ; 69
        FCB     OP_DEC          ; 6A
        FCB     OP_INV          ; 6B
        FCB     OP_INC          ; 6C
        FCB     OP_TST          ; 6D
        FCB     OP_JMP          ; 6E
        FCB     OP_CLR          ; 6F

        FCB     OP_NEG          ; 70
        FCB     OP_INV          ; 71
        FCB     OP_INV          ; 72
        FCB     OP_COM          ; 73
        FCB     OP_LSR          ; 74
        FCB     OP_INV          ; 75
        FCB     OP_ROR          ; 76
        FCB     OP_ASR          ; 77
        FCB     OP_ASL          ; 78
        FCB     OP_ROL          ; 79
        FCB     OP_DEC          ; 7A
        FCB     OP_INV          ; 7B
        FCB     OP_INC          ; 7C
        FCB     OP_TST          ; 7D
        FCB     OP_JMP          ; 7E
        FCB     OP_CLR          ; 7F

        FCB     OP_SUBA         ; 80
        FCB     OP_CMPA         ; 81
        FCB     OP_SBCA         ; 82
        FCB     OP_SUBD         ; 83
        FCB     OP_ANDA         ; 84
        FCB     OP_BITA         ; 85
        FCB     OP_LDA          ; 86
        FCB     OP_INV          ; 87
        FCB     OP_EORA         ; 88
        FCB     OP_ADCA         ; 89
        FCB     OP_ORA          ; 8A
        FCB     OP_ADDA         ; 8B
        FCB     OP_CMPX         ; 8C
        FCB     OP_BSR          ; 8D
        FCB     OP_LDX          ; 8E
        FCB     OP_INV          ; 8F

        FCB     OP_SUBA         ; 90
        FCB     OP_CMPA         ; 91
        FCB     OP_SBCA         ; 92
        FCB     OP_SUBD         ; 93
        FCB     OP_ANDA         ; 94
        FCB     OP_BITA         ; 95
        FCB     OP_LDA          ; 96
        FCB     OP_STA          ; 97
        FCB     OP_EORA         ; 98
        FCB     OP_ADCA         ; 99
        FCB     OP_ORA          ; 9A
        FCB     OP_ADDA         ; 9B
        FCB     OP_CMPX         ; 9C
        FCB     OP_JSR          ; 9D
        FCB     OP_LDX          ; 9E
        FCB     OP_STX          ; 9F

        FCB     OP_SUBA         ; A0
        FCB     OP_CMPA         ; A1
        FCB     OP_SBCA         ; A2
        FCB     OP_SUBD         ; A3
        FCB     OP_ANDA         ; A4
        FCB     OP_BITA         ; A5
        FCB     OP_LDA          ; A6
        FCB     OP_STA          ; A7
        FCB     OP_EORA         ; A8
        FCB     OP_ADCA         ; A9
        FCB     OP_ORA          ; AA
        FCB     OP_ADDA         ; AB
        FCB     OP_CMPX         ; AC
        FCB     OP_JSR          ; AD
        FCB     OP_LDX          ; AE
        FCB     OP_STX          ; AF

        FCB     OP_SUBA         ; B0
        FCB     OP_CMPA         ; B1
        FCB     OP_SBCA         ; B2
        FCB     OP_SUBD         ; B3
        FCB     OP_ANDA         ; B4
        FCB     OP_BITA         ; B5
        FCB     OP_LDA          ; B6
        FCB     OP_STA          ; B7
        FCB     OP_EORA         ; B8
        FCB     OP_ADCA         ; B9
        FCB     OP_ORA          ; BA
        FCB     OP_ADDA         ; BB
        FCB     OP_CMPX         ; BC
        FCB     OP_JSR          ; BD
        FCB     OP_LDX          ; BE
        FCB     OP_STX          ; BF

        FCB     OP_SUBB         ; C0
        FCB     OP_CMPB         ; C1
        FCB     OP_SBCB         ; C2
        FCB     OP_ADDD         ; C3
        FCB     OP_ANDB         ; C4
        FCB     OP_BITB         ; C5
        FCB     OP_LDB          ; C6
        FCB     OP_INV          ; C7
        FCB     OP_EORB         ; C8
        FCB     OP_ADCB         ; C9
        FCB     OP_ORB          ; CA
        FCB     OP_ADDB         ; CB
        FCB     OP_LDD          ; CC
        FCB     OP_INV          ; CD
        FCB     OP_LDU          ; CE
        FCB     OP_INV          ; CF

        FCB     OP_SUBB         ; D0
        FCB     OP_CMPB         ; D1
        FCB     OP_SBCB         ; D2
        FCB     OP_ADDD         ; D3
        FCB     OP_ANDB         ; D4
        FCB     OP_BITB         ; D5
        FCB     OP_LDB          ; D6
        FCB     OP_STB          ; D7
        FCB     OP_EORB         ; D8
        FCB     OP_ADCB         ; D9
        FCB     OP_ORB          ; DA
        FCB     OP_ADDB         ; DB
        FCB     OP_LDD          ; DC
        FCB     OP_STD          ; DD
        FCB     OP_LDU          ; DE
        FCB     OP_STU          ; DF

        FCB     OP_SUBB         ; E0
        FCB     OP_CMPB         ; E1
        FCB     OP_SBCB         ; E2
        FCB     OP_ADDD         ; E3
        FCB     OP_ANDB         ; E4
        FCB     OP_BITB         ; E5
        FCB     OP_LDB          ; E6
        FCB     OP_STB          ; E7
        FCB     OP_EORB         ; E8
        FCB     OP_ADCB         ; E9
        FCB     OP_ORB          ; EA
        FCB     OP_ADDB         ; EB
        FCB     OP_LDD          ; EC
        FCB     OP_STD          ; ED
        FCB     OP_LDU          ; EE
        FCB     OP_STU          ; EF

        FCB     OP_SUBB         ; F0
        FCB     OP_CMPB         ; F1
        FCB     OP_SBCB         ; F2
        FCB     OP_ADDD         ; F3
        FCB     OP_ANDB         ; F4
        FCB     OP_BITB         ; F5
        FCB     OP_LDB          ; F6
        FCB     OP_STB          ; F7
        FCB     OP_EORB         ; F8
        FCB     OP_ADCB         ; F9
        FCB     OP_ORB          ; FA
        FCB     OP_ADDB         ; FB
        FCB     OP_LDD          ; FC
        FCB     OP_STD          ; FD
        FCB     OP_LDU          ; FE
        FCB     OP_STU          ; FF

; Table of addressing modes. Listed in order,indexed by op code.
MODES:
        FCB     AM_DIRECT       ; 00
        FCB     AM_INVALID      ; 01
        FCB     AM_INVALID      ; 02
        FCB     AM_DIRECT       ; 03
        FCB     AM_DIRECT       ; 04
        FCB     AM_INVALID      ; 05
        FCB     AM_DIRECT       ; 06
        FCB     AM_DIRECT       ; 07
        FCB     AM_DIRECT       ; 08
        FCB     AM_DIRECT       ; 09
        FCB     AM_DIRECT       ; 0A
        FCB     AM_INVALID      ; 0B
        FCB     AM_DIRECT       ; 0C
        FCB     AM_DIRECT       ; 0D
        FCB     AM_DIRECT       ; 0E
        FCB     AM_DIRECT       ; 0F

        FCB     AM_INHERENT     ; 10 Page 2 extended opcodes (see other table)
        FCB     AM_INHERENT     ; 11 Page 3 extended opcodes (see other table)
        FCB     AM_INHERENT     ; 12
        FCB     AM_INHERENT     ; 13
        FCB     AM_INVALID      ; 14
        FCB     AM_INVALID      ; 15
        FCB     AM_RELATIVE2    ; 16
        FCB     AM_RELATIVE2    ; 17
        FCB     AM_INVALID      ; 18
        FCB     AM_INHERENT     ; 19
        FCB     AM_IMMEDIATE    ; 1A
        FCB     AM_INVALID      ; 1B
        FCB     AM_IMMEDIATE    ; 1C
        FCB     AM_INHERENT     ; 1D
        FCB     AM_IMMEDIATE    ; 1E
        FCB     AM_IMMEDIATE    ; 1F

        FCB     AM_RELATIVE     ; 20
        FCB     AM_RELATIVE     ; 21
        FCB     AM_RELATIVE     ; 22
        FCB     AM_RELATIVE     ; 23
        FCB     AM_RELATIVE     ; 24
        FCB     AM_RELATIVE     ; 25
        FCB     AM_RELATIVE     ; 26
        FCB     AM_RELATIVE     ; 27
        FCB     AM_RELATIVE     ; 28
        FCB     AM_RELATIVE     ; 29
        FCB     AM_RELATIVE     ; 2A
        FCB     AM_RELATIVE     ; 2B
        FCB     AM_RELATIVE     ; 2C
        FCB     AM_RELATIVE     ; 2D
        FCB     AM_RELATIVE     ; 2E
        FCB     AM_RELATIVE     ; 2F

        FCB     AM_INDEXED      ; 30
        FCB     AM_INDEXED      ; 31
        FCB     AM_INDEXED      ; 32
        FCB     AM_INDEXED      ; 33
        FCB     AM_IMMEDIATE    ; 34
        FCB     AM_IMMEDIATE    ; 35
        FCB     AM_IMMEDIATE    ; 36
        FCB     AM_IMMEDIATE    ; 37
        FCB     AM_INVALID      ; 38
        FCB     AM_INHERENT     ; 39
        FCB     AM_INHERENT     ; 3A
        FCB     AM_INHERENT     ; 3B
        FCB     AM_IMMEDIATE    ; 3C
        FCB     AM_INHERENT     ; 3D
        FCB     AM_INVALID      ; 3E
        FCB     AM_INHERENT     ; 3F

        FCB     AM_INHERENT     ; 40
        FCB     AM_INVALID      ; 41
        FCB     AM_INVALID      ; 42
        FCB     AM_INHERENT     ; 43
        FCB     AM_INHERENT     ; 44
        FCB     AM_INVALID      ; 45
        FCB     AM_INHERENT     ; 46
        FCB     AM_INHERENT     ; 47
        FCB     AM_INHERENT     ; 48
        FCB     AM_INHERENT     ; 49
        FCB     AM_INHERENT     ; 4A
        FCB     AM_INVALID      ; 4B
        FCB     AM_INHERENT     ; 4C
        FCB     AM_INHERENT     ; 4D
        FCB     AM_INVALID      ; 4E
        FCB     AM_INHERENT     ; 4F

        FCB     AM_INHERENT     ; 50
        FCB     AM_INVALID      ; 51
        FCB     AM_INVALID      ; 52
        FCB     AM_INHERENT     ; 53
        FCB     AM_INHERENT     ; 54
        FCB     AM_INVALID      ; 55
        FCB     AM_INHERENT     ; 56
        FCB     AM_INHERENT     ; 57
        FCB     AM_INHERENT     ; 58
        FCB     AM_INHERENT     ; 59
        FCB     AM_INHERENT     ; 5A
        FCB     AM_INVALID      ; 5B
        FCB     AM_INHERENT     ; 5C
        FCB     AM_INHERENT     ; 5D
        FCB     AM_INVALID      ; 5E
        FCB     AM_INHERENT     ; 5F

        FCB     AM_INDEXED      ; 60
        FCB     AM_INVALID      ; 61
        FCB     AM_INVALID      ; 62
        FCB     AM_INDEXED      ; 63
        FCB     AM_INDEXED      ; 64
        FCB     AM_INVALID      ; 65
        FCB     AM_INDEXED      ; 66
        FCB     AM_INDEXED      ; 67
        FCB     AM_INDEXED      ; 68
        FCB     AM_INDEXED      ; 69
        FCB     AM_INDEXED      ; 6A
        FCB     AM_INVALID      ; 6B
        FCB     AM_INDEXED      ; 6C
        FCB     AM_INDEXED      ; 6D
        FCB     AM_INDEXED      ; 6E
        FCB     AM_INDEXED      ; 6F

        FCB     AM_EXTENDED     ; 70
        FCB     AM_INVALID      ; 71
        FCB     AM_INVALID      ; 72
        FCB     AM_EXTENDED     ; 73
        FCB     AM_EXTENDED     ; 74
        FCB     AM_INVALID      ; 75
        FCB     AM_EXTENDED     ; 76
        FCB     AM_EXTENDED     ; 77
        FCB     AM_EXTENDED     ; 78
        FCB     AM_EXTENDED     ; 79
        FCB     AM_EXTENDED     ; 7A
        FCB     AM_INVALID      ; 7B
        FCB     AM_EXTENDED     ; 7C
        FCB     AM_EXTENDED     ; 7D
        FCB     AM_EXTENDED     ; 7E
        FCB     AM_EXTENDED     ; 7F

        FCB     AM_IMMEDIATE    ; 80
        FCB     AM_IMMEDIATE    ; 81
        FCB     AM_IMMEDIATE    ; 82
        FCB     AM_IMMEDIATE2   ; 83
        FCB     AM_IMMEDIATE    ; 84
        FCB     AM_IMMEDIATE    ; 85
        FCB     AM_IMMEDIATE    ; 86
        FCB     AM_INVALID      ; 87
        FCB     AM_IMMEDIATE    ; 88
        FCB     AM_IMMEDIATE    ; 89
        FCB     AM_IMMEDIATE    ; 8A
        FCB     AM_IMMEDIATE    ; 8B
        FCB     AM_IMMEDIATE2   ; 8C
        FCB     AM_RELATIVE     ; 8D
        FCB     AM_IMMEDIATE2   ; 8E
        FCB     AM_INVALID      ; 8F

        FCB     AM_DIRECT       ; 90
        FCB     AM_DIRECT       ; 91
        FCB     AM_DIRECT       ; 92
        FCB     AM_DIRECT       ; 93
        FCB     AM_DIRECT       ; 94
        FCB     AM_DIRECT       ; 95
        FCB     AM_DIRECT       ; 96
        FCB     AM_DIRECT       ; 97
        FCB     AM_DIRECT       ; 98
        FCB     AM_DIRECT       ; 99
        FCB     AM_DIRECT       ; 9A
        FCB     AM_DIRECT       ; 9B
        FCB     AM_DIRECT       ; 9C
        FCB     AM_DIRECT       ; 9D
        FCB     AM_DIRECT       ; 9E
        FCB     AM_DIRECT       ; 9F

        FCB     AM_INDEXED      ; A0
        FCB     AM_INDEXED      ; A1
        FCB     AM_INDEXED      ; A2
        FCB     AM_INDEXED      ; A3
        FCB     AM_INDEXED      ; A4
        FCB     AM_INDEXED      ; A5
        FCB     AM_INDEXED      ; A6
        FCB     AM_INDEXED      ; A7
        FCB     AM_INDEXED      ; A8
        FCB     AM_INDEXED      ; A9
        FCB     AM_INDEXED      ; AA
        FCB     AM_INDEXED      ; AB
        FCB     AM_INDEXED      ; AC
        FCB     AM_INDEXED      ; AD
        FCB     AM_INDEXED      ; AE
        FCB     AM_INDEXED      ; AF

        FCB     AM_EXTENDED     ; B0
        FCB     AM_EXTENDED     ; B1
        FCB     AM_EXTENDED     ; B2
        FCB     AM_EXTENDED     ; B3
        FCB     AM_EXTENDED     ; B4
        FCB     AM_EXTENDED     ; B5
        FCB     AM_EXTENDED     ; B6
        FCB     AM_EXTENDED     ; B7
        FCB     AM_EXTENDED     ; B8
        FCB     AM_EXTENDED     ; B9
        FCB     AM_EXTENDED     ; BA
        FCB     AM_EXTENDED     ; BB
        FCB     AM_EXTENDED     ; BC
        FCB     AM_EXTENDED     ; BD
        FCB     AM_EXTENDED     ; BE
        FCB     AM_EXTENDED     ; BF

        FCB     AM_IMMEDIATE    ; C0
        FCB     AM_IMMEDIATE    ; C1
        FCB     AM_IMMEDIATE    ; C2
        FCB     AM_IMMEDIATE2   ; C3
        FCB     AM_IMMEDIATE    ; C4
        FCB     AM_IMMEDIATE    ; C5
        FCB     AM_IMMEDIATE    ; C6
        FCB     AM_INVALID      ; C7
        FCB     AM_IMMEDIATE    ; C8
        FCB     AM_IMMEDIATE    ; C9
        FCB     AM_IMMEDIATE    ; CA
        FCB     AM_IMMEDIATE    ; CB
        FCB     AM_IMMEDIATE    ; CC
        FCB     AM_INHERENT     ; CD
        FCB     AM_IMMEDIATE    ; CE
        FCB     AM_INVALID      ; CF

        FCB     AM_DIRECT       ; D0
        FCB     AM_DIRECT       ; D1
        FCB     AM_DIRECT       ; D2
        FCB     AM_DIRECT       ; D3
        FCB     AM_DIRECT       ; D4
        FCB     AM_DIRECT       ; D5
        FCB     AM_DIRECT       ; D6
        FCB     AM_DIRECT       ; D7
        FCB     AM_DIRECT       ; D8
        FCB     AM_DIRECT       ; D9
        FCB     AM_DIRECT       ; DA
        FCB     AM_DIRECT       ; DB
        FCB     AM_DIRECT       ; DC
        FCB     AM_DIRECT       ; DD
        FCB     AM_DIRECT       ; DE
        FCB     AM_DIRECT       ; DF

        FCB     AM_INDEXED      ; E0
        FCB     AM_INDEXED      ; E1
        FCB     AM_INDEXED      ; E2
        FCB     AM_INDEXED      ; E3
        FCB     AM_INDEXED      ; E4
        FCB     AM_INDEXED      ; E5
        FCB     AM_INDEXED      ; E6
        FCB     AM_INDEXED      ; E7
        FCB     AM_INDEXED      ; E8
        FCB     AM_INDEXED      ; E9
        FCB     AM_INDEXED      ; EA
        FCB     AM_INDEXED      ; EB
        FCB     AM_INDEXED      ; EC
        FCB     AM_INDEXED      ; ED
        FCB     AM_INDEXED      ; EE
        FCB     AM_INDEXED      ; EF

        FCB     AM_EXTENDED     ; F0
        FCB     AM_EXTENDED     ; F1
        FCB     AM_EXTENDED     ; F2
        FCB     AM_EXTENDED     ; F3
        FCB     AM_EXTENDED     ; F4
        FCB     AM_EXTENDED     ; F5
        FCB     AM_EXTENDED     ; F6
        FCB     AM_EXTENDED     ; F7
        FCB     AM_EXTENDED     ; F8
        FCB     AM_EXTENDED     ; F9
        FCB     AM_EXTENDED     ; FA
        FCB     AM_EXTENDED     ; FB
        FCB     AM_EXTENDED     ; FC
        FCB     AM_EXTENDED     ; FD
        FCB     AM_EXTENDED     ; FE
        FCB     AM_EXTENDED     ; FF

; Special table for page 2 instructions prefixed by $10.
; Format: opcode (less 10), instruction, addressing mode

PAGE2:
        FCB     $21, OP_LBRN,  AM_RELATIVE2
        FCB     $22, OP_LBHI,  AM_RELATIVE2
        FCB     $23, OP_LBLS,  AM_RELATIVE2
        FCB     $24, OP_LBHS,  AM_RELATIVE2
        FCB     $25, OP_LBCS,  AM_RELATIVE2
        FCB     $26, OP_LBNE,  AM_RELATIVE2
        FCB     $27, OP_LBEQ,  AM_RELATIVE2
        FCB     $28, OP_LBVC,  AM_RELATIVE2
        FCB     $29, OP_LBVS,  AM_RELATIVE2
        FCB     $2A, OP_LBPL,  AM_RELATIVE2
        FCB     $2B, OP_LBMI,  AM_RELATIVE2
        FCB     $2C, OP_LBGE,  AM_RELATIVE2
        FCB     $2D, OP_LBLT,  AM_RELATIVE2
        FCB     $2E, OP_LBGT,  AM_RELATIVE2
        FCB     $2F, OP_LBLE,  AM_RELATIVE2
        FCB     $3F, OP_SWI2,  AM_INHERENT
        FCB     $83, OP_CMPD,  AM_IMMEDIATE2
        FCB     $8C, OP_CMPY,  AM_IMMEDIATE2
        FCB     $8E, OP_LDY,   AM_IMMEDIATE2
        FCB     $93, OP_CMPD,  AM_DIRECT
        FCB     $9C, OP_CMPY,  AM_DIRECT
        FCB     $9E, OP_LDY,   AM_DIRECT
        FCB     $9D, OP_STY,   AM_DIRECT
        FCB     $A3, OP_CMPD,  AM_INDEXED
        FCB     $AC, OP_CMPY,  AM_INDEXED
        FCB     $AE, OP_LDY,   AM_INDEXED
        FCB     $AF, OP_STY,   AM_INDEXED
        FCB     $B3, OP_CMPD,  AM_EXTENDED
        FCB     $BC, OP_CMPY,  AM_EXTENDED
        FCB     $BE, OP_LDY,   AM_EXTENDED
        FCB     $BF, OP_STY,   AM_EXTENDED
        FCB     $CE, OP_LDS,   AM_IMMEDIATE2
        FCB     $DE, OP_LDS,   AM_DIRECT
        FCB     $DD, OP_STS,   AM_DIRECT
        FCB     $EE, OP_LDS,   AM_INDEXED
        FCB     $EF, OP_STS,   AM_INDEXED
        FCB     $FE, OP_LDS,   AM_EXTENDED
        FCB     $FD, OP_STS,   AM_EXTENDED
        FCB     0                             ; indicates end of table

; Special table for page 3 instructions prefixed by $11.
; Same format as table above.

PAGE3:
        FCB     $3F, OP_SWI3,  AM_INHERENT
        FCB     $83, OP_CMPU,  AM_IMMEDIATE2
        FCB     $8C, OP_CMPS,  AM_IMMEDIATE2
        FCB     $93, OP_CMPU,  AM_DIRECT
        FCB     $9C, OP_CMPS,  AM_DIRECT
        FCB     $A3, OP_CMPU,  AM_INDEXED
        FCB     $AC, OP_CMPS,  AM_INDEXED
        FCB     $B3, OP_CMPU,  AM_EXTENDED
        FCB     $BC, OP_CMPS,  AM_EXTENDED
        FCB     0                             ; indicates end of table

; Display strings. Should be terminated in EOT character.

MSG1:   FCC     "; INVALID"
        FCB     EOT
