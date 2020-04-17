; Simple Test ROM
    ld SP,0xF000
    ld a,1
loop_continue:
    out (0),a
    call delay
    rlca
    jr  loop_continue

delay:
    push af
    ld de,500
    ld b, 0
dloop:
    djnz $
    dec de
    ld a,d
    or e
    jr nz,dloop
    pop af
    ret