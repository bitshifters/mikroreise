; ============================================================================
; Archie-Verse: a Acorn Archimedes demo/trackmo framework.
;	1. <Group> presents <demo> at <party>
;	2. 2D effect 1
;	3. 3D effect 1
;	4. Greets
;	5. 2D effect 2
;	6. 3D effect 2
;	7. Credits
;	8. Ending
; ============================================================================

.equ _DEBUG, 1
.equ _DEBUG_RASTERS, (_DEBUG && 1)
.equ _DEBUG_SHOW, (_DEBUG && 1)     ; TODO: Fast debug text on screen.
.equ _CHECK_FRAME_DROP, (!_DEBUG && 1)

.equ _DEBUG_DEFAULT_PLAY_PAUSE, 1		; play
.equ _DEBUG_DEFAULT_SHOW_RASTERS, 1
.equ _DEBUG_DEFAULT_SHOW_INFO, 0		; slow so off by default.

.equ Sample_Speed_SlowCPU, 48		; ideally get this down for ARM2
.equ Sample_Speed_FastCPU, 16		; ideally 16us for ARM250+

.equ _WIDESCREEN, 0

.equ Screen_Banks, 2

.equ Screen_Mode, 9
.equ Screen_Width, 320
.if _WIDESCREEN
.equ Vdu_Mode, 97					; MODE 9 widescreen (320x180)
									; or 96 for MODE 13 widescreen (320x180)
.equ Screen_Height, 180
.equ Mode_Height, 180
.else
.equ Vdu_Mode, 9
.equ Screen_Height, 256
.equ Mode_Height, 256
.endif
.equ Screen_PixelsPerByte, 2
.equ Screen_Stride, Screen_Width/Screen_PixelsPerByte
.equ Screen_Bytes, Screen_Stride*Screen_Height
.equ Mode_Bytes, Screen_Stride*Mode_Height

.include "lib/swis.h.asm"
.include "lib/lib_config.h.asm"
.include "lib/maths.h.asm"

; ============================================================================
; Macros.
; ============================================================================

.macro RND seed, bit, temp
    TST    \bit, \bit, LSR #1                       ; top bit into Carry
    MOVS   \temp, \seed, RRX                        ; 33 bit rotate right
    ADC    \bit, \bit, \bit                         ; carry into lsb of R1
    EOR    \temp, \temp, \seed, LSL #12             ; (involved!)
    EOR    \seed, \temp, \temp, LSR #20             ; (similarly involved!)
.endm

.macro SET_BORDER rgb
	.if _DEBUG_RASTERS
	mov r4, #\rgb
	ldrb r0, debug_show_rasters
	cmp r0, #0
	blne palette_set_border
	.endif
.endm

.macro DEBUG_REGISTER_VAR addr                      ; TODO: Move this to debug.h.asm?
    .if _DEBUG
    adr r0, \addr
    bl debug_register_var
    .endif
.endm

; ============================================================================
; App defines
; ============================================================================

.equ VU_Bars_Effect, 1					; 'fake' bars
.equ VU_Bars_Gravity, 1					; lines per vsync

.equ AutoPlay_Default, 1
.equ Stereo_Positions, 1		; Amiga (full) stereo positions.

.equ KeyBit_Space, 0
.equ KeyBit_A, 1
.equ KeyBit_S, 2
.equ KeyBit_D, 3
.equ KeyBit_R, 4
.equ KeyBit_ArrowRight, 5
.equ KeyBit_C, 6
.equ KeyBit_0, 10
.equ KeyBit_1, 11
.equ KeyBit_2, 12
.equ KeyBit_3, 13
.equ KeyBit_4, 14
.equ KeyBit_5, 15
.equ KeyBit_6, 16
.equ KeyBit_7, 17
.equ KeyBit_8, 18
.equ KeyBit_9, 19

; TODO: Remove Timer1 split if not necessary.
.equ RasterSplitLine, 56+90			; 56 lines from vsync to screen start

; ============================================================================
; Code Start
; ============================================================================

.org 0x8000

Start:
    ldr sp, stack_p
	B main

stack_p:
	.long stack_base_no_adr

; ============================================================================
; Main
; ============================================================================

main:
	; Set screen MODE & disable cursor
	adr r0, vdu_screen_disable_cursor
	mov r1, #12
	swi OS_WriteN

	; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	MOV r0, #DynArea_Screen
	MOV r2, #Mode_Bytes * Screen_Banks
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	CMP r1, r2
	ADRCC r0, error_noscreenmem
	SWICC OS_GenerateError

	; Clear all screen buffers
	mov r1, #1
.1:
	str r1, write_bank

	; CLS bank N
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte
	SWI OS_WriteI + 12		; cls

	add r1, r1, #1
	cmp r1, #Screen_Banks
	ble .1

	; Seed RND.
	swi OS_ReadMonotonicTime
	str r0, rnd_seed

    ; Register debug vars.
    DEBUG_REGISTER_VAR vsync_count
    DEBUG_REGISTER_VAR vsync_delta

	; Install our own IRQ handler - thanks Steve! :)
	bl install_irq_handler

	; EARLY INIT / LOAD STUFF HERE! 
	bl lib_init
	; R12=top of RAM used.

	; Bootstrap the main sequence.
	adr r0, seq_main_program
	bl script_add_program

    ; Tick script once for module init.
    bl script_tick_all

.if 0
	; Count how long the init takes as a very rough estimate of CPU speed.
	ldr r1, vsync_count
	cmp r1, #80		; ARM3~=20, ARM250~=70, ARM2~=108
	movge r0, #Sample_Speed_SlowCPU
	movlt r0, #Sample_Speed_FastCPU

	; Setup QTM for our needs.
	swi QTM_SetSampleSpeed

	mov r0, #VU_Bars_Effect
	mov r1, #VU_Bars_Gravity
	swi QTM_VUBarControl
.else
    mov r0, #Sample_Speed_SlowCPU
    swi QTM_SetSampleSpeed
.endif

	mov r0, #0
	mov r1, #Stereo_Positions
	swi QTM_Stereo

	; Load the music.
	mov r0, #-1					; load from address and copy to RMA.
	adr r1, music_table
	ldr r1, [r1, #0]
	swi QTM_Load

	; LATE INITALISATION HERE!
	bl get_next_bank_for_writing

	; Set palette (shows screen).
	ldr r2, palette_p
	bl palette_set_block

	; Claim the Event vector.
	MOV r0, #EventV
	ADR r1, event_handler
	MOV r2, #0
	SWI OS_Claim

	; Claim the Error vector.
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Claim

	; Play music!
	swi QTM_Start

	; Enable key pressed event.
	mov r0, #OSByte_EventEnable
	mov r1, #Event_KeyPressed
	SWI OS_Byte

main_loop:

	; ========================================================================
	; PREPARE
	; ========================================================================

    .if _DEBUG
    bl debug_tick
    .endif

	; exit if Escape is pressed
	swi OS_ReadEscapeState
	bcs exit

	.if _DEBUG
	ldrb r0, debug_play_pause
	cmp r0, #0
	bne .3

	ldrb r0, debug_play_step
	cmp r0, #0
	beq main_loop_skip_tick
	.3:
	.endif

	; ========================================================================
	; TICK
	; ========================================================================

	bl script_tick_all
	bl fx_tick_layers

    ; TODO: Update frame counter.

main_loop_skip_tick:

	; ========================================================================
	; VSYNC
	; ========================================================================

	; This will block if there isn't a bank available to write to.
	bl get_next_bank_for_writing

	; Useful to determine frame rate for debug.
	.if _DEBUG || _CHECK_FRAME_DROP
	ldr r1, last_vsync
	ldr r2, vsync_count
	sub r0, r2, r1
	str r2, last_vsync
	str r0, vsync_delta
	.endif

	; R0 = vsync delta since last frame.
	.if _CHECK_FRAME_DROP
	; This flashes if vsync IRQ has no pending buffer to display.
	ldr r2, last_dropped_frame
	ldr r1, last_last_dropped_frame
	cmp r2, r1
	moveq r4, #0x000000
	movne r4, #0x0000ff
	strne r2, last_last_dropped_frame
	bl palette_set_border
	.endif

	; ========================================================================
	; DRAW
	; ========================================================================

	bl fx_draw_layers

	; show debug
	.if _DEBUG
    ldr r12, screen_addr
    bl debug_plot_vars
	.endif

	; Swap screens!
	bl mark_write_bank_as_pending_display

	; repeat!
	b main_loop

exit:
	; Disable music
	mov r0, #0
	swi QTM_Clear

	; Remove our IRQ handler
	bl uninstall_irq_handler

	; Disable key press event
	mov r0, #OSByte_EventDisable
	mov r1, #Event_KeyPressed
	swi OS_Byte

	; Release our event handler
	mov r0, #EventV
	adr r1, event_handler
	mov r2, #0
	swi OS_Release

	; Release our error handler
	mov r0, #ErrorV
	adr r1, error_handler
	mov r2, #0
	swi OS_Release

	; Display whichever bank we've just written to
	mov r0, #OSByte_WriteDisplayBank
	ldr r1, write_bank
	swi OS_Byte
	; and write to it
	mov r0, #OSByte_WriteVDUBank
	ldr r1, write_bank
	swi OS_Byte

	; Flush keyboard buffer.
	mov r0, #15
	mov r1, #1
	swi OS_Byte

	SWI OS_Exit

; ============================================================================
; Debug helpers.
; ============================================================================

.if _DEBUG
keyboard_prev_mask:
    .long 0

debug_tick:
	str lr, [sp, #-4]!

    ldr r0, keyboard_pressed_mask
	ldr r2, keyboard_prev_mask
	mvn r2, r2				; ~old
	and r2, r0, r2			; new & ~old		; diff bits
	str r0, keyboard_prev_mask
	and r4, r2, r0			; diff bits & key down bits	

    tst r4, #1<<KeyBit_Space
    beq .1

	; Toggle play/pause.
	ldrb r0, debug_play_pause
	eor r0, r0, #1
	strb r0, debug_play_pause

    cmp r0, #0
    swieq QTM_Pause			    ; pause
    swine QTM_Start             ; play


    ; TODO: Stop/start script.

.1:
	mov r0, #0
	strb r0, debug_play_step

    tst r4, #1<<KeyBit_S
    beq .2

	; Step frame (without repeat).
    strb r4, debug_play_step

.2:
    tst r4, #1<<KeyBit_D
    beq .3

	; Toggle debug info.
	ldrb r0, debug_show_info
	eor r0, r0, #1
	strb r0, debug_show_info

.3:
    tst r4, #1<<KeyBit_R
    beq .4

	; Toggle rasters
	ldrb r0, debug_show_rasters
	eor r0, r0, #1
	strb r0, debug_show_rasters

.4:
    tst r4, #1<<KeyBit_A
    beq .5

    ; Start sequence again.
    mov r1, #0
	swi QTM_Pos

    ; TODO: Start script again.

.5:
    tst r4, #1<<KeyBit_ArrowRight
    beq .6

    ; Skip to next pattern.
    mov r0, #-1
    mov r1, #-1
    swi QTM_Pos         ; read position.

    add r0, r0, #1

    ; TODO: Update frame counter to match.

    mov r1, #0
    swi QTM_Pos         ; set position.

.6:
    tst r4, #1<<KeyBit_C
    beq .7

    ; Toggle palette.
    ldr r2, palette_p
    adr r3, palette_red_cyan
    cmp r2, r3
    adreq r2, palette_red_blue
    movne r2, r3
    str r2, palette_p
    bl palette_set_block

.7:
    mov r0, #-1

    tst r4, #1<<KeyBit_0
    movne r0, #0
    tst r4, #1<<KeyBit_1
    movne r0, #1
    tst r4, #1<<KeyBit_2
    movne r0, #2
    tst r4, #1<<KeyBit_3
    movne r0, #3
    tst r4, #1<<KeyBit_4
    movne r0, #4
    tst r4, #1<<KeyBit_5
    movne r0, #5
    tst r4, #1<<KeyBit_6
    movne r0, #6
    tst r4, #1<<KeyBit_7
    movne r0, #7
    tst r4, #1<<KeyBit_8
    movne r0, #8
    tst r4, #1<<KeyBit_9
    movne r0, #9

    cmp r0, #-1
    blne set_eye_distance

.8:
    ldr pc, [sp], #4
.endif

; ============================================================================
; System stuff.
; ============================================================================

error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.p2align 2
	.long 0

get_screen_addr:
	str lr, [sp, #-4]!
	adrl r0, screen_addr_input
	adrl r1, screen_addr
	swi OS_ReadVduVariables
	ldr pc, [sp], #4
	
screen_addr_input:
	.long VD_ScreenStart, -1

displayed_bank:
	.long 0				; VIDC sreen bank being displayed

write_bank:
	.long 0				; VIDC screen bank being written to

pending_bank:
	.long 0				; VIDC screen to be displayed next

vsync_count:
	.long 0				; current vsync count from start of exe.

.if _DEBUG || _CHECK_FRAME_DROP
last_vsync:
	.long 0

vsync_delta:
	.long 0
.endif

.if _CHECK_FRAME_DROP
last_dropped_frame:
	.long 0

last_last_dropped_frame:
	.long 0
.endif

keyboard_pressed_mask:
	.long 0

; R0=event number
event_handler:
	cmp r0, #Event_KeyPressed
	movne pc, lr

	; R1=0 key up or 1 key down
	; R2=internal key number (RMKey_*)

	str r0, [sp, #-4]!

	ldr r0, keyboard_pressed_mask
	cmp r1, #0
	beq .2

	; Key down
	cmp r2, #RMKey_Space
	orreq r0, r0, #1<<KeyBit_Space
	cmp r2, #RMKey_A
	orreq r0, r0, #1<<KeyBit_A
	cmp r2, #RMKey_S
	orreq r0, r0, #1<<KeyBit_S
	cmp r2, #RMKey_D
	orreq r0, r0, #1<<KeyBit_D
	cmp r2, #RMKey_R
	orreq r0, r0, #1<<KeyBit_R
	cmp r2, #RMKey_ArrowRight
	orreq r0, r0, #1<<KeyBit_ArrowRight
	cmp r2, #RMKey_C
	orreq r0, r0, #1<<KeyBit_C
	cmp r2, #RMKey_0
	orreq r0, r0, #1<<KeyBit_0
	cmp r2, #RMKey_1
	orreq r0, r0, #1<<KeyBit_1
	cmp r2, #RMKey_2
	orreq r0, r0, #1<<KeyBit_2
	cmp r2, #RMKey_3
	orreq r0, r0, #1<<KeyBit_3
	cmp r2, #RMKey_4
	orreq r0, r0, #1<<KeyBit_4
	cmp r2, #RMKey_5
	orreq r0, r0, #1<<KeyBit_5
	cmp r2, #RMKey_6
	orreq r0, r0, #1<<KeyBit_6
	cmp r2, #RMKey_7
	orreq r0, r0, #1<<KeyBit_7
	cmp r2, #RMKey_8
	orreq r0, r0, #1<<KeyBit_8
	cmp r2, #RMKey_9
	orreq r0, r0, #1<<KeyBit_9
	b .3

.2:
	; Key up
	cmp r2, #RMKey_Space
	biceq r0, r0, #1<<KeyBit_Space
	cmp r2, #RMKey_A
	biceq r0, r0, #1<<KeyBit_A
	cmp r2, #RMKey_S
	biceq r0, r0, #1<<KeyBit_S
	cmp r2, #RMKey_D
	biceq r0, r0, #1<<KeyBit_D
	cmp r2, #RMKey_R
	biceq r0, r0, #1<<KeyBit_R
	cmp r2, #RMKey_ArrowRight
	biceq r0, r0, #1<<KeyBit_ArrowRight
	cmp r2, #RMKey_C
	biceq r0, r0, #1<<KeyBit_C
	cmp r2, #RMKey_0
	biceq r0, r0, #1<<KeyBit_0
	cmp r2, #RMKey_1
	biceq r0, r0, #1<<KeyBit_1
	cmp r2, #RMKey_2
	biceq r0, r0, #1<<KeyBit_2
	cmp r2, #RMKey_3
	biceq r0, r0, #1<<KeyBit_3
	cmp r2, #RMKey_4
	biceq r0, r0, #1<<KeyBit_4
	cmp r2, #RMKey_5
	biceq r0, r0, #1<<KeyBit_5
	cmp r2, #RMKey_6
	biceq r0, r0, #1<<KeyBit_6
	cmp r2, #RMKey_7
	biceq r0, r0, #1<<KeyBit_7
	cmp r2, #RMKey_8
	biceq r0, r0, #1<<KeyBit_8
	cmp r2, #RMKey_9
	biceq r0, r0, #1<<KeyBit_9

.3:
	str r0, keyboard_pressed_mask
	ldr r0, [sp], #4
	mov pc, lr


mark_write_bank_as_pending_display:
	; Mark write bank as pending display.
	ldr r1, write_bank

	; What happens if there is already a pending bank?
	; At the moment we block but could also overwrite
	; the pending buffer with the newer one to catch up.
	; TODO: A proper fifo queue for display buffers.
	.1:
	ldr r0, pending_bank
	cmp r0, #0
	bne .1
	str r1, pending_bank

	; Show panding bank at next vsync.
	MOV r0, #OSByte_WriteDisplayBank
	swi OS_Byte
	mov pc, lr

get_next_bank_for_writing:
	; Increment to next bank for writing
	ldr r1, write_bank
	add r1, r1, #1
	cmp r1, #Screen_Banks
	movgt r1, #1

	; Block here if trying to write to displayed bank.
	.1:
	ldr r0, displayed_bank
	cmp r1, r0
	beq .1

	str r1, write_bank

	; Now set the screen bank to write to
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte

	; Back buffer address for writing bank stored at screen_addr
	b get_screen_addr

error_handler:
	STMDB sp!, {r0-r2, lr}

	bl uninstall_irq_handler

	; Release event handler.
	MOV r0, #OSByte_EventDisable
	MOV r1, #Event_KeyPressed
	SWI OS_Byte

	MOV r0, #EventV
	ADR r1, event_handler
	mov r2, #0
	SWI OS_Release

	; Release error handler.
	MOV r0, #ErrorV
	ADR r1, error_handler
	MOV r2, #0
	SWI OS_Release

	; Write & display current screen bank.
	MOV r0, #OSByte_WriteDisplayBank
	LDR r1, write_bank
	SWI OS_Byte

	; Do these help?
	swi QTM_Stop

	LDMIA sp!, {r0-r2, lr}
	MOVS pc, lr

; ============================================================================
; Interrupt handling.
; ============================================================================

oldirqhandler:
	.long 0

oldirqjumper:
	.long 0

vsyncstartdelay:
	.long 127*RasterSplitLine  ;2000000/50.08

install_irq_handler:
	mov r1, #0x18					; IRQ vector.
	
	; Remember previous IRQ branch call.
	ldr r0, [r1]					; old IRQ handler.
	str r0, oldirqjumper

	; Calculate old IRQ hanlder address from branch opcode.
	bic r0, r0, #0xff000000
	mov r0, r0, lsl #2
	add r0, r0, #32
	str r0, oldirqhandler

	; Set Timer 1.
	SWI		OS_EnterOS
	MOV     R12,#0x3200000           ;IOC address

	TEQP    PC,#0b11<<26 | 0b11  ;jam all interrupts!

	LDR     R0,vsyncstartdelay
	STRB    R0,[R12,#0x50]
	MOV     R0,R0,LSR#8
	STRB    R0,[R12,#0x54]           ;prepare timer 1 for waiting until screen start
									;don't start timer1, done on next Vs...
	TEQP    PC,#0
	MOV     R0,R0

	; Install our IRQ handler.
	swi OS_IntOff
	adr r0, irq_handler
	sub r0, r0, #32
	mov r0, r0, lsr #2
	add r0, r0, #0xea000000			; B irq_handler.
	str r0, [r1]
	swi OS_IntOn

	mov pc, lr

uninstall_irq_handler:
	mov r1, #0x18					; IRQ vector.
	
	; Restore previous IRQ branch call.
	ldr r0, oldirqjumper
	str r0, [r1]

	mov pc, lr

irq_handler:
	STMFD   R13!,{R0-R1,R11-R12}
	MOV     R12,#0x3200000           ;IOC address
	LDRB    R0,[R12,#0x14+0]
	TST     R0,#1<<6 | (1<<3)
	BEQ     nottimer1orVs           ;not T1 or Vs, back to RISCOS

	TEQP    PC,#0b11<<26 | 0b11
	MOV     R0,R0

	MOV     R11,#VIDC_Write
	TST     R0,#1<<3
	BNE     vsync                   ;...Vs higher priority than T1

timer1:
	mov r0, #0
	str r0, vsync_bodge

	; WRITE VIDC REGS HERE!

	LDRB    R0,[R12,#0x18]
	BIC     R0,R0,#1<<6
	STRB    R0,[R12,#0x18]           ;stop T1 irq...

exittimer1:
	TEQP    PC,#0b10<<26 | 0b10
	MOV     R0,R0
	LDMFD   R13!,{R0-R1,R11-R12}
	SUBS    PC,R14,#4

vsync:
	ldr r0, vsync_bodge
	cmp r0, #0
	beq .3
	b exitVs
.3:
	mov r0, #1
	str r0, vsync_bodge

	; WRITE VIDC REGS HERE!

	STRB    R0,[R12,#0x58]           ;T1 GO (latch already set up)
	LDRB    R0,[R12,#0x18]
	ORR     R0,R0,#1<<6
	STRB    R0,[R12,#0x18]           ;enable T1 irq...
	MOV     R0,#1<<6
	STRB    R0,[R12,#0x14]           ;clear any pending T1 irq

	; Update the vsync counter
	LDR r0, vsync_count
	ADD r0, r0, #1
	STR r0, vsync_count

	; Pending bank will now be displayed.
	ldr r1, pending_bank
	cmp r1, #0
	.if _CHECK_FRAME_DROP
	streq r0, last_dropped_frame
	.endif
	beq exitVs

	str r1, displayed_bank

	; Clear pending bank.
	mov r0, #0
	str r0, pending_bank

exitVs:
	TEQP    PC,#0b10<<26 | 0b10
	MOV     R0,R0

nottimer1orVs:
	LDMFD   R13!,{R0-R1,R11-R12}
	ldr pc, oldirqhandler

vsync_bodge:
	.long 0

; ============================================================================
; Additional code modules
; ============================================================================

rnd_seed:
    .long 0x87654321

palette_p:
    .long palette_red_cyan

screen_addr:
	.long 0					; ptr to the current VIDC screen bank being written to.

.if _DEBUG
debug_play_pause:
	.byte _DEBUG_DEFAULT_PLAY_PAUSE

debug_play_step:
	.byte 0

debug_show_info:
	.byte _DEBUG_DEFAULT_SHOW_INFO

debug_show_rasters:
	.byte _DEBUG_DEFAULT_SHOW_RASTERS

.p2align 2
.endif

.include "lib/debug.asm"

.include "src/fx.asm"
.include "src/script.asm"
.include "src/3d-scene.asm"

.include "lib/palette.asm"
.include "lib/mode9-screen.asm"
.include "lib/line.asm"
.include "lib/lib_code.asm"

; ============================================================================
; Data Segment
; ============================================================================

; TODO: Hot-reload this one day?
.include "src/sequence.asm"

vdu_screen_disable_cursor:
.byte 22, Vdu_Mode, 23,1,0,0,0,0,0,0,0,0
.p2align 2

music_table:
	.long changing_waves_mod_no_adr		; 14

; For anaglpyh want CRcr
palette_red_cyan:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00000077                    ; 01 = 0001 = red 1
    .long 0x00777700                    ; 02 = 0010 = cyan 1
    .long 0x00777777                    ; 03 = 0011 = white 1
    .long 0x00000099                    ; 04 = 0100 = red 2
    .long 0x000000bb                    ; 05 = 0101 = red 3
    .long 0x000000dd                    ; 06 = 0110 = red 4
    .long 0x000000ff                    ; 07 = 0111 = red 5
    .long 0x00999900                    ; 08 = 1000 = cyan 2
    .long 0x00bbbb00                    ; 09 = 1001 = cyan 3
    .long 0x00dddd00                    ; 10 = 1010 = cyan 4
    .long 0x00ffff00                    ; 11 = 1011 = cyan 5
    .long 0x00999999                    ; 12 = 1100 = white 2
    .long 0x00bbbbbb                    ; 13 = 1101 = white 3
    .long 0x00dddddd                    ; 14 = 1110 = white 4
    .long 0x00ffffff                    ; 15 = 1111 = white 5

palette_red_blue:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00000077                    ; 01 = 0001 = red 1
    .long 0x00770000                    ; 02 = 0010 = cyan 1
    .long 0x00770077                    ; 03 = 0011 = white 1
    .long 0x00000099                    ; 04 = 0100 = red 2
    .long 0x000000bb                    ; 05 = 0101 = red 3
    .long 0x000000dd                    ; 06 = 0110 = red 4
    .long 0x000000ff                    ; 07 = 0111 = red 5
    .long 0x00990000                    ; 08 = 1000 = cyan 2
    .long 0x00bb0000                    ; 09 = 1001 = cyan 3
    .long 0x00dd0000                    ; 10 = 1010 = cyan 4
    .long 0x00ff0000                    ; 11 = 1011 = cyan 5
    .long 0x00990099                    ; 12 = 1100 = white 2
    .long 0x00bb00bb                    ; 13 = 1101 = white 3
    .long 0x00dd00dd                    ; 14 = 1110 = white 4
    .long 0x00ff00ff                    ; 15 = 1111 = white 5

; ============================================================================
; DATA Segment
; ============================================================================

.include "src/data.asm"

; ============================================================================
; BSS Segment
; ============================================================================

.include "src/bss.asm"
