; A minimal boot sector Blackjack.

%ifdef com_file
      org 0x0100                    ; BIOS entry (COM)
%else
      org 0x7C00                    ; BIOS entry (IMG)
%endif
      cpu 8086                      ;
      bits 16                       ;
                                    ; ***** constants *****
deck_len: equ 52                    ; max cards in deck
hand_len: equ 6                     ; max cards allowed in hand
ent_len:  equ 8                     ; size of player/dealer struct

_start:                             ; ***** program entry *****
      cli                           ; clear interrupts
      xor ax, ax                    ; init essential segment registers
      mov ds, ax                    ; 
      mov es, ax                    ;
                                    ; AH = time resolution (18.2 Hz)
      int 0x1A                      ; BIOS interrupt - system time in CX:DX
      mov [seed], dx                ; init PRNG seed

      mov si, welcome               ; pointer to welcome message
      call print_str                ; print string to terminal

      xor bx, bx                    ; i = 0
_new_deck:                          ;
      mov [deck + bx], bl           ; deck[i] = i
      inc bx                        ; i++
      cmp bx, deck_len              ; check loop condition
      jl _new_deck                  ; while (i < deck_len)

_game_loop:                         ; main game loop
      xor ax, ax                    ;
      mov [deck_idx], ax            ; reset deck_idx

      mov si, player                ; pointer to player entity
_reset_entities:                    ; reset entities
      mov [si], al                  ; player[i] = 0
      mov [si + ent_len-1], al      ; dealer[i] = 0
      inc si                        ; i++
      cmp si, player + ent_len      ; check loop condition
      jne _reset_entities           ; while (i < entity_len)

      mov si, deck                  ; pointer to deck of cards
      mov cx, deck_len-1            ; i = 51
_shuffle_loop:                      ; shuffle deck of cards
      mov ax, 25173                 ; LCG multiplier (some arbitrary large prime)
      mul word [seed]               ; DX:AX = LGC multiplier * seed
      add ax, 13849                 ; LCG increment (some arbitrary large prime)
      mov [seed], ax                ; seed = (mult * seed + inc) % 65536

      xor dx, dx                    ; clear dividend
      mov bx, cx                    ; divisor
      inc bx                        ; (i + 1)
      div bx                        ; AX = BX / AX, DX = BX % AX
      mov ax, dx                    ; j = rand() % (i + 1)

      mov bx, ax                    ; load j into offset
      mov dl, [si + bx]             ; deck[j]
      push dx                       ; tmp = deck[j]
      mov bx, cx                    ; load i into offset
      mov dl, [si + bx]             ; deck[i]
      mov bx, ax                    ; load j into offset
      mov [si + bx], dl             ; deck[j] = deck[i]
      pop dx                        ; restore tmp
      mov bx, cx                    ;
      mov [si + bx], dl             ; deck[i] = tmp

      loopne _shuffle_loop          ; while (i > 0)
      
      mov cl, 2                     ; i = 2
_initial_hands:                     ; deal two
      mov si, player                ; entity = player
      call deal                     ; deal card
      mov si, dealer                ; entity = dealer
      call deal                     ; deal card
      loopne _initial_hands         ; while (i > 0)

      call eval_hand                ; evaluate dealer hand
      ; TODO: print card x2

      mov si, player                ;
      call eval_hand                ; evaluate player hand
      ;call print_hand               ; print player hand


; verify deck - TODO: remove
;       xor bx, bx
;       xor ax, ax
; _temp_deck:
;       mov al, [deck + bx]
;       call print_num
;       mov al, ' '
;       call print_char
;       inc bx
;       cmp bx, deck_len
;       jl _temp_deck
;       mov si, newline
;       call print_str
;       call print_str


; verify entity hand - TODO: remove
      mov bx, 2
_temp_hand:
      xor ax, ax
      mov al, [player + bx]
      push bx
      call print_card
      pop bx
      mov si, newline
      call print_str
      inc bx
      cmp bx, 8
      jl _temp_hand
      mov si, newline
      call print_str


      xor bx, bx
      xor ax, ax
_temp:
      mov al, [player + bx]
      call print_num
      mov al, ' '
      call print_char
      inc bx
      cmp bx, 9
      jl _temp


      jmp end

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

end:                                ; ***** end of program *****
      mov si, newline
      call print_str
      mov al, 'X'
      call print_char
      hlt                           ; end program

print_str:                          ; ***** print string to console *****
                                    ; input SI - pointer to string
      push si                       ;
_ps_loop:                           ;
      lodsb                         ; load byte into AL from string (SI)
      call print_char               ; print a single char to console
      cmp al, 0                     ; check for string null terminator
      jne _ps_loop                  ; while not null terminator
      pop si                        ;
      ret                           ; end print_str subroutine

print_char:                         ; ***** print single char to console *****
                                    ; input AX - char to print
	    push ax                       ;
	    push bx                       ;
	    push si                       ;
	    mov ah, 0x0E	                ; teletype output function
	    mov bx, 0x000F	              ; BH page zero and BL color (graphic mode only)
	    int 0x10		                  ; BIOS interrupt - display one char
	    pop si                        ; 
	    pop bx                        ; 
	    pop ax                        ; 
	    ret                           ; end print_char subroutine

print_num:                          ; ***** print number to console *****
                                    ; input AX - number to print
                                    ; clobbers AX,DX
      push cx                       ;
      xor dx, dx	                  ;
      mov cl, 10		                ;
      div cx		                    ; AX = CX / AX, DX = CX % AX
      push dx                       ; DX = remainder
      cmp ax, 0                     ; check loop condition
      je _pn_rem                    ; while (ax != 0)
      call print_num                ; recursive call
_pn_rem:                            ;
	    pop ax                        ; restore original number
	    add al, '0'                   ; convert remainder to ASCII
	    call print_char	              ; print single char to console
      pop cx                        ;
	    ret                           ; end print_num subroutine

deal:                               ; ***** deal a card to an entity *****
                                    ; input SI - pointer to entity
                                    ; clobbers BX
      push ax                       ;
      xor bx, bx                    ;
      mov bl, [deck_idx]            ;
      mov al, [deck + bx]           ; deck[deck_idx]
      mov bl, [si + 1]              ; entity.idx
      mov [si + 2 + bx], al         ; entity.hand[entity.idx] = deck[deck_idx]
      inc byte [si + 1]             ; entity.idx++
      inc byte [deck_idx]           ; deck_idx++
      pop ax                        ;
      ret                           ; end deal subroutine

eval_hand:                          ; ***** evaluate entity's hand *****
                                    ; input SI - pointer to entity
                                    ; clobbers AX,BX,CX,DX
      mov byte [si], 0              ; reset entity.score
      xor cx, cx                    ; i = 0
_eval_loop:                         ;
      xor ax, ax                    ;
      xor dx, dx	                  ;
      mov bx, cx                    ;
      mov al, [si + 2 + bx]         ; entity.deck[i]

      mov bx, 13		                ; face offset
      div bl		                    ; AH = AX % BL, AL = AX / BL
                                    ; AH = face, AL = suit
      cmp ah, 0                     ;
      je _eval_ace                  ; if (face == A)
      cmp ah, 10                    ;
      jge _eval_jqk                 ; if (face in [J,Q,K])
                                    ; else
      inc ah                        ; face++
      add [si], ah                  ; entity.score += face
      jmp _eval_next                ; iterate
_eval_jqk:                          ; Jack, Queen, King
      add byte [si], 10             ; entity.score += 10
      jmp _eval_next                ; iterate
_eval_ace:                          ; Ace
      mov bl, [si]                  ; entity.score
      cmp bl, 11                    ; ace = 11
      jl _eval_ace_11               ; if (entity.score < 11)

      inc byte [si]                 ; entity.score += 1
      jmp _eval_next                ; iterate
_eval_ace_11:                       ;
      add byte [si], 11             ; entity.score += 11
_eval_next:                         ;
      inc cl                        ; i++
      cmp cl, [si + 1]              ; check loop condition
      jl _eval_loop                 ; while (i < entity.idx)
      
      ret                           ; end eval_hand subroutine

print_card:                         ; ***** print a card *****
                                    ; input AX - card index
                                    ; clobbers AX,BX,DX
      mov bx, 13		                ; face offset
      div bl		                    ; AH = AX % BL, AL = AX / BL
      mov dx, ax                    ; AH = face, AL = suit
      xor ax, ax                    ;

      cmp dh, 0
      je _pc_face_ace               ; if (face == 0)
      cmp dh, 10                    ;
      jge _pc_face_letter           ; if (face >= 10)
      mov al, dh                    ;
      inc al                        ;
      push dx                       ; save face,suit
      call print_num                ; print face
      pop dx                        ; restore face,suit
      jmp _pc_suit                  ;
_pc_face_ace:                       ;
      mov dh, 10                    ; faces[0] = 'A'
_pc_face_letter:                    ;
      sub dh, 10                    ; re-adjust index
      mov bl, dh                    ; 
      mov al, [faces + bx]          ; get ['J', 'Q', 'K']
      call print_char               ; print
_pc_suit:                           ;
      mov al, ' '                   ;
      call print_char               ; print space
      mov al, 3                     ; adjust suit index
      add al, dl                    ; ASCII index [3,4,5,6]
      call print_char               ; print suit

      ret                           ; end print_card subroutine

                                    ; ***** variables *****
welcome:  db "Bootjack", 13, 10, 0  ; simple welcome message
newline:  db 13, 10, 0              ; \n
faces:    db "AJQK"                 ; non-numeric face values
seed:     dw 37                     ; random seed; init to arbitrary prime

deck_idx: db 0                      ; deck index
deck:     times deck_len db 0       ; deck of cards

player:                             ; player struct (8 bytes)
          db 0                      ; score
          db 0                      ; index
          times hand_len db 0       ; hand
dealer:                             ; dealer struct (8 bytes)
          db 0                      ; score
          db 0                      ; index
          times hand_len db 0       ; hand

%ifdef com_file
%else
                                    ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0     ; pad rest of boot sector
      dw 0xAA55                     ; magic numbers; BIOS bootable
%endif
