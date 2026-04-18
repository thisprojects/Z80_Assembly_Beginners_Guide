; set_attr
; Input:  B = y  (0–191)
;         C = x  (0–255)
;         A = attribute byte to write
; Output: none
; Destroys: HL, DE
set_attr:
    PUSH AF              ; PUSH AF saves A and Flags together — the only way to stack A
    CALL calc_attr_addr  ; HL = attribute file address  (overwrites A and DE)
    POP  AF              ; restore A (attribute byte) and Flags
    LD  (HL), A          ; write it
    RET
