
    ld  hl,0x4000
    ld  de,8
    ld  b,0
fill_loop:
    ld  (hl),b
    inc hl
    inc b
    dec de
    ld  a,d
    or  a,e
    jr  nz,fill_loop

    ld  hl,0x4000
    ld  de,0x5000
    ld  bc,8
    ldir

    ld  hl,0x5000
    ld  de,0x3c00
    ld  bc,8
    ldir

; Rotating LEDs
    ld SP,0xF000
    ld a,1
loop_continue:
    out (0),a
    call delay
    rlca
    jr  loop_continue

delay:
    push af
    ld de,50
    ld b, 0
dloop:
    djnz $
    dec de
    ld a,d
    or e
    jr nz,dloop
    pop af
    ret
