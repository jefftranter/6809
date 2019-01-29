#include <cmoc.h>

// Output function. Prints character in A on console.
void newOutputRoutine()
{
    // TODO: Convert CR to CR/LF
    asm
    {
        pshs    x,b  // preserve registers used by this routine
wrwait: ldb  $A000   // Read status register
        bitb #2      // Look at TDRE bit
        beq  wrwait  // Wait until it is 1
        sta $A001    // Write character to data register
        puls    b,x  // Restore registers
    }
}

int main()
{
    // Use custom output routine.
    setConsoleOutHook(newOutputRoutine);

    //putchar('H'); putchar('E'); putchar('L'); putchar('L'); putchar('O'); putchar('\n');

    putstr("Hello, world!\n", 13);

    //printf("Hello, world!\n");

    // Go to ASSIST09 monitor
    asm
    {
        jmp $f837
    }

    return 0;
}
