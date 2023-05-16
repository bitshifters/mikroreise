; ============================================================================
; Fast MODE 13 span plot routines.
; Code generated at runtime.
; Adapted from code kindly provided by Progen (Sarah Walker).
; TODO: Reduce duplicated code.
; ============================================================================

gen_code_pointers_p:
	.long gen_code_pointers_no_adr

; Registers used during span plotting functions.
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

;        pixel order	byte order in word
;        v				v
; screen=abcd			dcba
; colour=ijkl			lkji

gen_first_word_1:
	LDR r3, [r10]
	AND r3, r3, #0xff			; 000a
	bic r6, r9, #0xff			; lkj0
	ORR r3, r3, r6				; lkja => ajkl
	STR r3, [r10], #4
gen_first_word_2:
	LDR r3, [r10]
	mov r3, r3, lsl #16			; ba00
	mov r3, r3, lsr #16			; 00ba
	mov r6, r9, lsr #16			; 00lk
	ORR r3, r3, r6, lsl #16		; lkba => abkl
	STR r3, [r10], #4
gen_first_word_3:
	LDR r3, [r10]
	bic r3, r3, #0xff000000		; 0cba
	and r6, r9, #0xff000000		; l000
	orr r3, r3, r6				; lcba => abcl
	STR r3, [r10], #4
gen_first_word_over:

gen_first_word_table:
	.long 0
	.long gen_first_word_1
	.long gen_first_word_2
	.long gen_first_word_3
	.long gen_first_word_over

;        pixel order	byte order in word
;        v				v
; screen=abcd			dcba
; colour=ijkl			lkji

; R0=first pixel offset; R1=X end (inclusive)
gen_same_word_0:
	; 							  R1=0		 R1=1	 	R1=2	   R1=3
	; 							  len1       len2    	len3	   len4
	; 					result =  ibcd		 ijcd		ijkd	   ijkl

	add r1, r1, #1
    AND r1, r1, #3				; len=(xend+1-0)&3
	mov r1, r1, lsl #3			; byte shift
	mov r6, #-1					; R1=0		 R1=1		R1=2	   R1=3
	mov r6, r6, lsl r1			; 0xffffff00 0xffff0000 0xff000000 0xffffffff

	LDR r3, [r10]
	and r3, r3, r6				; dcb0       dc00       d000	   dcba
	bic r6, r9, r6				; 000i		 00ji	    0kji	   0000
	ORR r3, r3, r6				; dcbi=>ibcd dcji=>ijcd dkji=>ijkd dcba=>abcd
	STR r3, [r10]

gen_same_word_1:
	; 							  R1=4		 R1=1		R1=2	   R1=3
	; 	  * doesn't make sense	  len4*    	 len1		len2	   len3
	; 					result =  ijkl		 ajcd		ajkd	   ajkl

    AND r1, r1, #3				; len=(xend+1-1)&3
	mov r1, r1, lsl #3			; byte shift
	mov r6, #-1					; R1=0		 R1=1		R1=2	   R1=3
	mov r6, r6, lsl r1			; 0xffffffff 0xffffff00 0xffff0000 0xff000000
	mov r6, r6, ror #24			; 0xffffffff 0xffff00ff 0xff0000ff 0x000000ff ; rol #8

	LDR r3, [r10]
	and r3, r3, r6				; dcba       dc0a       d00a	   000a
	bic r6, r9, r6				; 0000       00j0       0kj0	   lkj0
	orr r3, r3, r6				; dcba=>abcd dcja=>ajcd dkja=>ajkb lkja=>ajkl
	STR r3, [r10]

gen_same_word_2:
	; 							  R1=4		 R1=5		R1=2	   R1=3
	; 	  * doesn't make sense	  len3*    	 len4*    	len1	   len2
	; 					result =  ibkl		 ijkl		abkd	   abkl

	sub r1, r1, #1
    AND r1, r1, #3				; len=(xend+1-2)&3
	mov r1, r1, lsl #3			; byte shift
	mov r6, #-1					; R1=0		 R1=1		R1=2	   R1=3
	mov r6, r6, lsl r1			; 0xff000000 0xffffffff 0xffffff00 0xffff0000 
	mov r6, r6, ror #16			; 0x0000ff00 0xffffffff 0xff00ffff 0x0000ffff ; rol #16

	LDR r3, [r10]
	and r3, r3, r6				; 00b0       dcba       d0ba	   00ba
	bic r6, r9, r6				; lk0i       0000       0k00	   lk00
	orr r3, r3, r6				; lkbi=>ibkl dcba=>abcd dkba=>abkd lkba=>abkl
	STR r3, [r10]

gen_same_word_3:
	; 							  R1=4		 R1=5		R1=6	   R1=3
	; 	  * doesn't make sense	  len2*    	 len3*    	len4*	   len1
	; 					result =  ibcl		 ijcl		ijkl	   abcl

	sub r1, r1, #2
    AND r1, r1, #3				; len=(xend+1-3)&3
	mov r1, r1, lsl #3			; byte shift
	mov r6, #-1					; R1=0		 R1=1		R1=2	   R1=3
	mov r6, r6, lsl r1			; 0xffff0000 0xff000000 0xffffffff 0xffffff00 
	mov r6, r6, ror #8			; 0x00ffff00 0x00ff0000 0xffffffff 0x00ffffff ; rol #24

	LDR r3, [r10]
	and r3, r3, r6				; 0cb0       0c00       dbca	   0cba
	bic r6, r9, r6				; l00i       l0ji       0000	   l000
	orr r3, r3, r6				; lcbi=>ibcl lcji=>ijcl dcba=>abcd lcba=>abcl
	STR r3, [r10]
gen_same_word_over:

gen_same_word_table:
	.long gen_same_word_0
	.long gen_same_word_1
	.long gen_same_word_2
	.long gen_same_word_3
	.long gen_same_word_over

gen_one_word:
	STR r9, [r10], #4
gen_one_word_end:

.if _SPAN_GEN_MULTI_WORD > 1
gen_two_words:
	stmia r10!, {r5, r9}
gen_two_words_end:
.endif

.if _SPAN_GEN_MULTI_WORD > 2
gen_four_words:
	stmia r10!, {r2, r4, r5, r9}
gen_four_words_end:
.endif

;        pixel order	byte order in word
;        v				v
; screen=abcd			dcba
; colour=ijkl			lkji

gen_last_word_0:
	MOV r0, r0
gen_last_word_1:
	strb r9, [r10]				; ibcd
gen_last_word_2:
	LDR r3, [r10]
	MOV r3, r3, LSR #16			; 00dc
	MOV r3, r3, LSL #16			; dc00
	mov r6, r9, lsl #16			; ji00
	ORR r3, r3, r6, LSR #16		; dcji => ijcd
	STR r3, [r10]
gen_last_word_3:
	LDR r3, [r10]
	and r3, r3, #0xff000000		; d000
	bic r6, r9, #0xff000000		; 0kji
	ORR r3, r3, R6				; dkji => ijkd
	STR r3, [r10]
gen_last_word_over:

gen_last_word_table:
	.long gen_last_word_0
	.long gen_last_word_1
	.long gen_last_word_2
	.long gen_last_word_3
	.long gen_last_word_over

gen_end_code:
	mov pc, lr
; Specific to circle plot.
;	ADD r11, r11, #Screen_Stride
;	SUBS r14, r14, #1
gen_end_code_end:
; These branch instructions are patched at copy.
;	BNE circle_loop
;	.long circle_loop
;	B return_from_span_plot
;	.long return_from_span_plot

gen_code_start_p:
	.long gen_code_start_no_adr

gen_code:
	STR lr, [sp, #-4]!

	LDR r11, gen_code_pointers_p
	LDR r12, gen_code_start_p
        MOV r0, #0 ;first pixel offset - 0-3
	MOV r1, #1 ;length - 1-320

gen_code_main_loop:
	CMP r0, #0
	BNE gen_code_dont_print		; TODO: Wut?

gen_code_dont_print:
	ADD r12, r12, #0xc ;Align to 16 byte boundary
	BIC r12, r12, #0xc
	STR r12, [r11], #4

	MOV r5, #0     ;current pixel

	ADD r2, r0, r1
	CMP r2, #4     ;Start and end lie in same word?
	BCC gen_code_same_word

	TST r0, #3
	BEQ gen_code_no_offset

	;Copy code to generate first word
	ADRL r2, gen_first_word_table
	ADD r2, r2, r0, LSL #2
	LDMIA r2, {r2-r3} ;r2-r3 - start and end addresses of code
gen_code_first_word_copy:
	LDR r4, [r2], #4
	STR r4, [r12], #4
	CMP r2, r3
	BNE gen_code_first_word_copy

	RSB r5, r0, #4

gen_code_no_offset:

gen_code_no_offset_loop:
	SUB r2, r1, r5  ;If less than 8 pixels remaining then jump to last word
	CMP r2, #4
	BCC gen_code_last_word

.if _SPAN_GEN_MULTI_WORD > 2
	cmp r2, #16
	blt .1
	; four words = 16 pixels
	adr r3, gen_four_words
	ldr r4, [r3]
	str r4, [r12], #4
	add r5, r5, #16
	B gen_code_no_offset_loop
.1:
.endif
.if _SPAN_GEN_MULTI_WORD > 1
	cmp r2, #8
	blt .2
	; two words = 16 pixels
	adr r3, gen_two_words
	ldr r4, [r3]
	str r4, [r12], #4
	add r5, r5, #8
	B gen_code_no_offset_loop
.2:
.endif

	ADRL r2, gen_one_word
	ADRL r3, gen_one_word_end
gen_code_main_loop_copy:
	LDR r4, [r2], #4
	STR r4, [r12], #4
	CMP r2, r3
	BNE gen_code_main_loop_copy
	ADD r5, r5, #4

	B gen_code_no_offset_loop

gen_code_last_word:
	TST r2, r2
	BEQ gen_code_complete

	;Copy code to generate last word
	ADR r3, gen_last_word_table
	ADD r2, r3, r2, LSL #2
	LDMIA r2, {r2-r3} ;r2-r3 - start and end addresses of code
gen_code_last_word_copy:
	LDR r4, [r2], #4
	STR r4, [r12], #4
	CMP r2, r3
	BNE gen_code_last_word_copy

gen_code_complete:
	;End of code
	ADRL r2, gen_end_code
	ADRL r3, gen_end_code_end
gen_code_end_copy:
	LDR r4, [r2], #4
	STR r4, [r12], #4
	CMP r2, r3
	BNE gen_code_end_copy

.if 0
	; Patch branch instruction with offset.
	LDMIA r2!, {r3-r4}
	AND r3, r3, #0xff000000
	SUB r4, r4, r12
	SUB r4, r4, #8
	MOV r4, r4, LSL #6
	ORR r3, r3, r4, LSR #8
	STR r3, [r12], #4

	; Patch branch instruction with offset.
	LDMIA r2!, {r3-r4}
	AND r3, r3, #0xff000000
	SUB r4, r4, r12
	SUB r4, r4, #8
	MOV r4, r4, LSL #6
	ORR r3, r3, r4, LSR #8
	STR r3, [r12], #4
.endif

	ADD r0, r0, #1
	ANDS r0, r0, #3
	BNE gen_code_main_loop
	ADD r1, r1, #1
	CMP r1, #MAXSPAN
	BLE gen_code_main_loop
	LDR pc, [sp], #4
	; Return R12=RAM top.


gen_code_same_word:
	;Copy code to generate same word
	ADRL r2, gen_same_word_table
	ADD r2, r2, r0, LSL #2
	LDMIA r2, {r2-r3} ;r2-r3 - start and end addresses of code
gen_code_same_word_copy:
	LDR r4, [r2], #4
	STR r4, [r12], #4
	CMP r2, r3
	BNE gen_code_same_word_copy

	B gen_code_complete

; ============================================================================

; R0=colour word.
; R1=screen base addr.
; R2=x start
; R3=x end
; R4=y line
mode13_plot_span:
	mov r9, r0
	mov r5, r0
	mov r11, r1
	mov r6, r2
	mov r1, r3

	sub r1, r1, #1				; omit last pixel.
    subs r3, r1, r6             ; width.
	movmi pc, lr

    str lr, [sp, #-4]!

    ldr r12, gen_code_pointers_p

	add r11, r11, r4, lsl #8
	add r11, r11, r4, lsl #6

    add r10, r11, r6
    bic r10, r10, #3

    and r6, r6, #3				; x start offset [0-3] pixel
    add r6, r6, r3, lsl #2      ; + span length * 4

    adr lr, .2                  ; link address.
    ; MULTI_WORD uses R2, R4, R5 as well as R9.
	.if _SPAN_GEN_MULTI_WORD>2
	mov r2, r9
	mov r4, r9
	.endif
    ldr pc, [r12, r6, lsl #2]   ; jump to plot function.
    ; Uses R1 (Xend in pixels), R3, R6, R9, R10, R11, R12

    .2:
    ldr pc, [sp], #4

; ============================================================================
