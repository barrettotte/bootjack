; A minimal boot sector Blackjack.

%ifdef com_file
      org 0x0100                  ; BIOS entry (COM)
%else
      org 0x7C00                  ; BIOS entry (IMG)
%endif

      cpu 8086                    ;
      bits 16                     ;
                                  ; ***** constants *****
deck_len: equ 52                  ; max cards in deck
hand_len: equ 6                   ; max cards allowed in hand
ent_len:  equ 8                   ; size of player/dealer struct

_start:                           ; ***** program entry *****
      cli                         ; clear interrupts
      xor ax, ax                  ; init essential segment registers
      mov ds, ax                  ; 
      mov es, ax                  ;

      mov si, welcome             ; pointer to welcome message
      call print_str              ; print string to terminal

      xor bx, bx                  ; i = 0
_init_deck:                       ;
      mov [deck + bx], bl         ; deck[i] = i
      inc bx                      ; i++
      cmp bx, deck_len            ; check loop condition
      jl _init_deck               ; while (i < deck_len)

; verify deck reset - TODO: remove
;       xor bx, bx
;       xor ax, ax
; _temp:
;       mov al, [deck + bx]
;       call print_num
;       mov al, ' '
;       call print_char
;       inc bx
;       cmp bx, deck_len
;       jl _temp

      call seed_rand              ; init PRNG seed

_game_loop:                       ; 
      call reset                  ; reset game state
      call shuffle                ; shuffle deck

; verify deck reset - TODO: remove
      xor bx, bx
      xor ax, ax
_temp:
      mov al, [deck + bx]
      call print_num
      mov al, ' '
      call print_char
      inc bx
      cmp bx, deck_len
      jl _temp  

      jmp end

            
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
      mov si, newline
      call print_str
      call print_str
      call print_str
      mov ax, 'X'
      call print_char
      call print_char
      call print_char
      hlt                         ; end program

reset:                            ; ***** reset game state *****
      push si                     ;
      mov si, player              ;
_struct_loop:                     ; reset player
      mov byte [si], 1            ; player[i] = 0
      mov byte [si + ent_len], 1  ; dealer[i] = 0
      inc si                      ; i++
      cmp si, player + ent_len    ; check loop condition
      jne _struct_loop            ; while (i < 8)

      pop si                      ;
      ret                         ; end reset subroutine

print_str:                        ; ***** print string to console *****
                                  ; input si - pointer to string
      push si                     ;
_ps_loop:                         ;
      lodsb                       ; load byte into AL from string (SI)
      test al, al                 ; check for string null terminator
      je _ps_done                 ; if end of string, leave
      call print_char             ; print a single char to console
      jmp _ps_loop                ; loop
_ps_done:                         ;
      pop si                      ;
      ret                         ; end print_str subroutine

print_char:                       ; ***** print single char to console *****
                                  ; input AX - char to print
	    push ax                     ;
	    push bx                     ;
	    push cx                     ;
	    push dx                     ;
	    push si                     ;
	    push di                     ;
	    mov ah, 0x0E	              ; teletype output function
	    mov bx, 0x000F	            ; BH page zero and BL color (graphic mode only)
	    int 0x10		                ; BIOS interrupt - display one char
	    pop di                      ;
	    pop si                      ; 
	    pop dx                      ; 
	    pop cx                      ; 
	    pop bx                      ; 
	    pop ax                      ; 
	    ret                         ; end subroutine print_char

print_num:                        ; ***** print number to console *****
                                  ; input AX - number to print
      push cx                     ;
      mov dx, 0		                ;
      mov cx, 10		              ;
      div cx		                  ; AX = DX:AX / CX
      push dx                     ;
      cmp ax, 0                   ; check loop condition
      je _pn_done                 ; while (ax != 0)
      call print_num              ; recursive call
_pn_done:                         ;
	    pop ax                      ; restore original number
	    add al, '0'                 ; convert remainder to ASCII
	    call print_char	            ; print single char to console
      pop cx                      ;
	    ret                         ; end print_num subroutine

shuffle:                          ; ***** shuffle deck using Fisher-Yates *****
      push ax                     ;
      push bx                     ;
      push cx                     ;
      push dx                     ;

      mov cx, deck_len-1          ; i = 51
_shuffle_loop:                    ;
      call next_rand              ; AX = new random number
      xor dx, dx                  ; clear dividend
      mov bx, cx                  ; divisor
      add bx, 1                   ; (i + 1)
      div bx                      ; AX = BX / AX, DX = BX % AX
      mov ax, dx                  ; j = rand() % (i + 1)

      mov bx, ax                  ; 
      mov dl, [deck + bx]         ; deck[j]
      push dx                     ; tmp = deck[j]
      mov bx, cx                  ;
      mov dl, [deck + bx]         ; deck[i]
      mov bx, ax                  ;
      mov [deck + bx], dl         ; deck[j] = deck[i]
      pop dx                      ; restore tmp
      mov bx, cx                  ;
      mov [deck + bx], dl         ; deck[i] = tmp

      dec cx                      ; i--
      cmp cx, 0                   ; check loop condition
      jne _shuffle_loop           ; while (i > 0)

      pop dx                      ;
      pop cx                      ;
      pop bx                      ;
      pop ax                      ;
      ret                         ; end shuffle subroutine

next_rand:                        ; ***** get next random number *****
                                  ; output ax - new random value
      push dx                     ;
      mov ax, 25173               ; LCG multiplier (some arbitrary large prime)
      mul word [seed]             ; DX:AX = LGC multiplier * seed
      add ax, 13849               ; LCG increment (some arbitrary large prime)
      mov [seed], ax              ; seed = (mult * seed + inc) % 65536
      pop dx                      ;
      ret                         ; end next_rand subroutine

seed_rand:                        ; ***** seed LCG PRNG with system time *****
                                  ;
      push ax                     ;
      push cx                     ;
      push dx                     ;
      xor ax, ax                  ; ah = time resolution (18.2 Hz)
      int 0x1A                    ; BIOS interrupt - system time in cx:dx
      mov [seed], dx              ; store seed value
                                  ; https://en.wikipedia.org/wiki/Linear_congruential_generator
      pop dx                      ;
      pop cx                      ;
      pop ax                      ;
      ret                         ; end seed_rand subroutine

                                  ; ***** variables *****
welcome: db "Bootjack", 10, 13, 0 ; simple welcome message
newline: db 10, 13, 0             ; \n

deck:    times deck_len db 0      ; deck of cards
seed:    dw 13                    ; random seed

player:                           ; player struct (8 bytes)
         db 0                     ; score
         db 0                     ; index
         times hand_len db 0      ; hand

dealer:                           ; dealer struct (8 bytes)
         db 0                     ; score
         db 0                     ; index
         times hand_len db 0      ; hand

wins:    db 0                     ; player wins
losses:  db 0                     ; player losses

%ifdef com_file
%else
                                  ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0   ; pad rest of boot sector
      dw 0xAA55                   ; magic numbers; BIOS bootable
%endif
