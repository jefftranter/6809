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
LEN     RMB     1               ; Length of instruction
AM      RMB     1               ; Addressing mode
BUFFER  RMB     8               ; Buffer holding traced instruction (up to 5 bytes plus JMP XXXX)
OURSP   RMB     2               ; This program's stack pointer

        ORG     $2000
        
;------------------------------------------------------------------------
; Code for testing trace function

testcode
        nop
        lda     #$01
        ldb     #$02
        ldx     #$1234
        ldy     #$2345
        lds     #$7000
        ldu     #$7100
        leax    1,x
        exg     a,b
        andcc   #$00
        orcc    #$FF
        cmpu    #$4321

        ORG     $3000

;------------------------------------------------------------------------
; Main program
; Trace test code.
main
        ldx     #testcode       ; Start address of code to trace
        sta     ADDRESS
        jsr     step
        bra     main

;------------------------------------------------------------------------
; Step: Step one instruction
; Get address to step.
; Call Trace
; Display register values
; Disassemble next instruction (Set ADDR, call DISASM)
; Return

step    jsr     Trace
        jsr     DisplayRegs
        jsr     Disassemble
        rts

;------------------------------------------------------------------------
; Trace one instruction.
; Input: Address of instruction in ADDRESS.
; Returns: Updates saved register values.
;
; TODO: How to handle PC relative instructions?

Trace

; Get and save op code.

; Call GetLength to get next instruction opcode byte from ADDRESS.
; Save in LENGTH.

; Get and save instruction type from table.

; Get addressing mode from table.

; Copy instruction and operands to RAM buffer (based on LEN, can be 1 to 5 bytes)

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
ReturnFromTrace

;Special case: If branch was taken (TAKEN=1), need to set next PC accordingly
;Next PC is Current address (ADDR) + operand (branch offset) + 2
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
; Add a jump after the instruction to where we want to go after it is executed
; Restore registers from saved values.
; Call instruction in buffer.
; It is followed by a JMP ReturnFromTrace so we get back

;ReturnFromTrace:

; Restore saved registers (except PC).
; Update new PC value and ADDRESS based on instruction address and lenght
; Restore this program's stack pointer so RTS etc. will still work.
; Restore DP?
; Return.

;------------------------------------------------------------------------
; Return length of instruction, given start address.
; Handles page 2/3 opcodes as well as indexed addressing based on the postbyte.
; Invalid instructions return a length of one.
; Input: Address of opcode in X
; Returns: Length of instruction in A

GetLength
        rts                     ; TODO: Implement


;------------------------------------------------------------------------
; Display register values
; Uses values in SAVED_A etc.
; e.g.
; PC=FEED A=01 B=02 X=1234 Y=2345 U=2000 S=2000 DP=00 CC=8D (EfhiNZvC)

DisplayRegs
        rts                     ; TODO: Implement

;------------------------------------------------------------------------
; Disasemble an instruction.
; e.g. 
; 1053 2001 86 01    lda     #$01

Disassemble
        rts                     ; TODO: Implement

