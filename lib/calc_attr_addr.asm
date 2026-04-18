; calc_attr_addr
; Input:  B = y  (0–191)
;         C = x  (0–255)
; Output: HL = attribute byte address
; Destroys: A, DE
calc_attr_addr:
    LD  A, B
    RRCA                 ; }
    RRCA                 ; } divide y by 8 to get character row
    RRCA                 ; }
    AND %00011111        ; A = cy (0–23)
    LD  H, 0
    LD  L, A             ; HL = cy
    ADD HL, HL           ; HL = cy *  2
    ADD HL, HL           ; HL = cy *  4
    ADD HL, HL           ; HL = cy *  8
    ADD HL, HL           ; HL = cy * 16
    ADD HL, HL           ; HL = cy * 32
    LD  A, C
    RRCA                 ; }
    RRCA                 ; } divide x by 8 to get column
    RRCA                 ; }
    AND %00011111        ; A = cx (0–31)
    ADD A, L
    LD  L, A             ; HL = cy*32 + cx
    LD  DE, $5800
    ADD HL, DE           ; HL = attribute file address
    RET
