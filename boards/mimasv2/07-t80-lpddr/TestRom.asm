    ld a,0xa6
    ld (0xFFFF),a
    ld a,(0x4000)
    ld a,(0xFFFF)
    out (0),a


	ld		HL,thunk
	ld		DE,0xFFF0
	ld		BC,thunk_end - thunk
	ldir	

    ; Jump to thunk
    jp      0xFFF0

    ; Finish
finished:
    jr      $

thunk:
	; Kick out the bootrom firmware (ie: this code)
	ld		A,0
	out		(0x1c),A

    ; Jump to big80.sys entry point
    jp      finished
thunk_end:
