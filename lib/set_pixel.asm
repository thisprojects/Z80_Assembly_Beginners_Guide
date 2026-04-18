; set_pixel
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Output: none
; Destroys: A, B, HL
set_pixel:
    CALL calc_pixel_addr  ; HL = byte address,  A = bitmask
    OR   (HL)             ; set target bit, preserve the other seven
    LD   (HL), A          ; write back
    RET
