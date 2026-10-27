ORG 0x8000

; Open channel 2 (main screen)
LD A, 2
CALL 0x1601

; Print 'A' using RST 0x10
LD A, 'A'
RST 0x10

RET

END 0x8000
