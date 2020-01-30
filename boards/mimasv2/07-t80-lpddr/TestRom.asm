    ld a,0xa6
    ld (0xFFFF),a
    ld a,(0x4000)
    ld a,(0xFFFF)
    out (0),a
    jr $

