; draw_hline
; Draw a horizontal line on pixel row y from x1 to x2.
; Input:  B = y   (0–191)
;         C = x1  (0–255, left end)
;         D = x2  (0–255, right end, must be >= x1)
; Output: none
; Destroys: A, B, C, D, E, H, L
; Note: calc_pixel_addr preserves C and D, so x1 and x2 survive the CALL.
draw_hline:
    CALL calc_pixel_addr   ; HL = byte address of x1  (C=x1 and D=x2 are preserved)

    ; — Same-byte check: XOR high bits of x1 and x2 —
    LD   A, D
    XOR  C
    AND  %11111000         ; non-zero if x1 and x2 are in different bytes
    JR   Z, .same_byte

    ; — Left partial byte: mask = $FF >> (x1 & 7) —
    LD   A, C
    AND  %00000111         ; shift count = x1 mod 8
    LD   B, A
    LD   A, $FF
    JR   Z, .lm_done       ; count=0: x1 is at leftmost bit, mask stays $FF
.lm_loop:
    SRL  A                 ; shift right, 0 fills from top — one step of $FF >> n
    DJNZ .lm_loop
.lm_done:
    OR   (HL)              ; set pixels from x1 down to end of byte, preserve left neighbours
    LD   (HL), A
    INC  L                 ; next byte (same row — INC L safe, not INC HL)

    ; — Middle full bytes: count = (x2>>3) - (x1>>3) - 1 —
    ; Extract byte column via three RRCA then AND %00011111
    LD   A, D
    RRCA
    RRCA
    RRCA
    AND  %00011111         ; x2 byte column (0–31)
    LD   E, A
    LD   A, C
    RRCA
    RRCA
    RRCA
    AND  %00011111         ; x1 byte column (0–31)
    LD   B, A
    LD   A, E
    SUB  B                 ; x2col - x1col
    DEC  A                 ; - 1 = number of middle bytes
    JR   Z, .right_byte    ; zero: x1 and x2 are adjacent bytes, no middle
    JR   C, .right_byte    ; carry guard (should not occur)
    LD   B, A
.middle:
    LD   (HL), $FF         ; all 8 pixels set
    INC  L
    DJNZ .middle

.right_byte:
    ; — Right partial byte: mask = $FF << (7 - x2 & 7) —
    LD   A, D
    AND  %00000111         ; x2 mod 8
    LD   B, A
    LD   A, 7
    SUB  B                 ; shift count = 7 - (x2 mod 8)
    LD   B, A
    LD   A, $FF
    JR   Z, .rm_done       ; count=0: x2 is at rightmost bit, mask stays $FF
.rm_loop:
    SLA  A                 ; shift left, 0 fills from bottom — one step of $FF << n
    DJNZ .rm_loop
.rm_done:
    OR   (HL)              ; set pixels from start of byte down to x2, preserve right neighbours
    LD   (HL), A
    RET

.same_byte:
    ; — Both x1 and x2 in the same byte: AND the left and right masks —
    LD   A, C
    AND  %00000111
    LD   B, A
    LD   A, $FF
    JR   Z, .sb_lm_done
.sb_lm_loop:
    SRL  A
    DJNZ .sb_lm_loop
.sb_lm_done:
    LD   E, A              ; E = left mask

    LD   A, D
    AND  %00000111
    LD   B, A
    LD   A, 7
    SUB  B
    LD   B, A
    LD   A, $FF
    JR   Z, .sb_rm_done
.sb_rm_loop:
    SLA  A
    DJNZ .sb_rm_loop
.sb_rm_done:
    AND  E                 ; intersection: only the pixels strictly between x1 and x2
    OR   (HL)
    LD   (HL), A
    RET
