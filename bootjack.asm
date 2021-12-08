; A minimal boot sector Blackjack.

%ifdef com_file
      org 0x0100                  ; BIOS entry (COM)
%else
      org 0x7C00                  ; BIOS entry (IMG)
%endif
      cpu 8086                    ;
      bits 16                     ;
                                  ; ***** constants *****
deck_size:  equ 52                ; max cards in deck
hand_size:  equ 6                 ; max cards allowed in hand

                                  ; ***** variables *****
msg:     db "Bootjack", 10, 13, 0 ;
deck:    times deck_size db 0     ; deck of cards
seed:    dw 13                    ; random seed

player:                           ; player struct (8 bytes)
         db 0                     ; score
         db 0                     ; index
         times hand_size db 0     ; hand

dealer:                           ; dealer struct (8 bytes)
         db 0                     ; score
         db 0                     ; index
         times hand_size db 0     ; hand

wins:    db 0                     ; player wins
losses:  db 0                     ; player losses

start:                            ; ***** program entry *****
      cli                         ; clear interrupts
      push cs                     ; 
      pop ds                      ; 

      mov si, msg                 ; pointer to message
      call tty_print              ; print message to terminal

      ; TODO: refactor to less?
      xor bx, bx                  ; i = 0
_init_deck:
      mov [deck + bx], bl         ; pointer to deck
      inc bx                      ; i++
      cmp bx, deck_size           ; check loop condition
      jb _init_deck               ; while (i < deck_size)

      call seed_rand              ; init PRNG seed

_game_loop:                       ; 
      call reset                  ; reset game state
      ; TODO: verify in GDB

      call shuffle                ; shuffle deck
      ; TODO: shuffle deck subroutine

            
      ; TODO: deal subroutine

      ; TODO: deal initial hand

      ; TODO: eval hand subroutine
      ; TODO: eval dealer hand

      ; TODO: display hand subroutine
      ; TODO: display dealer hand

      ; TODO: eval player hand
      ; TODO: display player hand

      ; TODO: player turn
      ; while (player < 21)
      ;   prompt user, do hit, stand, or quit
      
      ; TODO: check player bust
      
      ; TODO: dealer turn
      ; while (dealer < 17)
      ;   dealer hit
      ;   eval score
      ;   print hand

      ; TODO: check who won

      ; TODO: prompt for next game
      ; jmp _game_loop

end:                              ; ***** end of program *****
      jmp $                       ; repeat current line
      hlt                         ; end program

reset:                            ; ***** reset game state *****
      push si                     ;

      mov si, player              ;
_struct_loop:                     ; reset player
      mov byte [si], 0            ; player[i] = 0
      mov byte [si+0x8], 0        ; dealer[i] = 0
      inc si                      ; i++
      cmp si, player+8            ; check loop condition
      jne _struct_loop            ; while (i < 8)

      pop si                      ;
      ret                         ; end reset subroutine

tty_print:                        ; ***** print string to terminal *****
                                  ; in si; pointer to string
                                  ;
      push ax                     ;
      push bx                     ;
      mov ah, 0x0E                ; teletype output function
      mov bx, 0x000F              ; page zero and BL color (graphic mode)
_bp_msg_loop:                     ;
      lodsb                       ; load byte into AL from string (SI)
      cmp al, 0                   ; check for string null terminator
      je _bp_msg_done             ; if end of string, leave
      int 0x10                    ; BIOS interrupt - display one char
      jmp _bp_msg_loop            ; loop
_bp_msg_done:                     ;
      pop bx                      ;
      pop ax                      ;
      ret                         ; end tty_print subroutine

read_kbd:                         ; ***** read char from keyboard *****
      mov ah, 0x00                ; keyboard read function
      int 0x16                    ; BIOS interrupt - read keyboard
      ret                         ; end read_kbd subroutine

next_rand:                        ; ***** get next random number *****
                                  ; out ax; new random value
      push dx                     ;
      mov ax, 25173               ; LCG multiplier (some large prime)
      mul word [seed]             ; DX:AX = LGC multiplier * seed
      add ax, 13849               ; LCG increment (some large prime)
      mov [seed], ax              ; seed = (mult * seed + inc) % 65536
      pop dx                      ;
      ret                         ; end next_rand subroutine

seed_rand:                        ; ***** seed LCG PRNG with system time *****
                                  ; clobbers ax
      push cx                     ;
      push dx                     ;
      xor ax, ax                  ; ah = time resolution (18.2 Hz)
      int 0x1A                    ; BIOS interrupt - system time in cx:dx
      mov [seed], dx              ; store seed value
                                  ; https://en.wikipedia.org/wiki/Linear_congruential_generator
      pop dx                      ;
      pop cx                      ;
      ret                         ; end seed_rand subroutine

bootable:
%ifdef com_file
%else
                                 ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0  ; pad rest of boot sector
      db 0x55, 0xAA              ; magic numbers; BIOS bootable
%endif
