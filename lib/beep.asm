ORG 0x8000

; Play a beep
LD HL, 0x00C0        ; pitch (lower = higher pitch)
LD DE, 0x0040        ; duration (higher = longer)
CALL 0x03B5          ; BEEPER routine

RET

END 0x8000
