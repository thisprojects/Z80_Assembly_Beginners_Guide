ORG 0x8000

; Open channel 2
LD A, 2
CALL 0x1601

; Set print position to row 10, column 5
; CL-SET counts from the bottom-right: B = 24 - row, C = 33 - column
LD B, 24 - 10        ; row 10 (B = 24 - row)
LD C, 33 - 5         ; column 5 (C = 33 - column)
CALL 0x0DD9          ; CL-SET: position the cursor

; Now print a message at that position
LD A, 'X'
RST 0x10

RET

END 0x8000
