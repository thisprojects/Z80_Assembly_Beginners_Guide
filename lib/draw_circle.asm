; draw_circle
; Draw a circle using the midpoint algorithm.
; Input:  B = cy  (centre y, 0-191)
;         C = cx  (centre x, 0-255)
;         D = radius  (must keep centre +/- radius within screen bounds)
; Destroys: A, B, C, D, E, H, L
; Limitation: dc_d is a single signed byte. For radius > 129 the initial
;             value 1-radius underflows, producing an incorrect circle.
;             For typical Spectrum use (radius <= 95) this is not a concern.
draw_circle:
    LD   A, B
    LD   (dc_cy), A        ; save centre y
    LD   A, C
    LD   (dc_cx), A        ; save centre x
    LD   A, D              ; radius
    LD   (dc_y),  A        ; y offset starts at radius
    XOR  A
    LD   (dc_x),  A        ; x offset starts at 0

    ; d = 1 - radius
    LD   A, 1
    SUB  D
    LD   (dc_d),  A

dc_loop:
    ; while x <= y
    LD   A, (dc_x)
    LD   B, A
    LD   A, (dc_y)
    CP   B                 ; y - x: if x > y, done
    JR   C, dc_done        ; carry set means y < x

    ; plot 8 symmetric pixels
    CALL dc_plot8

    ; x += 1
    LD   A, (dc_x)
    INC  A
    LD   (dc_x), A

    ; if d < 0: d += 2*x + 1
    LD   A, (dc_d)
    OR A
    JP   M, dc_d_neg

; d >= 0: d += 2*(x-y) + 1,  y -= 1
    LD   B, A              ; save d

    ; Update Y first
    LD   A, (dc_y)
    DEC  A
    LD   (dc_y), A         ; y -= 1
    LD   D, A              ; D = new y

    ; Calculate 2*(x-y) + 1
    LD   A, (dc_x)         ; A = new x
    SUB  D                 ; A = x - y
    ADD  A, A              ; 2*(x - y)
    INC  A                 ; 2*(x - y) + 1
    ADD  A, B              ; d += 2*(x-y) + 1
    LD   (dc_d), A
    JR   dc_loop

dc_d_neg:
    ; d += 2*x + 1
    LD   B, A              ; save d
    LD   A, (dc_x)
    ADD  A, A              ; 2*x
    INC  A                 ; 2*x + 1
    ADD  A, B              ; d += 2*x + 1
    LD   (dc_d), A
    JR   dc_loop

dc_done:
    RET

; dc_plot8 -- plot the 8 symmetric pixels for current (x, y) offsets
; set_pixel destroys all registers, so dc_x and dc_y are reloaded from
; memory before every pixel. D = x offset, E = y offset throughout.
dc_plot8:
    ; (cx+x, cy+y)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    ADD  A, E
    LD   B, A
    LD   A, (dc_cx)
    ADD  A, D
    LD   C, A
    CALL set_pixel

    ; (cx-x, cy+y)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    ADD  A, E
    LD   B, A
    LD   A, (dc_cx)
    SUB  D
    LD   C, A
    CALL set_pixel

    ; (cx+x, cy-y)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    SUB  E
    LD   B, A
    LD   A, (dc_cx)
    ADD  A, D
    LD   C, A
    CALL set_pixel

    ; (cx-x, cy-y)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    SUB  E
    LD   B, A
    LD   A, (dc_cx)
    SUB  D
    LD   C, A
    CALL set_pixel

    ; (cx+y, cy+x)  -- x and y roles swap
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    ADD  A, D
    LD   B, A
    LD   A, (dc_cx)
    ADD  A, E
    LD   C, A
    CALL set_pixel

    ; (cx-y, cy+x)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    ADD  A, D
    LD   B, A
    LD   A, (dc_cx)
    SUB  E
    LD   C, A
    CALL set_pixel

    ; (cx+y, cy-x)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    SUB  D
    LD   B, A
    LD   A, (dc_cx)
    ADD  A, E
    LD   C, A
    CALL set_pixel

    ; (cx-y, cy-x)
    LD   A, (dc_x)
    LD   D, A
    LD   A, (dc_y)
    LD   E, A
    LD   A, (dc_cy)
    SUB  D
    LD   B, A
    LD   A, (dc_cx)
    SUB  E
    LD   C, A
    CALL set_pixel

    RET

dc_cx: DB 0   ; centre x
dc_cy: DB 0   ; centre y
dc_x:  DB 0   ; current x offset (0 -> radius)
dc_y:  DB 0   ; current y offset (radius -> 0)
dc_d:  DB 0   ; decision variable
