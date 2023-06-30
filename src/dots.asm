; ============================================================================
; Dots.
; ============================================================================

.equ Dots_Total, 6504                       ; ARM2=4900 max, ARM250=6400 easily

dots_y_table_1_p:
    .long dots_y_table_1_no_adr

dots_y_table_2_p:
    .long dots_y_table_2_no_adr

dots_y_t:
    .long 0

dots_total:
    .long Dots_Total

dots_screen_1_addr:
    .long 0x01fd8000

; R12=screen addr
dots_draw_all:
    str lr, [sp, #-4]!

    ; values are scr_base+y*320
    ; want scr_base+255*320-y*320
    ; want a-(scr_base+y*320)=scr_base+255*320-y*320
    ; therefore a=2*scr_base+255*320

    mov r11, r12, lsl #1
    add r11, r11, #255*Screen_Stride    ; screen bottom

    ; Scroll the y index for lookup.
    ldr r8, dots_y_t
    ldr r10, dots_total
    add r8, r8, #1
    cmp r8, r10
    movge r8, #0
    str r8, dots_y_t

    ; Work out which table to lookup for this screen buffer.
    ldr r10, dots_screen_1_addr
    cmp r12, r10
    ldreq r9, dots_y_table_1_p
    ldrne r9, dots_y_table_2_p

    ; Index the y table.
    add r9, r9, r8, lsl #2

    ; Set colours.
    mov r10, #0xff           ; colour
    mov r8, #0xaf

    ; Generated code with X values and Y mirroring baked in.
    .include "src/dot_plot_generated.asm"
    ; TODO: Generate code at init time.

    ldr pc, [sp], #4



.if 0
.rept Dots_Total/4
    ldmia r8!, {r0-r3}
    ldmia r9!, {r4-r7}

    add r14, r12, r4                    ; y already *320 in table.
    strb r10, [r14, r0]                 ; screen_y[screen_x]=colour index.
    add r14, r12, r5                    ; y already *320 in table.
    strb r10, [r14, r1]                 ; screen_y[screen_x]=colour index.
    add r14, r12, r6                    ; y already *320 in table.
    strb r10, [r14, r2]                 ; screen_y[screen_x]=colour index.
    add r14, r12, r7                    ; y already *320 in table.
    strb r10, [r14, r3]                 ; screen_y[screen_x]=colour index.

    sub r14, r11, r4                    ; mirror
    mov r4, r10, lsr #8
    strb r4, [r14, r0]
    sub r14, r11, r5                    ; mirror
    strb r4, [r14, r1]
    sub r14, r11, r6                    ; mirror
    strb r4, [r14, r2]
    sub r14, r11, r7                    ; mirror
    strb r4, [r14, r3]
.endr
.endif
