; draw_rect
; Draw a hollow rectangle.
; Input:  B = y1  (0–191, top)
;         C = x1  (0–255, left)
;         D = y2  (0–191, bottom, must be >= y1)
;         E = x2  (0–255, right,  must be >= x1)
; Destroys: A, B, C, D, E, H, L
draw_rect:
    ; Top edge: y=y1, x1 to x2
    PUSH BC
    PUSH DE
    LD   D, E              ; draw_hline needs x2 in D; E holds x2, D holds y2
    CALL draw_hline        ; B=y1, C=x1, D=x2
    POP  DE
    POP  BC

    ; Bottom edge: y=y2, x1 to x2
    PUSH BC
    PUSH DE
    LD   B, D              ; y = y2
    LD   D, E              ; draw_hline needs x2 in D
    CALL draw_hline        ; B=y2, C=x1, D=x2
    POP  DE
    POP  BC

    ; Skip vertical edges if height is 1 (y1 == y2)
    LD   A, B
    CP   D                 ; y1 == y2?
    JR   Z, dr_no_vert

    ; Left edge: x=x1, y1+1 to y2-1
    PUSH BC
    PUSH DE
    INC  B                 ; y1+1 — skip corner already drawn
    DEC  D                 ; y2-1 — skip corner already drawn
    CALL draw_vline        ; B=y1+1, C=x1, D=y2-1
    POP  DE
    POP  BC

    ; Right edge: x=x2, y1+1 to y2-1
    INC  B                 ; y1+1
    DEC  D                 ; y2-1
    LD   C, E              ; x = x2
    CALL draw_vline        ; B=y1+1, C=x2, D=y2-1
dr_no_vert:
    RET
