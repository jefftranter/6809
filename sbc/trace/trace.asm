;
; 6809 Trace Utility
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
; 0.0     20-Mar-2019  First version started, based on 6502 code.
;
; To Do: See TODOs in code.


; Character defines

EOT     EQU     $04             ; String terminator

; Tables and routines in ASSIST09 ROM

OPCODES equ     $C908
PAGE2   equ     $CB08
PAGE3   equ     $CB7B
LENGTHS equ     $C8DB
MODES   equ     $CA08
POSTBYTES equ   $C8E8

GetChar equ     $C07E
Print2Spaces equ $C062
PrintAddress equ $C08F
PrintByte equ   $C081
PrintCR equ     $C02E
PrintChar equ   $C07B
PrintDollar equ $C03B
PrintSpace equ  $C05F
PrintString equ $C09D
ADRS    equ     $5FF0
DISASM  equ     $C0A4

; Instruction types - taken from disassembler

OP_INV   EQU    $00
OP_BSR   EQU    $20
OP_CWAI  EQU    $30
OP_JMP   EQU    $3B
OP_JSR   EQU    $3C
OP_LBSR  EQU    $4B
OP_RTI   EQU    $6E
OP_RTS   EQU    $6F
OP_SWI   EQU    $7D
OP_SWI2  EQU    $7E
OP_SWI3  EQU    $7F
OP_SYNC  EQU    $80

; Addressing modes - taken from disassembler

AM_INVALID equ  0
AM_INDEXED equ  8

        ORG     $1000

; Variables

SAVE_CC RMB     1               ; Saved register values
SAVE_A  RMB     1
SAVE_B  RMB     1
SAVE_DP RMB     1
SAVE_X  RMB     2
SAVE_Y  RMB     2
SAVE_U  RMB     2
SAVE_S  RMB     2
SAVE_PC RMB     2
ADDRESS RMB     2               ; Instruction address
NEXTPC  RMB     2               ; Value of PC after next instruction
OPCODE  RMB     1               ; Instruction op code
OPTYPE  RMB     1               ; Instruction type (e.g. JMP)
PAGE23  RMB     1               ; Flag indicating page2/3 instruction when non-zero
POSTBYT RMB     1               ; Post byte (for indexed addressing)
LENGTH  RMB     1               ; Length of instruction
AM      RMB     1               ; Addressing mode
OURS    RMB     2               ; This program's user stack pointer
OURU    RMB     2               ; This program's system stack pointer
BUFFER  RMB     8               ; Buffer holding traced instruction (up to 5 bytes plus JMP XXXX)

        ORG     $2000
        
;------------------------------------------------------------------------
; Code for testing trace function. Just contains a variety of
; different instruction types.

testcode
        nop
        lda     #$01
        ldb     #$02
        ldx     #$1234
        ldy     #$2345
        lds     #$5000
        ldu     #$6000
        leax    1,x
        leay    2,y
        adda    #1
        addb    #1
        exg     a,b
        andcc   #$00
        orcc    #$FF
        cmpu    #$4321
        fcb     $01             ; Invalid instruction
        nop
        sync
        nop
        cwai    #$EF
        nop
        swi
        nop
        swi2
        nop
        swi3
        nop
        jmp     testcode
        jsr     testcode
        bsr     testcode
        lbsr    testcode
        rti
        rts
        bra     testcode
        beq     testcode
        bne     testcode
        lbra    testcode
        lbeq    testcode
        lbne    testcode
        puls    pc,a,b
        pulu    pc,x,y
        tfr     x,pc
        exg     y,pc
        exg     pc,y

        ORG     $3000

;------------------------------------------------------------------------
; Main program
; Trace test code.
main    sta     SAVE_A          ; Save all registers
        stb     SAVE_B
        stx     SAVE_X
        sty     SAVE_Y
        sts     SAVE_S
        stu     SAVE_U
        tfr     pc,x
        stx     SAVE_PC
        tfr     dp,a
        sta     SAVE_DP
        tfr     cc,a
        sta     SAVE_CC
        ldx     #testcode       ; Start address of code to trace
        stx     ADDRESS
        stx     SAVE_PC
loop    bsr     step
        lbsr    GetChar         ; Wait for a key press
        bra     loop

;------------------------------------------------------------------------
; Step: Step one instruction
; Get address to step.
; Call Trace
; Display register values
; Disassemble next instruction (Set ADDR, call DISASM)
; Return

step    bsr     Trace           ; Trace an instruction
        lbsr    DisplayRegs     ; Display register values
        lbsr    Disassemble     ; Disassemble the instruction
        ldx     ADDRESS         ; Get next address
        stx     SAVE_PC         ; And store as last PC
        rts

;------------------------------------------------------------------------
; Trace one instruction.
; Input: Address of instruction in ADDRESS.
; Returns: Updates saved register values.
;
; TODO: How to handle PC relative instructions?

Trace   clr     PAGE23          ; Clear page2/3 flag
        ldx     ADDRESS,PCR     ; Get address of instruction
        ldb     ,X              ; Get instruction op code
        cmpb    #$10            ; Is it a page 2 16-bit opcode prefix with 10?
        beq     handle10        ; If so, do special handling
        cmpb    #$11            ; Is it a page 3 16-bit opcode prefix with 11?
        beq     handle11        ; If so, do special handling
        lbra    not1011         ; If not, handle as normal case

handle10                        ; Handle page 2 instruction
        lda     #1              ; Set page2/3 flag
        sta     PAGE23
        ldb     1,X             ; Get real opcode
        stb     OPCODE          ; Save it.
        leax    PAGE2,PCR       ; Pointer to start of table
        clra                    ; Set index into table to zero
search10
        cmpb    A,X             ; Check for match of opcode in table
        beq     found10         ; Branch if found
        adda    #3              ; Advance to next entry in table (entries are 3 bytes long)
        tst     A,X             ; Check entry
        beq     notfound10      ; If zero, then reached end of table
        bra     search10        ; If not, keep looking

notfound10                      ; Instruction not found, so is invalid.
        lda     #$10            ; Set opcode to 10
        sta     OPCODE
        lda     #OP_INV         ; Set as instruction type invalid
        sta     OPTYPE
        lda     #AM_INVALID     ; Set as addressing mode invalid
        sta     AM
        lda     #1              ; Set length to one
        sta     LENGTH
        lbra    dism            ; Disassemble as normal

found10                         ; Found entry in table
        adda    #1              ; Advance to instruction type entry in table
        ldb     A,X             ; Get instruction type
        stb     OPTYPE          ; Save it
        adda    #1              ; Advanced to address mode entry in table
        ldb     A,X             ; Get address mode
        stb     AM              ; Save it
        clra                    ; Clear MSB of D, addressing mode is now in A:B (D)
        tfr     D,X             ; Put addressing mode in X
        ldb     LENGTHS,X       ; Get instruction length from table
        stb     LENGTH          ; Store it
        inc     LENGTH          ; Add one because it is a two byte op code
        bra     dism            ; Continue normal disassembly processing.

handle11                        ; Same logic as above, but use table for page 3 opcodes.
        lda     #1              ; Set page2/3 flag
        sta     PAGE23
        ldb     1,X             ; Get real opcode
        stb     OPCODE          ; Save it.
        leax    PAGE3,PCR       ; Pointer to start of table
        clra                    ; Set index into table to zero
search11
        cmpb    A,X             ; Check for match of opcode in table
        beq     found11         ; Branch if found
        adda    #3              ; Advance to next entry in table (entries are 3 bytes long)
        tst     A,X             ; Check entry
        beq     notfound11      ; If zero, then reached end of table
        bra     search11        ; If not, keep looking

notfound11                      ; Instruction not found, so is invalid.
        lda     #$11            ; Set opcode to 10
        sta     OPCODE
        LDA     #OP_INV         ; Set as instruction type invalid
        sta     OPTYPE
        lda     #AM_INVALID     ; Set as addressing mode invalid
        sta     AM
        lda     #1              ; Set length to one
        sta     LENGTH
        bra     dism            ; Disassemble as normal

found11                         ; Found entry in table
        adda    #1              ; Advance to instruction type entry in table
        ldb     A,X             ; Get instruction type
        stb     OPTYPE          ; Save it
        adda    #1              ; Advanced to address mode entry in table
        ldb     A,X             ; Get address mode
        stb     AM              ; Save it
        clra                    ; Clear MSB of D, addressing mode is now in A:B (D)
        tfr     D,X             ; Put addressing mode in X
        ldb     LENGTHS,X       ; Get instruction length from table
        stb     LENGTH          ; Store it
        inc     LENGTH          ; Add one because it is a two byte op code
        bra     dism            ; Continue normal disassembly processing.

not1011
        stb     OPCODE          ; Save the op code
        clra                    ; Clear MSB of D
        tfr     D,X             ; Put op code in X
        ldb     OPCODES,X       ; Get opcode type from table
        stb     OPTYPE          ; Store it
        ldb     OPCODE          ; Get op code again
        tfr     D,X             ; Put opcode in X
        ldb     MODES,X         ; Get addressing mode type from table
        stb     AM              ; Store it
        tfr     D,X             ; Put addressing mode in X
        ldb     LENGTHS,X       ; Get instruction length from table
        stb     LENGTH          ; Store it

; If addressing mode is indexed, get and save the indexed addressing
; post byte.

dism    lda     AM              ; Get addressing mode
        cmpa    #AM_INDEXED     ; Is it indexed mode?
        bne     NotIndexed      ; Branch if not
        ldx     ADDRESS,PCR     ; Get address of op code
                                ; If it is a page2/3 instruction, op code is the next byte after ADDRESS
        tst     PAGE23          ; Page2/3 instruction?
        beq     norm            ; Branch of not
        lda     2,X             ; Post byte is two past ADDRESS
        bra     getpb
norm    lda     1,X             ; Get next byte (the post byte)
getpb   sta     POSTBYT         ; Save it

; Determine number of additional bytes for indexed addressing based on
; postbyte. If most significant bit is 0, there are no additional
; bytes and we can skip the rest of the check.

        bpl     NotIndexed      ; Branch of MSB is zero

; Else if most significant bit is 1, mask off all but low order 5 bits
; and look up length in table.

        anda    #%00011111      ; Mask off bits
        leax    POSTBYTES,PCR   ; Lookup table of lengths
        lda     A,X             ; Get table entry
        adda    LENGTH          ; Add to instruction length
        sta     LENGTH          ; Save new length

NotIndexed

; At this point we have set: ADDRESS, OPCODE, OPTYPE, LENGTH, AM, PAGE23, POSTBYT
; Noew check for special instructions that change flow of control or otherwise
; need special handling rather than being directly executed.

; Invalid op code?
        lda     OPTYPE          ; Get op code type
        cmpa    #OP_INV         ; Is it an invalid instruction?
        lbeq    update          ; If so, nothing to do (length is 1 byte)

; SYNC instruction. Continue (emulate interrupt and then RTI
; happenning or mask interrupt and instruction continuing).

        lda     OPTYPE          ; Get op code type
        cmpa    #OP_SYNC        ; Is it a SYNC instruction?
        lbeq    update          ; If so, nothing to do (length is 1 byte)

; CWAI #$XX instruction. AND operand with CC. Set E flag in CC. Continue (emulate interrupt and then RTI happenning).

        lda     OPTYPE          ; Get op code type
        cmpa    #OP_CWAI        ; Is it a CWAI instruction?
        bne     tryswi
        ldx     ADDRESS         ; Get address of instruction
        lda     1,X             ; Get operand
        ora     #%10000000      ; Set E bit
        ora     SAVE_CC         ; Or with CC
        sta     SAVE_CC         ; Save CC
        bra     update          ; Done

tryswi

; SWI/SWI2/SWI3
;  Increment PC
;  Set E flag in CC (SWI only)
;  Save all registers except S
;  Set I in CC (SWI only)
;  new PC is [FFFA,FFFB] or [FFF4,FFF5] or [FFF2, FFF3]

;jmp
;  Next PC is operand effective address (possibly indirect).

;jsr
;  Next PC is operand effective address. Push return address-1 (Current address + 2) on stack.

;bsr/lbsr
;  Similar to jsr but EA is relative

;rti
;  Pop P. Pop PC. Increment PC to get next PC.

;rts
;  Pop PC. Increment PC to get next PC.

;bxx/lbxx
;These are executed but we change the destination of the branch so we
;catch whether they are taken or not.

;The code in the TRACEINST buffer will look like this:
;       JMP TRACEINST
;       ...
;       Bxx $03 (Taken)         ; Instruction being traced
;       JMP ReturnFromTrace
;Taken: JMP BranchTaken
;        ...

;Special case: If branch was taken (TAKEN=1), need to set next PC accordingly
;Next PC is Current address (ADDRESS) + operand (branch offset) + 2
;Set new PC to next PC

;puls pc,r,r,r
;  Set PC (and other registers) from S, adjust S.

;pulu pc,r,r,r
;  Set PC (and other registers) from U, adjust U.

;tfr r,pc
;  Get new PC value from other (simulated) register

;exg r,pc/exg pc,r
;  Swap PC and other (simulated) register value.

; Otherwise:
; Not a special instruction. We execute it from the buffer.
; Copy instruction and operands to RAM buffer (based on LEN, can be 1 to 5 bytes)

        ldx     ADDRESS         ; Address of instruction
        ldy     #BUFFER         ; Address of buffer
        clra                    ; Loop counter and index
copy    ldb    a,x              ; Get instruction byte
        stb    a,y              ; Write to buffer
        inca                    ; Increment counter
        cmpa   LENGTH           ; Copied all bytes?
        bne    copy

; Add a jump after the instruction to where we want to go after it is executed (ReturnFromTrace).

        ldb   #$7E              ; JMP $XXXX instruction
        stb   a,y               ; Store in buffer
        inca                    ; Advance buffer
        ldx   #ReturnFromTrace  ; Destination address of JMP 
        stx   a,y               ; Store in buffer

; Restore registers from saved values.

        sts   OURS              ; Save this program's stack pointers
        stu   OURU

        ldb   SAVE_B
        ldx   SAVE_X
        ldy   SAVE_Y
        lds   SAVE_S
        ldu   SAVE_U
        lda   SAVE_DP
        tfr   a,dp
        lda   SAVE_CC
        tfr   a,cc
        lda   SAVE_A            ; FIXME: This changes CC

; Call instruction in buffer. It is followed by a JMP ReturnFromTrace so we get back.

        jmp   BUFFER

ReturnFromTrace

; Restore saved registers (except PC).

        sta   SAVE_A
        stb   SAVE_B
        stx   SAVE_X
        sty   SAVE_Y
        sts   SAVE_S
        stu   SAVE_U
        tfr   cc,a
        sta   SAVE_CC
        tfr   dp,a
        sta   SAVE_DP

; Restore this program's stack pointers so RTS etc. will still work.

        lds   OURS
        ldu   OURU

; Set this program's DP register to zero just in case calling program changed it.

        clra
        tfr   a,dp

; Update new ADDRESS value based on instruction address and length

update  clra                    ; Set MSB to zero
        ldb   LENGTH            ; Get length byte
        addd  ADDRESS           ; 16-bit add
        std   ADDRESS           ; Store new address value

; And return.

        rts

;------------------------------------------------------------------------
; Display register values
; Uses values in SAVED_A etc.
; e.g.
; PC=FEED A=01 B=02 X=1234 Y=2345 S=2000 U=2000 DP=00 CC=8D
; PC=FEED A=01 B=02 X=1234 Y=2345 S=2000 U=2000 DP=00 CC=10001101
; PC=FEED A=01 B=02 X=1234 Y=2345 S=2000 U=2000 DP=00 CC=10001101 (EFHINZVC)
; PC=FEED A=01 B=02 X=1234 Y=2345 S=2000 U=2000 DP=00 CC=E...NZ.C
; TODO: Show CC in binary

DisplayRegs
        leax  MSG1,PCR
        lbsr  PrintString
        ldx   SAVE_PC
        lbsr  PrintAddress

        leax  MSG2,PCR
        lbsr  PrintString
        lda   SAVE_A
        lbsr  PrintByte

        leax  MSG3,PCR
        lbsr  PrintString
        lda   SAVE_B
        lbsr  PrintByte

        leax  MSG4,PCR
        lbsr  PrintString
        ldx   SAVE_X
        lbsr  PrintAddress

        leax  MSG5,PCR
        lbsr  PrintString
        ldx   SAVE_Y
        lbsr  PrintAddress

        leax  MSG6,PCR
        lbsr  PrintString
        ldx   SAVE_S
        lbsr  PrintAddress

        leax  MSG7,PCR
        lbsr  PrintString
        ldx   SAVE_U
        lbsr  PrintAddress

        leax  MSG8,PCR
        lbsr  PrintString
        lda   SAVE_DP
        lbsr  PrintByte

        leax  MSG9,PCR
        lbsr  PrintString
        lda   SAVE_CC
        lbsr  PrintByte
        lbsr  PrintCR

        rts

MSG1    FCC     "PC="
        FCB     EOT
MSG2    FCC     "A="
        FCB     EOT
MSG3    FCC     "B="
        FCB     EOT
MSG4    FCC     "X="
        FCB     EOT
MSG5    FCC     "Y="
        FCB     EOT
MSG6    FCC     "S="
        FCB     EOT
MSG7    FCC     "U="
        FCB     EOT
MSG8    FCC     "DP="
        FCB     EOT
MSG9    FCC     "CC="
        FCB     EOT

;------------------------------------------------------------------------
; Disassemble an instruction. Uses ASSIST09 ROM code.
; e.g. 
; 1053 2001 86 01    lda     #$01

Disassemble
        ldx     SAVE_PC         ; Get address of instruction
        stx     ADRS            ; Pass it to the disassembler
        jsr     DISASM          ; Disassemble one instruction
        rts
