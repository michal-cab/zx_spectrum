    DEVICE ZXSPECTRUM48
    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
    
    org $8000


letter_address  = $7900     ; variables in memory, as i still dont
line_address    = $7910     ; understand how stack works in sjasmplus
iterate         = $7920     ; and also got lost in pushes and pops
next_letter     = $7930
last_letter     = $7940
iterate_main    = $7950

text:       db '^ ^ ^ na kraji lesa , je listi do pole , jako ja do tebe , jako ty do me'
text_end:   equ $           ; end of text address

    di                      ; disable interrupt                    
load_letter_init:
     ld hl, text_end
    ld (last_letter), hl    ; saving address of last letter into memeory
    ld bc,0                 ; init conunter for main loop
    ld (iterate_main),bc    ; and save it into memory


main_loop:
    ld bc, (iterate_main)
    ld hl, text             ; address of text into hl
    add hl,bc               ; moving through text  
    inc bc                  ; as interate_main grows
    ld (iterate_main),bc    ; and saving it for next round
    ld (next_letter),hl 

    ld hl, (next_letter)
    ld bc, (last_letter)
  
                            ; testing if we reached end of text with xor
                            ; comparing two registers
                            ; in hl is actual position in text
                            ; bc holds address of last letter

test_end_text:
                            ; registers d and e hold results of tests
    ld a, c                 ; first comparing lower registers
    xor l                   ; and
    ld  e,a                 ; saving result into e - final xor d and e must be zero

    ld a, b                 ; second test of upper registers
    xor h
    ld d,a                  ; saving results into d

    ld a, e                 ; final test - comparing d and e with xor
    xor d                   ; both are zero -> zero flag in a 
   
                            ; till we did not reach end of text, we are looping/inerating
    jr nz, load_letter      ; and drawing a letter

    jr load_letter_init     ; did we reach address of last letter? if yes -> reset value for first letter
                            ; and start from beginning      

load_letter:
                            ; computing memory location of letter graphivs in ROM
    ld a,9                  ; we need to go 9 (or 8) lines deeper
    ld de, $3c00            ; place in ROM where letter starts
                            ; https://skoolkid.github.io/rom/asm/3D00.html
    ld hl,(next_letter)     ; address of just tested lettet into hl
    ld l, (hl)              ; ASCII code of letter into l
    ld h,0                  ; purging upper byte of hl, xor h not working (?)    
    add hl, hl              ; x 2
    add hl, hl              ; x 4
    add hl, hl              ; x 8
    add hl, de              ; adding ROM offset where letters start
    add a,l
    ld l,a                  ; in hl in now lower line of letter
    ld (letter_address), hl ; saving it into memory


next_line_init:
    ld bc, 9                ; saving number of iterations 
                            ; 8 or 9
    ld (iterate), bc
    ld de, 22528-32         ; destination - beginning of zx's video RAM
                            ; -32 works better for diagoval scroll
    ld (line_address),hl    ; loading conteno of line of a letter into hl


next_line:
    ld  hl,(line_address)  
    dec hl
    ld (line_address),hl    ; saving line of address-1 into memory 
    ld l, (hl)              ; tested byte pointing at one line of char


start:
    ld b,8                  ; drawing 8 attributes
test_bit:                   ; going through 8 attribute bits
    bit 7,l                 ; testing 7th bit
    push af     
    ld a,%11111000
    and l
    out (254),a             ; sound and border
    pop af  
    jr nz, draw_black       ; replacing call with
    jr draw_cyan            ; faster and smaller jr
rtrn:
    rlc l                   ; rotating bit
    djnz test_bit
    jr vscroll_init         ; after all 8 attributes are done, we jump for scrolling routine 

draw_black:
    ld a,%01111000          ; load ink/paprt into a
                            ; %00000111 - BLACK
    ld (de),a               ; load a into videoram
    inc e                   ; move forward in videoram
                            ; originally i had dec de here
    jr rtrn

draw_cyan:
    ld a,%00000111          ; load ink/paprt into a
                            ; %00101000 - CYAN
    ld (de),a               ; load a into videoarm
    inc e   
    jr rtrn

vscroll_init:
    ld a,24                 ; number of lines we are about to scroll down
                            ; outer loop counter
    ld hl, 23264            ; last attribute line in videoram
                            ; source address
    ld de, 23264+32         ; destination address
                            ; one line below


 
vscroll_videoram:
    call wait
 ;   ld bc, 8               ; we will copy 8 attributes
    push hl                 ; ldir incements hl and de
    push de                 ; so we are saving them in stack
    ldir                    ; copy 8 attributes from
                            ; upper line to one line below
    pop de                   
    pop hl
    ld bc, 32              ; amout we are subtracting from video address
                            ; 32 is ok, 31 for screwed/diagonal scroll :)
    ld de, hl               ; switching source and destination
                            ; so de points on lower line
    sbc hl,bc               ; computing new upper source address in videoram
    dec a     
    jr nz, vscroll_videoram
    ld bc, (iterate)        ; how many times we will iterate
    dec c
    ld (iterate), bc        ; and saving into memory again    
    jr  nz, next_line       ; after 8 cycles we need to calculate
                            ; new address for a letter
    jp main_loop

wait:
    push af
    push bc
    ld bc,200               ; delay time
delay_loop:
    ld a,b 
    or c
    dec bc
    jr nz, delay_loop
    pop bc
    pop af
    ret



                            ;???? still dont know how sjasmplus dealing with stack
STACK_SIZE: equ 200  
    defw 0  ; WPMEM, 2
stack_bottom:
    defs    STACK_SIZE*2, 0
stack_top:
    defw 0  ; WPMEM, 2

end:
    SAVESNA "vertical_scroll.sna", $8000

