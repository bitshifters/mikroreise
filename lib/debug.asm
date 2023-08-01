; ============================================================================
; Debug helpers.
; TODO: Replace OS VDU routines with faster version.
; TODO: Could do fast direct-to-emulator logging if useful?
; ============================================================================

.if _DEBUG
.equ Debug_Temp_Len, 16
.equ Debug_Max_Vars, 8

; Plot a string to the screen at the current cursor position.
; R0=ptr to null terminated string.
debug_plot_string:
    ; TODO: Replace OS VDU handling with faster version.
    swi OS_WriteO
    mov pc, lr

; R0=VDU character
debug_vdu:
    ; TODO: Replace OS VDU handling with faster version.
    swi OS_WriteC
    mov pc, lr

; R0=value to plot as %04x
; Trashes R1-R2.
debug_plot_hex4:
    adr r1, debug_temp_string
    mov r2, #Debug_Temp_Len
    swi OS_ConvertHex4

    adr r0, debug_temp_string
    b debug_plot_string

; R0=address of a variable to add to the debug display.
; Trashes: R1-R3
debug_register_var:
    adr r1, debug_var_stack
    mov r2, #0
.1:
    ldr r3, [r1, r2, lsl #2]
    cmp r3, #0
    streq r0, [r1, r2, lsl #2]
    moveq pc, lr

    add r2, r2, #1
    cmp r2, #Debug_Max_Vars
    blt .1

    adr r0, error_out_of_vars
    swi OS_GenerateError
    mov pc, lr

; R12=screen addr.
debug_plot_vars:
	ldrb r0, debug_show_info
	cmp r0, #0
	moveq pc, lr

	str lr, [sp, #-4]!

	SET_BORDER 0xffffff		; white = debug

	mov r0, #30	; home cursor
	swi OS_WriteC
	mov r0, #17	; set text colour
	swi OS_WriteC
	mov r0, #15
	swi OS_WriteC

    adr r10, debug_var_stack
    mov r11, #0
.1:
    ldr r1, [r10, r11, lsl #2]
    cmp r1, #0
    beq .2

    ldr r0, [r1]
    bl debug_plot_hex4
	swi OS_WriteI+32        ; SPACE

    add r11, r11, #1
    cmp r11, #Debug_Max_Vars
    blt .1

.2:
	SET_BORDER 0x000000
	ldr pc, [sp], #4


debug_temp_string:
	.skip Debug_Temp_Len

debug_var_stack:
    .skip 4*Debug_Max_Vars

error_out_of_vars:
    .long 0
    .byte "Out of debug vars!"
    .p2align 2
    .long 0

.endif
