; ============================================================================
; Starfield.
; ============================================================================

.equ Starfield_NumVerts, 100

starfield_cam_pos:
    VECTOR3 0.0, 0.0, 0.0

starfield_init:
    adr r9, starfield_verts
    ldr r8, rnd_seed
    mov r7, #1

    mov r10, #Starfield_NumVerts
.1:
    ; Generate 3x random numbers for x,y,z.
    RND r8, r7, r6              ; seed, bit, temp
    bic r0, r8, #0x7f000000     ; cap at +/=256 [s15.16]
    bic r0, r0, #0x00800000

    RND r8, r7, r6              ; seed, bit, temp
    bic r1, r8, #0x7f000000     ; cap at +/=256 [s15.16]
    bic r1, r1, #0x00800000

    RND r8, r7, r6              ; seed, bit, temp
    bic r2, r8, #0x7f000000     ; cap at +/=256 [s15.16]
    bic r2, r2, #0x00800000

    stmia r9!, {r0-r2}

    subs r10, r10, #1
    bne .1

    mov pc, lr

starfield_update:
    ldr r2, starfield_cam_pos+8 ; cam_z
    add r2, r2, #1.0*PRECISION_MULTIPLIER
    cmp r2, #256.0*PRECISION_MULTIPLIER
    movge r2, #-256.0*PRECISION_MULTIPLIER
    str r2, starfield_cam_pos+8 ; cam_z
    mov pc, lr

starfield_colour:
    .long 0

; R4=colour index.
; R12=screen_addr.
starfield_draw:
    str lr, [sp, #-4]!

    mov r4, #0xf
    str r4, starfield_colour

    adr r7, starfield_verts
    mov r11, #Starfield_NumVerts
.1:
    ; Load a star position.
    ldmia r7!, {r3-r5}

    ; Make camera relative.
    adr r2, starfield_cam_pos
    ldmia r2, {r6-r8}

    sub r3, r3, r6
    sub r4, r4, r7
    sub r5, r5, r8

    ; Store temp. (ARGH!)
    adr r2, starfield_temp_vec
    stmia r2, {r3-r5}
    
    ; Project to screen.
    bl project_to_screen

    ldrb r3, Anaglyph_Enable_Skew
    cmp r3, #0
    ldrne r3, starfield_cam_pos+0        ; camera_pos_x
    movne r3, r3, asl #1
    addne r0, r0, r3

    ; R0=screen_x, R1=screen_y [16.16]
    mov r0, r0, asr #16         ; [16.0]
    cmp r0, #0
    blt .2
    cmp r0, #Screen_Width
    bge .2

    mov r1, r1, asr #16         ; [16.0]
    cmp r1, #0
    blt .2
    cmp r1, #Screen_Height
    bge .2

    ; Plot a pixel.
	; ptr = screen_addr + starty * screen_stride + startx DIV 2
	add r10, r12, r1, lsl #7	; r10 = screen_addr + starty * 128
	add r10, r10, r1, lsl #5	; r10 += starty * 32 = starty * 160
	add r10, r10, r0, lsr #1	; r10 += startx DIV 2

	ldrb r9, [r10]				; load screen byte

	tst r0, #1					; odd or even pixel?
	andeq r9, r9, #0xF0		; mask out left hand pixel
	orreq r9, r9, r4			; mask in colour as left hand pixel

	andne r9, r9, #0x0F		; mask out right hand pixel
	orrne r9, r9, r4, lsl #4	; mask in colour as right hand pixel

	strb r9, [r10]				; store screen byte

.2:
    subs r11, r11, #1
    bne .1

    ldr pc, [sp], #4

starfield_temp_vec:
    VECTOR3 0.0, 0.0, 0.0

; ============================================================================

starfield_verts:
    .skip Starfield_NumVerts * VECTOR3_SIZE

starfield_projected:
    .skip Starfield_NumVerts * 2 * 4

; ============================================================================
