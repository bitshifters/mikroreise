; ============================================================================
; Debug helpers.
; TODO: Replace OS VDU routines with faster version.
; TODO: Could do fast direct-to-emulator logging if useful?
; ============================================================================

.if _DEBUG
.equ Debug_Temp_Len, 16
.equ Debug_Max_Vars, 8
.equ Debug_Max_Keys, 32

debug_num_keys:
    .long 0

debug_pressed_mask:
    .long 0

debug_prev_mask:
    .long 0

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

    ; TODO: Replace OS VDU handling for cursor etc.
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
	swi OS_WriteI+32        ; TODO: SPACE

    add r11, r11, #1
    cmp r11, #Debug_Max_Vars
    blt .1

.2:
	SET_BORDER 0x000000
	ldr pc, [sp], #4

; R0=key code to register.
; R1=addr of function to call.
; R2=param to call the function with.
; Trashes: R3-R4.
debug_register_key:
    adr r4, debug_key_stack
    ldr r3, debug_num_keys
    cmp r3, #Debug_Max_Keys
    adrge r0, error_out_of_keys
    swige OS_GenerateError

    add r4, r4, r3, lsl #3
    add r4, r4, r3, lsl #2
    stmia r4, {r0-r2}

    add r3, r3, #1
    str r3, debug_num_keys
    mov pc, lr

; R1=0 key up or 1 key down
; R2=internal key number (RMKey_*)
debug_handle_keypress:
    stmfd sp!, {r3-r6}
    adr r4, debug_key_stack
    ldr r3, debug_num_keys
    add r4, r4, r3, lsl #3
    add r4, r4, r3, lsl #2
    mov r5, #1
    mov r5, r5, lsl r3      ; key bit.
    ldr r3, debug_pressed_mask
.1:
    ; Any bits left?
    movs r5, r5, lsr #1
    beq .2                  ; no more bits.

    ; Check key code.
    ldr r6, [r4, #-12]!
    cmp r6, r2
    bne .1

    ; Key matches so mask bit in/out.
    cmp r1, #0
    biceq r3, r3, r5
    orrne r3, r3, r5
    b .1

.2:
    str r3, debug_pressed_mask
    ldmfd sp!, {r3-r6}
    mov pc, lr


debug_do_key_callbacks:
	str lr, [sp, #-4]!

    ldr r0, debug_pressed_mask
	ldr r2, debug_prev_mask
	mvn r2, r2				; ~old
	and r2, r0, r2			; new & ~old		; diff bits
	str r0, debug_prev_mask
	and r4, r2, r0			; diff bits & key down bits	

    adr r3, debug_key_stack
    ldr r0, debug_num_keys
    add r3, r3, r0, lsl #3
    add r3, r3, r0, lsl #2

    mov r5, #1
    mov r5, r5, lsl r0      ; key bit.
.1:
    ; Any bits left?
    movs r5, r5, lsr #1
    beq .2                  ; no more bits.

    ; Key down?
    sub r3, r3, #12
    tst r4, r5
    beq .1

    ; Make key callback.
    ldr r0, [r3, #4]        ; func.
    ldr r1, [r3, #8]        ; data.
    adr lr, .1
    mov pc, r0

.2:
    ldr pc, [sp], #4

; R1=byte addr.
debug_toggle_byte:
    ldrb r0, [r1]
    eor r0, r0, #1
    strb r0, [r1]
    mov pc, lr

debug_set_byte_true:
    mov r0, #1
    strb r0, [r1]
    mov pc, lr


debug_temp_string:
	.skip Debug_Temp_Len

debug_var_stack:
    .skip 4*Debug_Max_Vars

error_out_of_vars:
    .long 0
    .byte "Out of debug vars!"
    .p2align 2
    .long 0

debug_key_stack:
    .skip 12*Debug_Max_Keys

error_out_of_keys:
    .long 0
    .byte "Out of debug keys!"
    .p2align 2
    .long 0

.endif
