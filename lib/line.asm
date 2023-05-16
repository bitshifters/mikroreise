; ============================================================================
; Line drawing routines.
; ============================================================================

; Plot a batch of lines.
; Parameters:
;  R0=number of lines
;  R1=screen addr
;  R2=ptr to array containining x1,y1,x2,y2
;  [Assumes colour index is just incremented.]
mode12_drawline_batch:
	str lr, [sp, #-4]!			; push lr on stack

    mov r12, r1

    mov r6, r2
    mov r5, r0
    mov r4, #0
.1:
    ldmia r6!, {r0-r3}

    stmfd sp!, {r4-r6}
    ;bl mode9_drawline
    bl mode12_drawline
    ldmfd sp!, {r4-r6}

    add r4, r4, #1
    and r4, r4, #15
    subs r5, r5, #1
    bne .1

    ldr pc, [sp], #4

; R0=startx, R1=starty, R2=endx, R3=endy, R4=colour, R12=screen_addr
; Trashes r5-r11
mode9_drawline:
	str lr, [sp, #-4]!			; push lr on stack

	subs r5, r2, r0				; r5 = dx = endx - startx
	rsblt r5, r5, #0			; r5 = abs(dx)

	cmp r0,r2					; startx < endx?
	movlt r7, #1				; r7 = sx = 1
	movge r7, #-1				; r7 = sx = -1

	subs r6, r3, r1				; r6 = dy = endy - starty
	rsblt r6, r6, #0			; r6 = abs(dy)
	rsb r6, r6, #0				; r6 = -abs(dy)

	cmp r1, r3					; starty < endy?
	movlt r8, #1				; r8 = sy = 1
	movge r8, #-1				; r8 = sy = -1

	add r9, r5, r6				; r9 = dx + dy = err

    ; TODO: Replace y and sy with ptr_y and stride_y.

.1:
	cmp r0, r2					; x0 == x1?
	cmpeq r1, r3				; y0 == y1?
	ldreq pc, [sp], #4			; rts

	; there will be faster line plot algorithms by keeping track of
	; screen pointer then flushing a byte or word when moving to next row
	; ptr = screen_addr + starty * screen_stride + startx DIV 2
	add r10, r12, r1, lsl #7	; r10 = screen_addr + starty * 128
	add r10, r10, r1, lsl #5	; r10 += starty * 32 = starty * 160

	ldrb r11, [r10, r0, lsr #1]	; load screen byte

	tst r0, #1					; odd or even pixel?
	andeq r11, r11, #0xF0		; mask out left hand pixel
	orreq r11, r11, r4			; mask in colour as left hand pixel

	andne r11, r11, #0x0F		; mask out right hand pixel
	orrne r11, r11, r4, lsl #4	; mask in colour as right hand pixel

	strb r11, [r10, r0, lsr #1]	; store screen byte

	mov r10, r9, lsl #1			; r10 = err * 2
	cmp r10, r6					; e2 >= dy?
	addge r9, r9, r6			; err += dy
	addge r0, r0, r7			; x0 += sx

	cmp r10, r5					; e2 <= dx?
	addle r9, r9, r5			; err += dx
	addle r1, r1, r8			; y0 += sy

	b .1

; R0=x, R1=y, R4=colour, R12=screen_addr, trashes r10, r11
mode9_plot_pixel:
	; ptr = screen_addr + starty * screen_stride + startx DIV 2
	add r10, r12, r1, lsl #7	; r10 = screen_addr + starty * 128
	add r10, r10, r1, lsl #5	; r10 += starty * 32 = starty * 160
	add r10, r10, r0, lsr #1	; r10 += startx DIV 2

	ldrb r11, [r10]				; load screen byte

	tst r0, #1					; odd or even pixel?
	andeq r11, r11, #0xF0		; mask out left hand pixel
	orreq r11, r11, r4			; mask in colour as left hand pixel

	andne r11, r11, #0x0F		; mask out right hand pixel
	orrne r11, r11, r4, lsl #4	; mask in colour as right hand pixel

	strb r11, [r10]				; store screen byte
	mov pc, lr

; R0=startx, R1=starty, R2=endx, R3=endy, R4=colour, R12=screen_addr
; Trashes r5-r10
mode12_drawline:
	orr r4, r4, r4, lsl #4      ; make byte

	subs r5, r2, r0				; r5 = dx = endx - startx
	orrs r7, r5, #1<<30			; int sx = dx > 0 ? 1 : -1;
	rsbmi r5, r5, #0			; r5 = abs(dx)

	mov r8, #320                ; r8 = sy = +stride
	subs r6, r3, r1				; r6 = dy = endy - starty
	rsbpl r6, r6, #0			; r6 = -abs(dy)
	rsbmi r8, r8, #0            ; r8 = sy = -stride

	add r9, r5, r6				; r9 = err = dx + dy

	add r10, r12, r1, lsl #8	; 
	add r1, r10, r1, lsl #6	    ; replace current_y with current_y_ptr

	add r10, r12, r3, lsl #8	; 
	add r3, r10, r3, lsl #6	    ; replace endy with end_y_ptr

    ; ~13c setup per line.

    ; R0=current_x
    ; R1=current_y_ptr
    ; R2=end_x
    ; R3=end_y_ptr
    ; R4=colour byte
    ; R5=dx
    ; R6=dy
    ; R7=sx
    ; R8=stride_y
    ; R9=err
    ; R10=e2 (temp)
    ; R11=<free>
    ; R12=screen base
    ; R14=scanline ptr
.1:
	cmp r0, r2					; x0 == x1?                 ; 1c
	cmpeq r1, r3				; y0 == y1?                 ; 1c
	moveq pc, lr       			; rts                       ; 1c

	; NOTE: Aligning this write to address xxxxxxx4 has measurable
	;       speed improvements over any other alignment. Worth testing! 
	strb r4, [r1, r0]     	    ; store screen byte         ; 4c

	mov r10, r9, lsl #1			; r10 = err * 2 = e2        ; 1c
	cmp r10, r6					; e2 >= dy?                 ; 1c
	addge r9, r9, r6			; err += dy                 ; 1c
	addge r0, r0, r7, asr #30	; x0 += sx                  ; 1c

	cmp r10, r5					; e2 <= dx?                 ; 1c
	addle r9, r9, r5			; err += dx                 ; 1c
	addle r1, r1, r8			; y0 += stride_y            ; 1c

	b .1                                                    ; 4c
    ; ~18c per pixel?
