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
hand_len: equ 5                     ; max cards in hand; (6 - 1 player)
ent_len:  equ 7                     ; entity struct data length  (2+hand_len)

_start:                             ; ***** program entry *****
      xor ax, ax                    ; 
                                    ; AH = time resolution (18.2 Hz)
      int 0x1A                      ; BIOS interrupt - system time in CX:DX
      mov [seed], dx                ; init PRNG seed

_game_loop:                         ; main game loop
      xor ax, ax                    ;
      mov byte [deck_idx], al       ; reset deck_idx

      mov si, player                ; pointer to player entity
_reset_entities:                    ; reset entities
      mov [si], al                  ; player[i] = 0
      mov [si + ent_len - 1], al    ; dealer[i] = 0
      inc si                        ; i++
      cmp si, player + ent_len      ; check loop condition
      jne _reset_entities           ; while (i < entity_len)

      mov si, deck                  ; pointer to deck of cards
      mov cl, deck_len - 1          ; i = 51
_shuffle_loop:                      ; shuffle deck of cards
      mov al, 251                   ; LCG mulitplier (arbitrary prime)
      mul byte [seed]               ; AX = AL * operand
      add al, 197                   ; LCG increment (arbitrary prime)
      mov [seed], ax                ;

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
      push si                       ; 
      call deal                     ; deal card

      mov si, dealer                ; entity = dealer
      call deal                     ; deal card
      loopne _initial_hands         ; while (i > 0)

      push si                       ; save dealer pointer
      mov si, s_dealer              ; dealer label
      call print_str                ;
      pop si                        ; restore dealer pointer
      call eval_hand                ; evaluate dealer hand
      xor ax, ax                    ;
      mov al, [si + 2]              ; dealer.hand[0]
      call print_card               ; print first card

      mov si, s_player              ; player label
      call print_str                ;
      pop si                        ; restore player pointer
      push si                       ; save player pointer
      call eval_hand                ; evaluate player hand
      call print_hand               ; print player hand

      pop si                        ; restore player pointer
_player_turn:
      call get_choice               ; get char from user
      cmp al, 'h'                   ; hit?
      jne _dealer_turn              ; if no hit, assume stand; move to dealer turn

      call deal                     ; deal to player
      call eval_hand                ; evaluate player hand
      
      push si                       ; save player pointer
      mov si, s_player              ; print player label
      call print_str                ;
      pop si                        ; restore player pointer

      call print_hand               ; print player hand
      mov al, [player]              ; player.score

      cmp al, 21                    ; check loop condition
      jg _player_loss               ; if player.score > 21 then bust
      jl _player_turn               ; while (player.score < 21)
                                    ; 21 fallthrough
_dealer_turn:                       ;
      mov si, s_dealer              ;
      call print_str                ; print dealer label
      mov si, dealer                ;
      call print_hand               ; print dealer hand

      mov bl, [dealer]              ;
      cmp bl, 17                    ; check loop condition; soft 17
      jge _check_win                ; dealer done

      call deal                     ; deal to dealer
      call eval_hand                ; evaluate dealer hand
      jmp _dealer_turn              ; continue loop

_check_win:                         ;
      cmp bl, 21                    ; dealer > 21
      jg _player_win                ; dealer bust
      mov bh, [player]              ; reload player score
      cmp bl, bh                    ; bh=player, bl=dealer
      je _player_tie                ; if (dealer == player) then player tied
      jg _player_loss               ; if (dealer > player) then player lost
_player_win:                        ;
      mov al, 'W'                   ; default - player won
      jmp _game_over                ; if player > dealer then player won
_player_tie:                        ;
      mov al, 'T'                   ; player tied
_player_loss:                       ;
      mov al, 'L'                   ; player lost
_game_over:                         ;
      push ax                       ; save game status
      mov si, s_player              ;
      call print_str                ; print player label
      xor ax, ax                    ;
      pop ax                        ; restore game status
      call print_char               ; AL has game status:  W/L

      mov al, 0x0A                  ;
      call print_char               ; print LF
      mov al, 0x0D                  ;
      call print_char               ; print CR

      call get_choice               ; prompt user to continue
      jmp _game_loop                ; play again if != 'q'
end:                                ; ***** end of program *****
      jmp $                         ;

get_choice:                         ; ***** get user choice *****
                                    ; output AX = lowercase ASCII input
                                    ; clobbers AX
      mov al, ':'                   ; output basic prompt
      call print_char               ; 
      mov ah, 0x00                  ; keyboard read
      int 0x16                      ; BIOS interrupt; key as ASCII in AL
      or al, 0x20                   ; input to lowercase
      call print_char               ; echo input back
      cmp al, 'q'                   ; 
      je end                        ; end program
      ret                           ; end get_choice subroutine

print_str:                          ; ***** print string to console *****
                                    ; input SI - pointer to string
_ps_loop:                           ;
      lodsb                         ; load byte into AL from string (SI)
      cmp al, 0                     ; check for string null terminator
      je _ps_done                   ; while not null terminator
      call print_char               ; print a single char to console
      jmp _ps_loop                  ; continue loop
_ps_done:                           ;
      ret                           ; end print_str subroutine

print_char:                         ; ***** print single char to console *****
                                    ; input AL - char to print, clobbers AH
      push bx                       ;
      mov ah, 0x0E	            ; teletype output function
      mov bx, 0x000F	            ; BH page zero and BL color (graphic mode only)
      int 0x10		            ; BIOS interrupt - display one char
      and ah, 0x00                  ; clear AH
      pop bx                        ; 
      ret                           ; end print_char subroutine

deal:                               ; ***** deal a card to an entity *****
                                    ; input SI - pointer to entity
                                    ; clobbers BX
      xor bx, bx                    ;
      mov bl, [deck_idx]            ;
      mov al, [deck + bx]           ; deck[deck_idx]
      mov bl, [si + 1]              ; entity.idx
      mov [si + 2 + bx], al         ; entity.hand[entity.idx] = deck[deck_idx]
      inc byte [si + 1]             ; entity.idx++
      inc byte [deck_idx]           ; deck_idx++
      ret                           ; end deal subroutine

eval_hand:                          ; ***** evaluate entity's hand *****
                                    ; input SI - pointer to entity
                                    ; clobbers AX,BX,CX,DX
      xor dx, dx                    ; entity.score = 0
      xor bx, bx                    ; i = 0
_eval_loop:                         ;
      xor ax, ax                    ;
      push bx
      mov al, [si + 2 + bx]         ; entity.deck[i]
      mov bx, 13		            ; face offset
      div bl		            ; AH = AX % BL, AL = AX / BL
                                    ; AH = face, AL = suit
      cmp ah, 0                     ;
      je _eval_ace                  ; if (face == A)
      cmp ah, 10                    ;
      jg _eval_10                   ; if (face in [J,Q,K])

      add dl, ah                    ;
      inc dx                        ; face++
      jmp _eval_next                ; iterate

_eval_ace:                          ; Ace
      inc dx                        ; entity.score += 1
      cmp dl, 12                    ;
      jg _eval_next                 ; if (entity.score > 11)
_eval_10:                           ; A,J,Q,K
      add dl, 10                    ;
_eval_next:                         ;
      pop bx                        ;
      mov [si], dl                  ; save entity.score
      inc bx                        ; i++
      cmp bl, [si + 1]              ; check loop condition
      jl _eval_loop                 ; while (i < entity.idx)

      ret                           ; end eval_hand subroutine

print_card:                         ; ***** print a card *****
                                    ; input AX - card index
                                    ; clobbers AX,DX
      push bx                       ;

      mov bl, 13		            ; face offset
      div bl		            ; AH = AX % BL, AL = AX / BL
      xchg ax, dx                   ; AH = face, AL = suit
      xor ax, ax                    ;

      cmp dh, 9                     ; 
      jne _pc_face_letter           ; if (face >= 10)

_pc_face_10:                        ;
      mov al, '1'                   ; for printing '10'
      call print_char               ;
_pc_face_letter:                    ;
      mov bl, dh                    ; 
      mov al, [faces + bx]          ; get face display
      call print_char               ; print face

_pc_suit:                           ;
      mov al, 3                     ; adjust suit index
      add al, dl                    ; ASCII index [3,4,5,6]
      call print_char               ; print suit

      pop bx                        ;
      ret                           ; end print_card subroutine

print_hand:                         ; ***** print an entity's hand *****
                                    ; input SI - pointer to entity
      xor bx, bx                    ; i = 0
_ph_loop:                           ;
      xor ax, ax                    ;
      mov al, [si + bx + 2]         ; entity.hand[i]
      call print_card               ; print card to terminal
      mov al, ' '                   ;
      call print_char               ;

      inc bx                        ; i++
      cmp bl, [si + 1]              ; check loop condition
      jl _ph_loop                   ; while (i < entity.idx)

      ret                           ; end print_hand subroutine

                                    ; ***** variables *****
s_player:  db 0x0A, 0x0D, "P: ", 0  ; player entity label
s_dealer:  db 0x0A, 0x0D, "D: ", 0  ; dealer entity label
seed:      dw 227                   ; random seed; init to arbitrary prime

deck_idx:  db 0                     ; deck index
player:                             ; player struct (8 bytes)
           db 0                     ; score
           db 0                     ; index
           times hand_len db 0      ; hand

dealer:                             ; dealer struct (8 bytes)
           db 0                     ; score
           db 0                     ; index
           times hand_len db 0      ; hand

faces:     db "A234567890JQK"       ; faces

deck:      db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
           db 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
           db 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17
           db 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
           db 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27
           db 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F
           db 0x30, 0x31, 0x32, 0x33  ; 0-51

%ifdef com_file
%else
                                    ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0     ; pad rest of boot sector
      dw 0xAA55                     ; magic numbers; BIOS bootable
%endif
