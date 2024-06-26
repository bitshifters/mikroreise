; ============================================================================
; Sine and cosine functions.
; TODO: Add run-time sinus table generation routine from Rose.
; ============================================================================

.equ LibSine_TableBits, 13
.equ LibSine_TableSize, 1<<LibSine_TableBits
.equ LibSine_TableShift, 32-LibSine_TableBits

sinus_table_p:
    .long sinus_table_no_adr

; Sine.
; Parameters:
;  R0 = radians [0.0, 1.0] at fixed point precision. [s1.16]
; Returns:
;  R0 = sin(2 * PI * radians)
; Trashes: R9
sine:
    ldr r9, sinus_table_p
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #LibSine_TableShift      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; Cosine.
; Parameters:
;  R0 = radians [0.0, 1.0] at fixed point precision. [s1.16]
; Returns:
;  R0 = cos(2 * PI * radians)
; Trashes: R9
cosine:
    ldr r9, sinus_table_p
    add r0, r0, #MATHS_CONST_QUARTER                    ; add PI/2
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #LibSine_TableShift      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; Sine and Cosine.
; Parameters:
;  R0 = angle in brads [0-255]
; Returns:
;  R0 = sin(angle)
;  R1 = cos(angle)
; Trashes: R9
sin_cos:
    ldr r9, sinus_table_p
    mov r0, r0, asr #8                      ; convert brads to radians
    add r1, r0, #MATHS_CONST_QUARTER                    ; add PI/2
    mov r1, r1, asl #PRECISION_BITS         ; remove integer part
    mov r1, r1, lsr #LibSine_TableShift      ; remove insignificant bits
    ldr r1, [r9, r1, lsl #2]                ; lookup word
    mov r0, r0, asl #PRECISION_BITS         ; remove integer part
    mov r0, r0, lsr #LibSine_TableShift      ; remove insignificant bits
    ldr r0, [r9, r0, lsl #2]                ; lookup word
    mov pc, lr

; ============================================================================
