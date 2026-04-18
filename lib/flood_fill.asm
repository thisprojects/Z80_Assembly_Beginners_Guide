; flood_fill
; 4-connected flood fill from a seed pixel.
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Fills all unset pixels reachable from (x,y) by 4-connectivity.
; Warning: stack depth grows with fill area. Safe for small regions only.
; Destroys: A, B, C, H, L (and uses stack heavily)
flood_fill:
    ; bounds check: stay within 0–255 x, 0–191 y
    LD   A, B
    CP   192
    RET  NC               ; y >= 192: off screen

    ; check if pixel is already set — if so, stop
    PUSH BC
    CALL calc_pixel_addr   ; HL = byte addr, A = bitmask
    LD   B, A              ; save bitmask
    AND  (HL)              ; test pixel
    JR   NZ, ff_already_set

    ; set the pixel
    LD   A, B
    OR   (HL)
    LD   (HL), A

    POP  BC                ; restore y=B, x=C

    ; recurse: up (y-1)
    PUSH BC
    DEC  B
    CALL flood_fill
    POP  BC

    ; recurse: down (y+1)
    PUSH BC
    INC  B
    CALL flood_fill
    POP  BC

    ; recurse: left (x-1)
    PUSH BC
    DEC  C
    CALL flood_fill
    POP  BC

    ; recurse: right (x+1)
    INC  C
    JP   flood_fill        ; tail call — no PUSH/POP needed for last branch

ff_already_set:
    POP  BC
    RET
