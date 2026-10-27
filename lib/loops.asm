    ORG 0x8000

    LD C, 0              ; C = current border colour, starting at 0

colour_loop:
    LD A, C
    OUT (0xFE), A        ; Set the border to colour C

    ; Inner DJNZ loop: 25 HALTs x 20ms each = ~0.5 seconds
    LD B, 25
delay_loop:
    HALT                 ; Wait for the next interrupt (~20ms)
    DJNZ delay_loop      ; Repeat 25 times

    ; Advance to the next colour and loop while C < 8
    INC C
    LD A, C
    CP 8                 ; Have we shown all 8 colours (0-7)?
    JP NZ, colour_loop   ; No — go back for the next one

    RET                  ; Yes — all colours shown, return to BASIC

    END 0x8000
