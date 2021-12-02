; A minimal boot sector Blackjack.

org 0x7C00                 ; BIOS entry
bits 16

start:
    cli              ; disable interrupts
    mov si, msg      ; pointer to message
    call bios_print  ;
    jmp $            ;

bios_print:          ; subroutine to print to BIOS
    mov ah, 0x0E     ; print char

_msg_loop:           ;
    lodsb            ; load char  TODO:
    cmp al, 0        ; check for end of string
    je _msg_done     ; if end, leave
    int 0x10         ; interrupt - teletype TODO:
    jmp _msg_loop    ; 

_msg_done:           ;
    ret              ;

end:                 ;
    hlt              ; end program

msg:  db "Hello world", 0

; complete boot sector
times 510 - ($ - $$) db 0  ; pad rest of boot sector
dw 0xAA55                  ; magic numbers; BIOS bootable
