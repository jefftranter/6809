; Port of Woz Monitor to the 6809.
; Jeff Tranter <tranter@pobox.com>
;
;***********************************************************************

;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976

; Variables

        ORG     $1000

XAML    RMB     1               ; Last "opened" location Low
XAMH    RMB     1               ; Last "opened" location High
STL     RMB     1               ; Store address Low
STH     RMB     1               ; Store address High
L       RMB     1               ; Hex value parsing Low
H       RMB     1               ; Hex value parsing High
YSAV    RMB     1               ; Used to see if hex value is given
MODE    RMB     1               ; $00=XAM, $7F=STOR, $AE=BLOCK XAM

IN      RMB     128             ; Input buffer

; Constants

ACIAC   EQU     $A000           ; 6850 ACIA status/control register
ACIAD   EQU     $A001           ; 6850 ACIA data register

; Program

        ORG     $2000           ; To run from RAM
;       ORG     $FF00           ; To run from ROM

RESET   ORCC    #$10            ; SEI, mask interrupts
        LDS     #$3000          ; Initialize stack
        LDA     #3              ; Reset ACIA
        STA     ACIAC
        LDA     #$15            ; Control register setting
        STA     ACIAC           ; Initialize ACIA to 8 bits and no parity

NOTCR   CMPA    #'_'            ; Was key "_" ?
        BEQ     BACKSPACE       ; Yes.
        CMPA    #$1B            ; ESC?
        BEQ     ESCAPE          ; Yes.
        LEAY    1,Y             ; Advance text index.
        BPL     NEXTCHAR        ; Auto ESC if > 127.
ESCAPE  LDA     #'\'            ; "\".
        JSR     ECHO            ; Output it.
GETLINE LDA     #$0D            ; CR.
        JSR     ECHO            ; Output it.
        LDY     #$01            ; Initialize text index.
BACKSPACE
        LEAY    -1,Y            ; Back up text index.
;        BEQ     GETLINE         ; Beyond start of line, reinitialize.
NEXTCHAR
        LDA     ACIAC           : Read ACIA
        BITA    #$01            ; Key ready?
        BEQ     NEXTCHAR        ; Loop until ready.
        LDA     ACIAD           ; Load character.
        STA     IN,Y            ; Add to text buffer.
        JSR     ECHO            ; Display character.
        CMPA    #$0D            ; CR?
        BNE     NOTCR           ; No.
        LDY     #$FF            ; Reset text index.
        LDA     #$00            ; For XAM mode.
        LDX     #0              ; 0->X.
SETSTOR ASLA                    ; Leaves $7B if setting STOR mode.
SETMODE STA     MODE            ; $00=XAM $7B=STOR $AE=BLOK XAM
BLSKIP  LEAY    1,Y             ; Advance text index.
NEXTITEM
        LDA     IN,Y            ; Get character.
        CMPA    #$0D            ; CR?
        BEQ     GETLINE         ; Yes, done this line.
        CMPA    #'.'            ; "."?
        BCS     BLSKIP          ; Skip delimiter.
        BEQ     SETMODE         ; Yes. Set STOR mode.
        CMPA    #':'            ; ":"?
        BEQ     SETSTOR         ; Yes. Set STOR mode.
        CMPA    #'R'            ; "R"?
        BEQ     RUN             ; Yes. Run user program.
        STX     L               ; $00-> L.
        STX     H               ; and H.
        STY     YSAV            ; Save Y for comparison.
NEXTHEX LDA     IN,Y            ; Get character for hex test.
        EORA    #$B0            ; Map digits to $0-9.
        CMPA    #$0A            ; Digit?
        BCS     DIG             ; Yes.
        ADCA    #$88            ; Map letter "A"-"F" to $FA-FF.
        CMPA    #$FA            ; Hex letter?
        BCS     NOTHEX          ; No, character not hex.
DIG     ASLA
        ASLA                    ; Hex digit to MSD of A.
        ASLA
        ASLA
        LDX     #$04            ; Shift count.
HEXSHIFT
        ASL                     ; Hex digit left, MSB to carry.
        ROL     L               ; Rotate into LSD.
        ROL     H               ;  Rotate into MSD’s.
        LEAX    -1,X            ; Done 4 shifts?
        BNE     HEXSHIFT        ; No, loop.
        LEAY    1,Y             ; Advance text index.
        BNE     NEXTHEX         ; Always taken. Check next char for hex.
NOTHEX  CMPY    YSAV            ; Check if L, H empty (no hex digits).
        LBEQ    ESCAPE          ; Yes, generate ESC sequence.
        BITA    MODE            ; Test MODE byte.
        BVC     NOTSTOR         ;  B6=0 STOR 1 for XAM & BLOCK XAM
        LDA     L               ; LSD’s of hex data.
        STA     [STL,X]         ; Store at current ‘store index’.
        INC     STL             ; Increment store index.
        BNE     NEXTITEM        ; Get next item. (no carry).
        INC     STH             ; Add carry to ‘store index’ high order.
TONEXTITEM
        JMP     NEXTITEM        ; Get next command item.
RUN     JMP     [XAML]          ; Run at current XAM index.
NOTSTOR BMI     XAMNEXT         ; B7=0 for XAM, 1 for BLOCK XAM.
        LDX     #$02            ; Byte count.
SETADR  LDA     L-1,X           ; Copy hex data to
        STA     STL-1,X         ; ‘store index’.
        STA     XAML-1,X        ; And to ‘XAM index’.
        LEAX    -1,X            ; Next of 2 bytes.
        BNE     SETADR          ; Loop unless X=0.
NXTPRNT BNE     PRDATA          ; NE means no address to print.
        LDA     #$8D            ; CR.
        JSR     ECHO            ; Output it.
        LDA     XAMH            ; ‘Examine index’ high-order byte.
        JSR     PRBYTE          ; Output it in hex format.
        LDA     XAML            ; Low-order ‘examine index’ byte.
        JSR     PRBYTE          ; Output it in hex format.
        LDA     #':'            ; ":".
        JSR     ECHO            ; Output it.
PRDATA  LDA     #$A0            ; Blank.
        JSR     ECHO            ; Output it.
        LDA     [XAML,X]        ; Get data byte at ‘examine index’.
        JSR     PRBYTE          ; Output it in hex format.
XAMNEXT STX     MODE            ; 0->MODE (XAM mode).
        LDA     XAML
        CMPA    L               ; Compare ‘examine index’ to hex data.
        LDA     XAMH
        SBCA    H
        BCC     TONEXTITEM      ; Not less, so no more data to output.
        INC     XAML
        BNE     MOD8CHK         ; Increment ‘examine index’.
        INC     XAMH
MOD8CHK LDA     XAML            ; Check low-order ‘examine index’ byte
        ANDA    #$07            ; For MOD 8=0
        BPL     NXTPRNT         ; Always taken.
PRBYTE  PSHS    A               ; Save A for LSD.
        LSRA
        LSRA
        LSRA                    ; MSD to LSD position.
        LSRA
        JSR     PRHEX           ; Output hex digit.
        PULS    A               ; Restore A.
PRHEX   ANDA    #$0F            ; Mask LSD for hex print.
        ORA     #'0'            ; Add "0".
        CMPA    #$3A            ; Digit?
        BCS     ECHO            ; Yes, output it.
        ADDA    #$07            ; Add offset for letter.
ECHO    LDB     ACIAC
        BITB    #$02            ; bit (B2) cleared yet?
        BEQ     ECHO            ; No, wait for display.
        STA     ACIAD           ; Output character. Sets DA.
        RTS                     ; Return.

; Interrupt Vectors - all point to monitor start for now.
; Comment out when running from RAM.
;       ORG     $FF10
        FDB     RESET           ; Reserved vector
        FDB     RESET           ; SWI3 vector
        FDB     RESET           ; SWI2 vector
        FDB     RESET           ; FIRQ vector
        FDB     RESET           ; IRQ vector
        FDB     RESET           ; SWI vector
        FDB     RESET           ; NMI vector
        FDB     RESET           ; Reset vector
