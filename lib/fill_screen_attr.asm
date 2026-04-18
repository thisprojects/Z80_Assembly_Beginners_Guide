; fill_screen_attr
; Fill all 768 attribute bytes with a single value
; Input:  A = attribute byte to fill with
; Output: none
; Destroys: BC, HL
fill_screen_attr:
    LD  HL, $5800        ; start of attribute file
    LD  B, 3             ; 3 outer passes of 256 bytes = 768 bytes total
.outer:
    PUSH BC
    LD  B, 0             ; B=0 → DJNZ loops 256 times (decrements to 255 on first pass)
.inner:
    LD  (HL), A          ; write attribute — DJNZ does not touch A
    INC HL
    DJNZ .inner
    POP  BC
    DJNZ .outer          ; 3 × 256 = 768
    RET
