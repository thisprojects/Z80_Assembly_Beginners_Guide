; toggle_pixel
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Output: none
; Destroys: A, B, HL
toggle_pixel:
    CALL calc_pixel_addr  ; HL = byte address,  A = bitmask
    XOR  (HL)             ; flip target bit, leave the other seven unchanged
    LD   (HL), A          ; write back
    RET
