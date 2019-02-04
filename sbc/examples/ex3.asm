; Example of adding custom command to ASSIST09 using secondary command
; list. After calling this code from the monitor, typing the command U
; will display the string Hello!

; Character defines

EOT     EQU     $04             ; String terminator

; ASSIST09 SWI call numbers

PDATA1  EQU     2               ; Output string
PCRLF   EQU     6               ; OUTPUT CR/LF
VCTRSW  EQU     9               ; Vector swap
.CMDL2  EQU     44              ; Secondary command list

        ORG     $1000           ; Start address

START   LEAX    MYCMDL,PCR      ; Load new handler address
        LDA     #.CMDL2         ; Load subcode for vector swap
        SWI                     ; Request service
        FCB    VCTRSW           ; Service code byte
        RTS                     ; Return to monitor

MYCMDL:
        FCB     4               ; Table entry length
        FCC     'U'             ; Command name
        FDB     UCMD-*          ; Pointer to command (relative to here)
        FCB     $FE             ; -2 indicates end of table

UCMD:
        LEAX    MSG1,PCR        ; Get address of string to display
        SWI                     ; Call ASSIST09 monitor function
        FCB     PDATA1          ; Service code byte
        SWI                     ; Print CR/LF
        FCB     PCRLF
        RTS

MSG1    FCC     'Hello!'
        FCB     EOT

