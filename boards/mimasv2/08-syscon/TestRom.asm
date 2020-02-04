; Simple Test ROM
    ld SP,0xF000

    ld HL,message
    ld B,message_end - message
    ld C,0x80

send_char:
    in a,(c)
    cp 7
    jr z, send_char;

    outi
    jr nz, send_char

    jr $

message:
    db "Hello World from Big80\n"
message_end: