; ============================================================================
; MODE 9 screen routines
; ============================================================================

; R12 = screen address
; trashes r0-r9
screen_cls:
	add r9, r12, #Screen_Bytes
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0
	mov r5, #0
	mov r6, #0
	mov r7, #0
.if 0
.1:
	.rept Screen_Stride / 32
	stmia r12!, {r0-r7}
    .endr
	cmp r12, r9
	blt .1
.else
    .rept Screen_Bytes / 32
	stmia r12!, {r0-r7}
    .endr
.endif
	mov pc, lr

.if 0
; R12 = screen address
screen_dup_lines:
	add r9, r12, #Screen_Bytes
	add r11, r12, #Screen_Stride
.1:
	.rept Screen_Stride / 32
	ldmia r12!, {r0-r7}
	stmia r11!, {r0-r7}
	.endr
	add r12, r12, #Screen_Stride
	add r11, r11, #Screen_Stride
	cmp r12, r9
	blt .1
	mov pc, lr
.endif

static_screen_p:
    .long 0

static_palette_p:
    .long 0

static_set_palette:
    ldr r2, static_palette_p
    cmp r2, #0
    moveq pc, lr
    b palette_set_block

; R12=screen address
static_copy_screen:
    ldr r11, static_screen_p
    cmp r11, #0
    moveq pc, lr

; R11=source address
; R12=screen address
screen_copy:
    mov r10, #Screen_Height
.1:
    .rept Screen_Stride / 40
	ldmia r11!, {r0-r9}
	stmia r12!, {r0-r9}
    .endr
    subs r10, r10, #1
    bne .1
    mov pc, lr
