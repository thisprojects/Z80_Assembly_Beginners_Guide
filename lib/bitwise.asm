    ORG 0x8000

    CALL 0x0DAF              ; ROM: CLS — clear screen, cursor to (0,0)
    CALL debug_init          ; Open screen channel

    LD HL, msg
    CALL print_string        ; "FLASH!" appears at the top of the screen

    ; Use OR to set FLASH (bit 7) and BRIGHT (bit 6) on each of the 6 characters.
    ; OR %11000000 forces both bits to 1 without touching the colour bits.

    LD A, (0x5800)
    OR %11000000             ; Set Flash + Bright on 'F'
    LD (0x5800), A

    LD A, (0x5801)
    OR %11000000             ; Set Flash + Bright on 'L'
    LD (0x5801), A

    LD A, (0x5802)
    OR %11000000             ; Set Flash + Bright on 'A'
    LD (0x5802), A

    LD A, (0x5803)
    OR %11000000             ; Set Flash + Bright on 'S'
    LD (0x5803), A

    LD A, (0x5804)
    OR %11000000             ; Set Flash + Bright on 'H'
    LD (0x5804), A

    LD A, (0x5805)
    OR %11000000             ; Set Flash + Bright on '!'
    LD (0x5805), A

    ; Now use AND to clear just the FLASH bit (bit 7) on the first character.
    ; AND %01111111 forces bit 7 to 0 while leaving everything else unchanged.
    ; 'F' stops flashing but stays bright — the rest of the word keeps flashing.

    LD A, (0x5800)
    AND %01111111            ; Clear Flash on 'F' only
    LD (0x5800), A

    RET                      ; Return to BASIC

msg: DB "FLASH!", 0

    INCLUDE "debug_output.asm"
    END 0x8000
