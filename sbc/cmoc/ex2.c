#include <cmoc.h>

// Output function. Prints character in A on console.
// CMOC standard library converts LF to CR, so we need to convert CR to CR/LF.

void newOutputRoutine()
{
    asm
    {
        pshs    x,b     // Preserve registers used by this routine
wrwait: ldb     $A000   // Read status register
        bitb    #2      // Look at TDRE bit
        beq     wrwait  // Wait until it is 1
        sta     $A001   // Write character to data register
        cmpa    #$0D    // Was character CR?
        bne     done    // If not, then done
        lda     #$0A    // Line feed
        bra     wrwait  // Send it
done:   puls    b,x     // Restore registers
    }
}

int main()
{
    // Use custom output routine.
    setConsoleOutHook(newOutputRoutine);

    putchar('T'); putchar('E'); putchar('S'); putchar('T'); putchar('\n');

    const char *s = "Test of putstr...\n";
    putstr(s, strlen(s));

    putstr("Hello, world!\n", 14);
    putstr("And again hello.\n", 17);

    //printf("Hello, world!\n");

    // Go to ASSIST09 monitor
    asm
    {
        jmp $f837
    }

    return 0;
}
