# bootjack

A minimal boot sector Blackjack.

## Running Locally

Build and run via QEMU with - `make qemu`

I also made a C implementation in [c/](c/) that can be run with - `gcc c/blackjack.c -Wall -o blackjack; ./blackjack`.

## References

- [Programming Boot Sector Games - Toledo Gutierrez](https://www.amazon.com/Programming-Sector-Games-Toledo-Gutierrez/dp/0359816312)
- [x86 instructions](https://www.felixcloutier.com/x86/)
- [Linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator)
- [Interrupt table for BIOS/DOS](https://stanislavs.org/helppc/int_table.html)
- [PC Interrupts: A Programmer's Reference to BIOS, DOS, and Third Party Calls - Ralf Brown](https://www.amazon.com/PC-Interrupts-Programmers-Reference-Third-dp-0201577976/dp/0201577976)
- [Code page 437](https://en.wikipedia.org/wiki/Code_page_437)
