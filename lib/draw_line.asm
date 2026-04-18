; draw_line
; Draw a line from (x1,y1) to (x2,y2) using Bresenham's algorithm.
; Input:  B = y1  (0–191)    C = x1  (0–255)
;         D = y2  (0–191)    E = x2  (0–255)
; Constraint: |x2-x1| and |y2-y1| must each be at most 63.
; Output: none    Destroys: A, B, C, D, E, H, L
draw_line:
    LD   A, C
    LD   (dl_x),  A         ; x = x1
    LD   A, B
    LD   (dl_y),  A         ; y = y1
    LD   A, E
    LD   (dl_x2), A         ; target x2
    LD   A, D
    LD   (dl_y2), A         ; target y2

    ; dx = |x2-x1|,  sx = +1 or $FF (-1)
    LD   A, E
    SUB  C                  ; A = x2 - x1 (signed)
    JP   P, .dx_pos
    NEG                     ; make positive for dx
    LD   (dl_dx), A
    LD   A, $FF
    LD   (dl_sx), A          ; sx = $FF (-1): moving left
    JR   .dy_calc
.dx_pos:
    LD   (dl_dx), A
    LD   A, 1
    LD   (dl_sx), A          ; sx = 1: moving right

.dy_calc:
    ; dy = |y2-y1|,  sy = +1 or $FF (-1)
    LD   A, D
    SUB  B                  ; A = y2 - y1 (signed)
    JP   P, .dy_pos
    NEG
    LD   (dl_dy), A
    LD   A, $FF
    LD   (dl_sy), A          ; sy = $FF (-1): moving up
    JR   .err_calc
.dy_pos:
    LD   (dl_dy), A
    LD   A, 1
    LD   (dl_sy), A          ; sy = 1: moving down

.err_calc:
    ; err = dx - dy
    LD   A, (dl_dx)
    LD   B, A
    LD   A, (dl_dy)
    LD   C, A
    LD   A, B
    SUB  C                  ; A = dx - dy
    LD   (dl_err), A

dl_loop:
    ; — Draw pixel at (x, y) —
    LD   A, (dl_y)
    LD   B, A
    LD   A, (dl_x)
    LD   C, A
    PUSH BC
    CALL set_pixel
    POP  BC

    ; — Check if done: x==x2 and y==y2 —
    LD   A, (dl_x2)
    LD   B, A
    LD   A, (dl_x)
    CP   B
    JR   NZ, dl_not_done
    LD   A, (dl_y2)
    LD   B, A
    LD   A, (dl_y)
    CP   B
    JR   Z, dl_done
dl_not_done:

    ; — e2 = 2 * err —
    LD   A, (dl_err)
    ADD  A, A               ; e2 = err * 2 (left shift by 1)
    LD   B, A               ; B = e2, preserved across both branch tests below

    ; — if e2 > -dy: err -= dy;  x += sx —
    ; Test: dy + e2 > 0  ↔  e2 > -dy
    LD   A, (dl_dy)
    ADD  A, B               ; A = dy + e2
    JR   Z, dl_skip_x       ; e2 == -dy: condition false
    JP   M, dl_skip_x       ; e2 < -dy: condition false
    LD   A, (dl_err)
    LD   C, A
    LD   A, (dl_dy)
    LD   D, A
    LD   A, C
    SUB  D                  ; err -= dy  (load dy to D, subtract from err in C)
    LD   (dl_err), A
    LD   A, (dl_x)
    LD   C, A
    LD   A, (dl_sx)
    ADD  A, C               ; x += sx  ($FF + x = x - 1 in 8-bit arithmetic)
    LD   (dl_x), A
dl_skip_x:

    ; — if e2 < dx: err += dx;  y += sy —
    ; Test: e2 - dx < 0  ↔  e2 < dx
    LD   A, B               ; restore e2 (B unchanged since we saved it)
    LD   C, A
    LD   A, (dl_dx)
    LD   D, A
    LD   A, C
    SUB  D                  ; A = e2 - dx
    JP   P, dl_skip_y       ; positive or zero: e2 >= dx, condition false
    LD   A, (dl_err)
    LD   C, A
    LD   A, (dl_dx)
    ADD  A, C               ; err += dx
    LD   (dl_err), A
    LD   A, (dl_y)
    LD   C, A
    LD   A, (dl_sy)
    ADD  A, C               ; y += sy
    LD   (dl_y), A
dl_skip_y:

    JR   dl_loop

dl_done:
    RET

dl_x:   DB 0   ; current x
dl_y:   DB 0   ; current y
dl_x2:  DB 0   ; target x
dl_y2:  DB 0   ; target y
dl_dx:  DB 0   ; |x2-x1|
dl_dy:  DB 0   ; |y2-y1|
dl_sx:  DB 0   ; x step: 1 or $FF
dl_sy:  DB 0   ; y step: 1 or $FF
dl_err: DB 0   ; Bresenham error accumulator
