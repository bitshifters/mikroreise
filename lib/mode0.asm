; ============================================================================
; MODE 0 plot routines (!)
; ============================================================================

; For compatibility try to map against span_gen.asm registers.
; r0 = not used
; r1 = X end (in pixels)
; r2 = not used [typically X start (in pixels)] <= colour word
; r3 = temp [word read from screen]
; r4 = not used <= colour word
; r5 = not used <= colour word
; r6 = temp [construct word to write]
; r7 = not used
; r8 = not used [typically Y rasterline for outer loop]
; r9 = colour word [preserved]
; r10 = ptr to screen addr [updated]
; r11 = ptr to start of screen rasterline [updated]
; r12 = not used
; r13 = not used
; r14 = link address

; R0=colour word.
; R1=screen base addr.
; R2=x start
; R3=x end
; R4=y line
mode0_test_plot_span:
    mov r9, r0                      ; colour word.
    mov r6, r2                      ; x start
    add r11, r1, r4, lsl #6
    add r11, r11, r4, lsl #4        ; scanline=base+y*80
    mov r1, r3                      ; x end

    ; Fall through!

; r1 = x end (can trash).
; r3 = temp.
; r6 = x start (can trash).
; r9 = colour word [preserved].
; r10 = ptr to start / current screen word.
; r11 = ptr to start of scanline.
; r12 = ptr to last screen word.
; Plot a span of pixels supporting dithering, i.e. don't shift colour word.
mode0_plot_span:
    add r10, r11, r6, lsr #3        ; nearest byte!
    bic r10, r10, #3                ; start word.

    add r12, r11, r1, lsr #3
    bic r12, r12, #3                ; end word.

    cmp r10, r12
    bne .1

    ; x start & end both in same word.
    ; TODO: This code is duplicated.
    ands r6, r6, #31                ; x_start (pixels)
    ands r1, r1, #31                ; x_end (pixels)
    rsb r1, r1, #32

    ; Create mask from 0xffffffff << x_start >> x_end
    mov r3, #-1
    mov r6, r3, lsl r6
    mov r1, r3, lsr r1
    and r3, r1, r6

    ldr r12, [r10]                  ; load screen word.
    bic r12, r12, r3                ; mask out screen bits.
    and r6, r9, r3                  ; mask out colour bits.
    orr r12, r12, r6                ; mask together
    str r12, [r10], #4              ; store screen word.
    mov pc, lr

.1:
    ; Mask N pixels to get to word boundary.
    ands r6, r6, #31                ; x_start (pixels)
    beq .2                          ; already aligned.

    ; Create mask from 0xffffffff << x_start
    mov r3, #-1
    mov r3, r3, lsl r6

    ldr r12, [r10]                  ; load screen word.
    bic r12, r12, r3                ; mask out screen bits.
    and r6, r9, r3                  ; mask out colour bits.
    orr r12, r12, r6                ; mask together
    str r12, [r10], #4              ; store screen word.

    ; TODO: Can we avoid recalculating this?
    add r12, r11, r1, lsr #3
    bic r12, r12, #3                ; end word.

.2:
    ; Plot N words.
    ; TODO: Unroll this loop.
    cmp r10, r12
    beq .3
    str r9, [r10], #4
    b .2

.3:
    ; Mask N pixels to finish.
    ands r1, r1, #31                ; x_end (pixels)
    beq .4                          ; nothing to do.

    ; Create mask from 0xffffffff << x_end
    mov r3, #-1
    mov r3, r3, lsl r1

    ldr r12, [r10]                  ; load screen word.
    and r12, r12, r3                ; mask out screen bits.
    bic r6, r9, r3                  ; mask out colour bits.
    orr r12, r12, r6                ; mask together
    str r12, [r10], #4              ; store screen word.

.4:
    mov pc, lr

; TODO: Maybe generated code for unroll somehow?
