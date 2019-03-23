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

OPCODES equ     $C909
PAGE2   equ     $CB09
PAGE3   equ     $CB7C
LENGTHS equ     $C8DC
MODES   equ     $CA09
POSTBYTES equ   $C8E9

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

OP_INV  equ     0
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
        leax    2,y
        adda    #1
        addb    #1
        exg     a,b
        andcc   #$00
        orcc    #$FF
        cmpu    #$4321
        fcb     $01             ; Invalid instruction

        bra     testcode

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
loop    jsr     step
        jsr     GetChar         ; Wait for a key press
        bra     loop

;------------------------------------------------------------------------
; Step: Step one instruction
; Get address to step.
; Call Trace
; Display register values
; Disassemble next instruction (Set ADDR, call DISASM)
; Return

step    jsr     Trace           ; Trace an instruction
        jsr     DisplayRegs     ; Display register values
        jsr     Disassemble     ; Disassemble the instruction
        ldx     ADDRESS         ; Get next address
        stx     SAVE_PC         ; And store as last PC
        rts

;------------------------------------------------------------------------
; Trace one instruction.
; Input: Address of instruction in ADDRESS.
; Returns: Updates saved register values.
;
; TODO: How to handle PC relative instructions?

Trace   CLR     PAGE23          ; Clear page2/3 flag
        LDX     ADDRESS,PCR     ; Get address of instruction
        LDB     ,X              ; Get instruction op code
        CMPB    #$10            ; Is it a page 2 16-bit opcode prefix with 10?
        BEQ     handle10        ; If so, do special handling
        CMPB    #$11            ; Is it a page 3 16-bit opcode prefix with 11?
        BEQ     handle11        ; If so, do special handling
        LBRA    not1011         ; If not, handle as normal case

handle10                        ; Handle page 2 instruction
        LDA     #1              ; Set page2/3 flag
        STA     PAGE23
        LDB     1,X             ; Get real opcode
        STB     OPCODE          ; Save it.
        LEAX    PAGE2,PCR       ; Pointer to start of table
        CLRA                    ; Set index into table to zero
search10
        CMPB    A,X             ; Check for match of opcode in table
        BEQ     found10         ; Branch if found
        ADDA    #3              ; Advance to next entry in table (entries are 3 bytes long)
        TST     A,X             ; Check entry
        BEQ     notfound10      ; If zero, then reached end of table
        BRA     search10        ; If not, keep looking

notfound10                      ; Instruction not found, so is invalid.
        LDA     #$10            ; Set opcode to 10
        STA     OPCODE
        LDA     #OP_INV         ; Set as instruction type invalid
        STA     OPTYPE
        LDA     #AM_INVALID     ; Set as addressing mode invalid
        STA     AM
        LDA     #1              ; Set length to one
        STA     LENGTH
        LBRA    dism            ; Disassemble as normal

found10                         ; Found entry in table
        ADDA    #1              ; Advance to instruction type entry in table
        LDB     A,X             ; Get instruction type
        STB     OPTYPE          ; Save it
        ADDA    #1              ; Advanced to address mode entry in table
        LDB     A,X             ; Get address mode
        STB     AM              ; Save it
        CLRA                    ; Clear MSB of D, addressing mode is now in A:B (D)
        TFR     D,X             ; Put addressing mode in X
        LDB     LENGTHS,X       ; Get instruction length from table
        STB     LENGTH          ; Store it
        INC     LENGTH          ; Add one because it is a two byte op code
        BRA     dism            ; Continue normal disassembly processing.

handle11                        ; Same logic as above, but use table for page 3 opcodes.
        LDA     #1              ; Set page2/3 flag
        STA     PAGE23
        LDB     1,X             ; Get real opcode
        STB     OPCODE          ; Save it.
        LEAX    PAGE3,PCR       ; Pointer to start of table
        CLRA                    ; Set index into table to zero
search11
        CMPB    A,X             ; Check for match of opcode in table
        BEQ     found11         ; Branch if found
        ADDA    #3              ; Advance to next entry in table (entries are 3 bytes long)
        TST     A,X             ; Check entry
        BEQ     notfound11      ; If zero, then reached end of table
        BRA     search11        ; If not, keep looking

notfound11                      ; Instruction not found, so is invalid.
        LDA     #$11            ; Set opcode to 10
        STA     OPCODE
        LDA     #OP_INV         ; Set as instruction type invalid
        STA     OPTYPE
        LDA     #AM_INVALID     ; Set as addressing mode invalid
        STA     AM
        LDA     #1              ; Set length to one
        STA     LENGTH
        BRA     dism            ; Disassemble as normal

found11                         ; Found entry in table
        ADDA    #1              ; Advance to instruction type entry in table
        LDB     A,X             ; Get instruction type
        STB     OPTYPE          ; Save it
        ADDA    #1              ; Advanced to address mode entry in table
        LDB     A,X             ; Get address mode
        STB     AM              ; Save it
        CLRA                    ; Clear MSB of D, addressing mode is now in A:B (D)
        TFR     D,X             ; Put addressing mode in X
        LDB     LENGTHS,X       ; Get instruction length from table
        STB     LENGTH          ; Store it
        INC     LENGTH          ; Add one because it is a two byte op code
        BRA     dism            ; Continue normal disassembly processing.

not1011
        STB     OPCODE          ; Save the op code
        CLRA                    ; Clear MSB of D
        TFR     D,X             ; Put op code in X
        LDB     OPCODES,X       ; Get opcode type from table
        STB     OPTYPE          ; Store it
        LDB     OPCODE          ; Get op code again
        TFR     D,X             ; Put opcode in X
        LDB     MODES,X         ; Get addressing mode type from table
        STB     AM              ; Store it
        TFR     D,X             ; Put addressing mode in X
        LDB     LENGTHS,X       ; Get instruction length from table
        STB     LENGTH          ; Store it

; If addressing mode is indexed, get and save the indexed addressing
; post byte.

dism    LDA     AM              ; Get addressing mode
        CMPA    #AM_INDEXED     ; Is it indexed mode?
        BNE     NotIndexed      ; Branch if not
        LDX     ADDRESS,PCR     ; Get address of op code
                                ; If it is a page2/3 instruction, op code is the next byte after ADDRESS
        TST     PAGE23          ; Page2/3 instruction?
        BEQ     norm            ; Branch of not
        LDA     2,X             ; Post byte is two past ADDRESS
        BRA     getpb
norm    LDA     1,X             ; Get next byte (the post byte)
getpb   STA     POSTBYT         ; Save it

; Determine number of additional bytes for indexed addressing based on
; postbyte. If most significant bit is 0, there are no additional
; bytes and we can skip the rest of the check.

        BPL     NotIndexed      ; Branch of MSB is zero

; Else if most significant bit is 1, mask off all but low order 5 bits
; and look up length in table.

        ANDA    #%00011111      ; Mask off bits
        LEAX    POSTBYTES,PCR   ; Lookup table of lengths
        LDA     A,X             ; Get table entry
        ADDA    LENGTH          ; Add to instruction length
        STA     LENGTH          ; Save new length

NotIndexed

; At this point we have set: ADDRESS, OPCODE, OPTYPE, LENGTH, AM, PAGE23, POSTBYT

; Check for special instructions that change flow of control:

;invalid op code:
;  do nothing (length is 1 byte)

;swi/swi2/swi3
;  Increment PC
;  Set E flag in CC (SWI only)
;  Save all registers except S
;  Set I in CC (SWI only)
;  new PC is [FFFA,FFFB] or [FFF4,FFF5] or [FFF2, FFF3]

;cwai
;  ANDD operand with CC
;  Set E flag in CC
;  Continue (emulate interrupt and then RTI happenning)

;sync
;  Continue (emulate interrupt and then RTI happenning)

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

        clra                    ; Set MSB to zero
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

DisplayRegs
        leax  MSG1,PCR
        jsr   PrintString
        ldx   SAVE_PC
        jsr   PrintAddress

        leax  MSG2,PCR
        jsr   PrintString
        lda   SAVE_A
        jsr   PrintByte

        leax  MSG3,PCR
        jsr   PrintString
        lda   SAVE_B
        jsr   PrintByte

        leax  MSG4,PCR
        jsr   PrintString
        ldx   SAVE_X
        jsr   PrintAddress

        leax  MSG5,PCR
        jsr   PrintString
        ldx   SAVE_Y
        jsr   PrintAddress

        leax  MSG6,PCR
        jsr   PrintString
        ldx   SAVE_S
        jsr   PrintAddress

        leax  MSG7,PCR
        jsr   PrintString
        ldx   SAVE_U
        jsr   PrintAddress

        leax  MSG8,PCR
        jsr   PrintString
        lda   SAVE_DP
        jsr   PrintByte

        leax  MSG9,PCR
        jsr   PrintString
        lda   SAVE_CC
        jsr   PrintByte
        jsr   PrintCR

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
