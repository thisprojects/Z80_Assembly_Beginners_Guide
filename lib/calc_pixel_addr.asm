; calc_pixel_addr
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Output: HL = display file address of the byte containing the pixel
;          A = bitmask for that pixel  (bit 7 = leftmost)
; Destroys: B
calc_pixel_addr:
    LD  A, B
    AND %11000000        ; isolate TT (bits 7–6)
    RRCA                 ; }
    RRCA                 ; } rotate TT right 3
    RRCA                 ; }
    OR  %01000000        ; set fixed $40 base
    LD  H, A             ; H = 010TT000
    LD  A, B
    AND %00000111        ; isolate LLL (bits 2–0)
    OR  H                ; A = 010TTLLL
    LD  H, A             ; H complete

    LD  A, B
    AND %00111000        ; isolate RRR (bits 5–3)
    RLCA                 ; } rotate RRR left 2
    RLCA                 ; }
    LD  L, A             ; L = RRR00000
    LD  A, C
    RRCA                 ; }
    RRCA                 ; } divide x by 8
    RRCA                 ; }
    AND %00011111        ; mask off rotated-in bits
    OR  L                ; A = RRRCCCCC
    LD  L, A             ; L complete — HL = display file address

    LD  A, C
    AND %00000111        ; A = bit position within byte (0–7)
    LD  B, A             ; B = shift count
    LD  A, %10000000     ; start with leftmost pixel mask
    JR  Z, .mask_done    ; shift count was 0: mask already correct
.mask_shift:
    RRCA                 ; move mask right by one
    DJNZ .mask_shift     ; repeat B times
.mask_done:
    RET
