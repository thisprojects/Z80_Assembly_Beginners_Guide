; fill_rect
; Draw a solid filled rectangle.
; Input:  B = y1  (0–191, top)
;         C = x1  (0–255, left)
;         D = y2  (0–191, bottom, must be >= y1)
;         E = x2  (0–255, right,  must be >= x1)
; Destroys: A, B, C, D, E, H, L
fill_rect:
    LD   A, D
    SUB  B                 ; y2 - y1
    INC  A                 ; row count = y2 - y1 + 1
    LD   (fr_rows), A
    LD   A, B
    LD   (fr_y),    A      ; save starting y
    LD   A, C
    LD   (fr_x1),   A      ; save x1
    LD   A, E
    LD   (fr_x2),   A      ; save x2

fr_loop:
    LD   A, (fr_y)
    LD   B, A              ; current row
    LD   A, (fr_x1)
    LD   C, A              ; x1
    LD   A, (fr_x2)
    LD   D, A              ; x2
    CALL draw_hline

    LD   A, (fr_y)
    INC  A
    LD   (fr_y), A          ; advance to next row

    LD   A, (fr_rows)
    DEC  A
    LD   (fr_rows), A
    JR   NZ, fr_loop
    RET

fr_y:    DB 0
fr_x1:   DB 0
fr_x2:   DB 0
fr_rows: DB 0
