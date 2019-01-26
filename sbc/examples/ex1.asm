; Simple 6809 assembler example.
; Does not do anything meaningful, but can be used for testing file
; loading and running from ASSIST09.

        ORG     $7000           ; Start address

START:  LDA     #$12
        LDB     #$34
        LDX     #$5678
        EXG     A,B
        NOP
        NOP
        RTS
