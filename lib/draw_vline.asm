; draw_vline
; Draw a vertical line on pixel column x from y1 to y2.
; Input:  B = y1  (0–191, top)
;         C = x   (0–255)
;         D = y2  (0–191, bottom, must be >= y1)
; Output: none
; Destroys: A, B, C, D, E, H, L
draw_vline:
    PUSH BC                ; save y1 (B) — calc_pixel_addr destroys B
    CALL calc_pixel_addr   ; HL = byte address,  A = bitmask for column x
    LD   E, A              ; save bitmask in E before POP overwrites A
    POP  BC                ; restore B = y1  (C = x, no longer needed)

    LD   A, D              ; y2
    SUB  B                 ; y2 - y1  (B = y1 restored by POP)
    INC  A                 ; pixel count = y2 - y1 + 1
    LD   B, A              ; B = DJNZ counter

    LD   C, E              ; bitmask into C
dv_loop:
    LD   A, C              ; bitmask
    OR   (HL)              ; set pixel, preserve neighbours
    LD   (HL), A
    ; advance HL to the next pixel row
    LD   A, H
    AND  $07               ; isolate scan line field (LLL, H bits 2:0)
    CP   $07               ; at scan line 7?
    JR   Z, dv_cross       ; yes: step the character row explicitly
    INC  H                 ; no: simple scan line increment
    DJNZ dv_loop
    RET
dv_cross:
    ; Scan line 7 → 0: reset LLL, step RRR in L
    LD   A, H
    AND  $F8               ; clear H bits 2:0 (LLL = 0), T field in bits 4:3 preserved
    LD   H, A
    LD   A, L
    ADD  A, $20            ; step RRR (character row field, L bits 7:5)
    LD   L, A
    JR   NC, dv_next       ; no carry: still in same third
    LD   A, H
    ADD  A, $08            ; RRR overflowed: step TT (third field, H bits 4:3)
    LD   H, A
dv_next:
    DJNZ dv_loop
    RET
