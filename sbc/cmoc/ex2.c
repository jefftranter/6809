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

// Read a character from the console and return it.
char readchar()
{
    char c;

    asm
    {
loop:   lda     $A000   // Read ACIA status register
        lsra            // Shift RDR bit into carry
        bcc     loop    // Branch if not character yet
        lda     $A001   // Read data register
        sta     :c      // Store in variable c
    }

    return c;
}

static char linebuf[80]; // Buffer for readline

// Replacement for readline library function.
// Reads a line from standard input and returns it.
char *readline()
{
    int i;

    for (i = 0; i < sizeof(linebuf); i++) {
        linebuf[i] = readchar();
        if (linebuf[i] == '\r' || linebuf[i] == '\r' || linebuf[i] == '\0') {
            break;
        }
    }
    linebuf[i] = 0;
    return linebuf;
}

int main()
{
    // Use custom output routine.
    setConsoleOutHook(newOutputRoutine);

    // Try output routines
    putchar('T'); putchar('E'); putchar('S'); putchar('T'); putchar('\n');

    const char *s = "Test of putstr...\n";
    putstr(s, strlen(s));

    putstr("Hello, world!\n", 14);
    putstr("And again hello.\n", 17);

    //printf("Hello, world!\n");

    // Try input routine.
    putstr("Enter some text: ", 17);
    char *ln = readline();
    putstr("\nInput text was: '", 18);
    putstr(ln, strlen(ln));
    putstr("'\n", 2);

    // Go to ASSIST09 monitor
    asm
    {
        jmp $f837
    }

    return 0;
}
