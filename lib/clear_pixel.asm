; clear_pixel
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Output: none
; Destroys: A, B, HL
clear_pixel:
    CALL calc_pixel_addr  ; HL = byte address,  A = bitmask  (one 1, seven 0s)
    CPL                   ; invert A  →  inverted mask  (one 0, seven 1s)
    AND  (HL)             ; clear target bit, preserve the other seven
    LD   (HL), A          ; write back
    RET
