* 6309 Examples

************************************************************************

* Determine whether processor is 6309 or 6809
* Returns Z clear if 6309, set if 6809

CHK309  PSHS    D               ; Save Reg-D
        FDB     $1043           ; 6309 COMD instruction (COMA on 6809)
        CMPB    1,S             ; not equal if 6309
        PULS    D,PC            ; exit, restoring D

************************************************************************

* Determine whether processor is in Emulation Mode or Native Mode
* Works for 6809 or 6309.
* Returns Z clear if Emulation (or 6809), Z set if Native
CHKNTV  PSHSW                   ;Ignored on 6809 (no stack data)
        PSHS    U,Y,X,DP,D,CC   ;Save all registers
        LEAU    CHKX68,PCR      ;Special exit for 6809 processor
        LDY     #0
        PSHS    U,Y,X,D         ;Push 6809 trap, Native marker, PC temps
        ORCC    #$D0            ;Set CC.E (entire), no interrupts
        PSHS    U,Y,X,DP,D,CC   ;Save regs
        LEAX    CHKXIT,PCR
        STX     10,S            ;Preset Emulation mode PC slot
        STX     12,S            ;Preset Native mode PC slot
        RTI                     ;End up at CHKXIT next
CHKXIT  LDX     ,S++            ;In NATIVE, get 0; in EMULATION, non-zero
        BEQ     CHKNTV9
        LEAS    2,S             ;Discard native marker in EMULATION mode
CHKNTV9 TFR     CC,A
        ANDA    #$0F            ;Keep low CC value
        AIM     #$F0,0,S        ;Keep high bits of stacked CC
        ORA     2,S             ;Combine CC values (skip over 6809 trap)
        STA     2,S             ; and save on stack
        PULSW                   ;Pull bogus W (does RTS to CHKX68 on 6809)
        PULS    CC,D,DP,X,Y,U   ;Restore 6309 registers and return
        PULSW
        RTS
CHKX68  PULS    CC,D,DP,X,Y,U,PC ;Restore 6809 registers and return

************************************************************************

* Force processor to Emulation Mode or Native Mode,
* depending on value in Register A
* A=0 Emulation Mode
* A<>0 Native Mode
* Works for 6309 only.
SETPMD  TSTA
        BNE     SETNTV
        LDMD    #$00            ; Force Emulation Mode, normal FIRQ
        BRA     SETPND
SETNTV  LDMD    #$01            ; Force Native Mode, normal FIRQ
SETPND  RTS

************************************************************************

* Change processor to Emulation Mode or Native Mode,
* depending on value in Register A
* A=0 Emulation Mode
* A<>0 Native Mode
*
* Assumes direct page location <DMDREG contains an
* accurate image of the MD register contents (The
* program must initialize <DMDREG to $00 at start-up).
*
* Since LDMD accepts only an immediate operand, we
* push the appropriate LDMD / RTS sequence onto the
* stack and call it as a subroutine.
* Works for 6309 only.

DMDREG  EQU     $0050

SETPMD1 PSHS    X,D,CC          ;Save registers
        ORCC    #$50            ;Make operation indivisible
        LDB     <DMDREG         ;Get mode register image
        ANDB    #$FE            ; strip mode selection bit (Emulation)
        TSTA
        BEQ     SETMD2          ;Skip next part if want Emulation
        ORB     #$01            ;Set Native mode bit (INCB lacks clarity)
SETMD2  STB     <DMDREG         ;B has right value — update register image
        LDA     #$39            ;RTS op-code
        EXG     B,A             ;Now A = LDMD’s immed. operand, B = RTS
        LDX     #$103D          ;X has LDMD’s 2-byte op-code
        EXG     D,X             ;Now D:X = 10 3D <value> 39
        PSHS    X,D             ;Put subroutine on stack
        JSR     ,S              ;Call subroutine, setting mode
        LEAS    4,S             ; throw away subroutine when done.
        PULS    CC,D,X,PC       ; and return to caller.

************************************************************************

* 6809-style FIRQ routine, assuming all registers
* must be preserved.
*
* This routine uses 34 cycles for register stacking
* overhead; the FIRQ itself takes 10 cycles, for a
* total overhead of 44 cycles.

FIRQVC  PSHS    U,Y,X,DP,B,A    ;Save registers — 14 cycles
        LDA     >DEVSTS         ;Clear the interrupt source
*       ...                     ; (do rest of service here)
        PULS    A,B,DP,X,Y,U    ;Restore registers — 14 cycles
        RTI                     ;Restore CC and PC — 6 cycles

DEVSTS  EQU     *

************************************************************************

* 6309-style FIRQ routine, assuming FIRQ automatically
* preserves all registers.
*
* This routine uses 15 cycles for register stacking
* overhead; the FIRQ itself takes 19 cycles, for a
* total overhead of 34 cycles.

FIRQVC1 LDA     >DEVSTS         ;Clear the interrupt source
*       ...                     ; (do rest of service here)
        RTI                     ;Restore all registers — 15 cycles

************************************************************************

* Main program. Decrements W register until 0, then
* executes an RTS
MAIN    LDW     #1000           ;Delay value
DELAY   DECW                    ; (loop until zero)
        BNE     DELAY
        RTS                     ;Exit

************************************************************************

* Interrupt service routine. This routine
* transfers 16 bytes of data from IOADDR to
* the buffer pointed to by >BFADDR

IRQSVC  LDX     #IOADDR
        LDY     >BFADDR
        LDW     #16             ;byte count
        TFM     X,Y+
        RTI                     ;now W is zero

IOADDR  EQU     *
BFADDR  EQU     *

************************************************************************

* Main program. Decrements W register until 0, then
* executes an RTS

MAIN1   LDW     #1000           ;Delay value
DELAY1  DECW                    ; (loop until zero)
        BNE     DELAY1
        RTS                     ;Exit

************************************************************************

* Revised interrupt service routine. This routine
* transfers 16 bytes of data from IOADDR to the
* buffer pointed to by >BFADDR, preserving W.

IRQSVC1 PSHSW                   ;save W
        LDX     #IOADDR
        LDY     >BFADDR
        LDW     #16
        TFM     X,Y+
        PULSW
        RTI                     ;byte count
                                ;now W is zero

************************************************************************

* Routine to use W “safely” as a parameter
* to the TFM instruction. Since TFM is
* interruptible, we explicitly mask them
* for the entire time that the W register
* contents are important.

BLKCLR  CLR     ,-S             ;Get a ZERO to the stack
        LDY     >BFADDR         ;Address of buffer to clear
        ORCC    #$50            ;No IRQ, no FIRQ (hope NMI is OK!)
        LDW     #2048           ; buffer size is 2K
* An interrupt that changed W during
* execution of the TFM would be disastrous!
        TFM     X,Y+            ; clear the buffer
        ANDCC   #$AF            ;FIRQ, IRQ OK now.
        LEAS    1,S             ;clean the stack
        RTS

************************************************************************

* Example of a TRAP interrupt service routine.
* This routine dispatches ILLEGAL OPCODE interrupts
* to a ROM debugger at address DBGENT, while it
* handles DIVISION BY ZERO interrupts by setting the
* carry bit (CC.C) on the stack frame. Note that the
* routine works for both Native and Emulation modes.

SVTRAP  BITMD   #%01000000      ;MD.6 non-zero if ILLEGAL OPCODE
        BNE      DBGENT         ; so go to ROM debugger
        OIM     #$01,0,S        ;DIVISION BY ZERO; set LSB of stacked CC
        RTI                     ;Return past DIVD or DIVQ, with carry set.

DBGENT

************************************************************************

* Example to move 16 bytes from START to START-1
* using Post-Increment TFM.

MOVEIT  LDX     #START          ;Source pointer
        LDU     #START-1        ;Destination pointer
        LDW     #16             ;Byte count
        TFM     X+,U+           ;Post-Increment TFM
        RTS                     ;Return when done.
        RMB     1               ;This is START-1
START   FCB     0,1,2,3,4,5,6,7 ;Data to move
        FCB     8,9,10,11,12,13,14,15
XEND    EQU      *


************************************************************************

* Example to move 16 bytes from START to START+1
* using Post-Increment TFM. (A bad idea!)

MOVEIT1 LDX     #START1         ;Source pointer
        LDU     #START1+1       ;Destination pointer
        LDW     #16             ;Byte count
        TFM     X+,U+           ;Post-Increment TFM
        RTS                     ;Return when done.
START1  FCB     0,1,2,3,4,5,6,7 ;Data to move
        FCB     8,9,10,11,12,13,14,15
XEND1   RMB     1               ; last byte gets moved here

************************************************************************

* Example to move 16 bytes from START to START+1
* using Post-Decrement TFM.

MOVEIT2 LDX     #(START2+16-1)  ;Source pointer
        LDU     #(START2+16-1)+1 ;Destination pointer
        LDW     #16             ;Byte count
        TFM     X-,U-           ;Post-Decrement TFM
        RTS                     ;Return when done.
START2  FCB     0,1,2,3,4,5,6,7 ;Data to move
        FCB     8,9,10,11,12,13,14,15
XEND2   RMB     1               ; last byte gets moved here.

************************************************************************

* Example to read 256 bytes from the HDDATA
* (sector buffer) peripheral input register of a
* no-handshake hard disk controller to the
* buffer at register X

HDREAD  PSHS    U,X,CC          ;Save pointers
        LDU     #HDDATA         ;Source pointer
        LDW     #256            ;Byte count
        ORCC    #$50            ;No interrupts!
        TFM     U,X+            ;Peripheral input TFM
        PULS    CC,X,U,PC       ;Return when done.

HDDATA  EQU     *

************************************************************************

* Example to write 256 bytes to the HDDATA
* (sector buffer) peripheral input register of a
* no-handshake hard disk controller from the
* buffer at register X

HDWRIT  PSHS    U,X             ;Save pointers
        LDU     #HDDATA         ;Destination pointer
        LDW     #256            ;Byte count
        TFM     X+,U            ;Peripheral output TFM
        PULS    X,U,PC          ;Return when done.

************************************************************************

* Example to move 4096 bytes
* from (X) to (Y)
* using Peripheral Input TFM
* and a loop.

MOVEIT3 PSHS    Y,X,B           ;Save register values
        LDB     #(4096/256)     ;Number of loops
MOVE2   PSHS    CC
        ORCC    #$50            ;No interrupts
        LDW     #256            ;Byte count per loop
        TFM     X+,Y+           ;Post-Increment TFM (< 1ms at 1MHz)
        PULS    CC              ;Enable interrupts!
        DECB                    ;Decrement loop counter
        BNE     MOVE2
        PULS    B,X,Y,PC        ;Return when done.

************************************************************************

* Example to clear 256 bytes at (X)
* using Peripheral Input TFM.
* This example uses 15 bytes.

MCLEAR  PSHS    X               ;Save register values
        CLR     ,-S             ;ZERO on stack
        LDW     #256            ;Byte count
        TFM     S,Y+            ;Copy 256 Zeros to (X)
        LEAS    1,S             ;Clean up stack
        PULS    X,PC            ;Return when done.

************************************************************************

* Example to clear 256 bytes at (X)
* using Post-Increment TFM.
* This example also uses 15 bytes.

MCLEAR2 PSHS    Y,X             ;Save register values
        LEAY    1,X             ;Duplicate pointer + 1
        CLR     ,X              ;ZERO 1st byte
        LDW     #255            ;Byte count - 1
        TFM     X+,Y+           ;Duplicate 255 Zeros to (Y)
        PULS    X,Y,PC          ;Return when done.

************************************************************************

* Example showing 16 bytes of stack data
* initialized using Post-Decrement TFM.

SAMPLE  LEAX    IDATA+15,PCR    ;Point at stack initializers
        LDW     #16             ;Byte count
        LEAS    -1,S            ;Adjust SP to point at 1st byte pushed
        TFM     X-,S-           ;Post-Decrement TFM
        LEAS    1,S             ;Adjust SP to point at last byte pushed
*       ...                     ;Rest of routine goes here.
IDATA   FCB     0,1,2,3,4,5,6,7 ;Data to initialize stack with
        FCB     8,9,10,11,12,13,14,15

************************************************************************

* Example showing 16 bytes of stack data
* initialized (unwisely) using Post-Increment TFM.

SAMPLE1 LEAX    IDATA1,PCR      ;Point at stack initializers
        LDW     #16             ;Byte count
        LEAS    -16,S           ;Adjust SP, then copy upwards
        TFM     X+,S+           ;Post-Increment TFM
*** NMI or other interrupt here overwrites initialized stack!
        LEAS    -16,S           ;Move SP back to 1st byte pushed
*       ...                     ;Rest of routine goes here.
IDATA1  FCB     0,1,2,3,4,5,6,7 ;Data to initialize stack with
        FCB     8,9,10,11,12,13,14,15

************************************************************************

* 16 x 16 unsigned multiplication using 6809
* MUL instruction. Multiplies D by (0,X).
* Returns 32-bit result in D:X

MUL16   CLR     ,-S             ;temp. results
        CLR     ,-S
        CLR     ,-S
        CLR     ,-S
        PSHS    D
        LDA     1,X
MUL                             ;D lo byte * (X) lo byte
        STD     2+2,S           ; <61 cycles so far>
        LDA     1,S
        LDB     0,X
        MUL                     ;D lo byte * (X) hi byte
        ADDD    2+1,S           ; (accumulate result)
        STD     2+1,S
        LDA     2+0,S
        ADCA    #0
        STA     2+0,S           ; <46 more cycles>
        LDA     0,S
        LDB     1,X
        MUL                     ;D hi byte * (X) lo byte
        ADDD    2+1,S
        STD     2+1,S
        LDA     2+0,S
        ADCA    #0
        STA     2+0,X           ; <46 more cycles>
        LDA     0,S
        LDB     0,X
        MUL                     ;D hi byte * (X) hi byte
        ADDD    2+0,S           ; (accumulate result)
        STD     2+0,S           ; <34 more cycles>
        LEAS    2,S             ;discard old value of D
        PULS    D,X,PC          ;Exit with result in X:X <16 more>

************************************************************************

* 16 x 16 signed multiplication using 6309
* MULD instruction. Multiplies D by (0,X).
* Returns 32-bit result in D:X

MUL16A  MULD    0,X             ;results to D:W
        TFR     W,X             ; now results in D:X
        RTS

************************************************************************

* Example to use single-bit instructions
* anywhere in memory. This example sets
* carry based on bit 4 of variable FLAGS.

FLAGS   EQU     $10

        PSHS    A,DP            ;Save DP
        LDA     #(FLAGS/256)    ;Set up new DP register
        TFR     A,DP
        LDBT    CC,0,4,FLAGS    ;Load CC.C from FLAGS.4
        PULS    DP,A

************************************************************************

* Example to use single-bit instructions to initialize
* a peripheral from a data byte. Each bit position of
* the data byte represents a pair of peripheral addresses.
* If the bit is clear, we initialize the peripheral by
* writing to the lower address. If the bit is set, we
* initialize the peripheral by writing to the higher
* address.
*
* Some types of video peripherals use similar
* initialization sequences.
*
* Enter with value in A, peripheral at VIDADR.
* Uses direct page variable TEMP as scratch.

VCINIT  STA     <TEMP
        LDD     #$0800          ;Byte count, offset
        LDX     #VIDADR         ;Note: must be even!
VCLOOP  LDBT    B,0,0,<TEMP     ;Make B #0 or #1
        STA     B,X             ;Write anything to correct address
        LSR     <TEMP           ;Line up next TEMP.0
        LEAX    2,X             ;Line up next peripheral address
        DECA
        BNE     VCLOOP          ;Loop for each of 8 bits.
        RTS

TEMP    EQU     $10
VIDADR  EQU     *

************************************************************************

* Example to use 6309 single-bit instructions to
* move a 2-bit field from TEMP1 to TEMP2. Note that
* no registers are changed, and that the field
* starts at a different bit position in each TEMP.

MOVFLD  LDBT    CC,0,3,TEMP1    ;1st bit to carry
        STBT    CC,0,5,TEMP2    ; carry to destination.
        LDBT    CC,0,4,TEMP1    ;2nd bit to carry
        STBT    CC,0,6,TEMP2    ; carry to destination.
        RTS

* Here’s the same thing, in old 6809 instructions.
MOVFLD1 PSHS    A
        LDA     <TEMP2
        ANDA    #%10011111      ;Strip old field value (use AIM on 6309)
        STA     <TEMP2
        LDA     <TEMP1
        ANDA    #%00011000      ;Get just field being copied
        ASLA                    ;Align to destination bit position
        ASLA                    ; (shift bit 3 to bit 5, etc.).
        ORA     <TEMP2          ;OR copied data into TEMP1
        STA     <TEMP2
        PULS    A,PC

TEMP1   EQU     $10
TEMP2   EQU     $11

************************************************************************

* Example to use 6309 single-bit instructions to
* move a 2-bit field from TEMP1 to TEMP2. Note that
* no registers are changed, and that the field
* starts at a different bit position in each TEMP.

ORBFLD  LDBT    CC,0,3,TEMP1    ;1st bit to carry
        BOR     CC,0,5,TEMP2    ; OR in current value
        STBT    CC,0,5,TEMP2    ; carry to destination.
        LDBT    CC,0,4,TEMP1    ;2nd bit to carry
        BOR     CC,0,6,TEMP2    ; OR in current value
        STBT    CC,0,6,TEMP2    ; carry to destination.
        RTS

* Here’s the same thing, in old 6809 instructions.

ORBFLD1 PSHS A
        LDA     <TEMP1
        ANDA    #%00011000      ; Get just field being copied
        ASLA                    ;Align to destination bit position
        ASLA                    ; (shift bit 3 to bit 5, etc.).
        ORA     <TEMP2          ;OR copied data into TEMP1
        STA     <TEMP2
        PULS    A,PC

************************************************************************

* RESET routine.
*
* If this is initial power-up, initialize all peripherals and memory.
* If this is a RESET, just initialize the peripherals

RESET   JSR     PINIT           ;Initialize peripherals
        TFR     V,X             ;Check V register for $FFFF
        CMPX    #$FFFF
        BNE     WARMST          ;If not $FFFF, this is just a reset
* Here, we know it’s a power-up. Init memory and store “reset” flag
* value in V
COLDST  JSR     MINIT           ;Initialize memory
        LDD     #$1234          ; Set V register (any value but $FFFF)
        TFR     D,V
WARMST  JMP     >PROGRM         ;RESET complete. Go do the program!

PROGRM  EQU     *
MINIT   EQU     *
PINIT   EQU     *

************************************************************************

* Example: loading another register from V
* Start by initializing V early in the program

        LDD     #$1234
        TFR     D,V
*       ....
* Much later in the program, we need the value $1234 in a
* lot of places. Two of the places might look like this:
        TFR     V,X             ;Get $1234 to X
*       ...
        ADDR    V,U             ;Add $1234 to U
*       ...
