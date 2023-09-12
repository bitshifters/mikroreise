; ============================================================================
; The actual sequence for the demo.
; ============================================================================

sequence_program_p:
    .long seq_main_program

sequence_init:
    str lr, [sp, #-4]!
    bl script_init

    .if _DEBUG
	; Load seq file.
	mov r0, #0xff
    ldr r2, sequence_program_p
	adr r1, filename
    mov r3, #0
	swi OS_File
    .endif

	ldr r0, sequence_program_p
	bl script_add_program
    ldr pc, [sp], #4

.if _DEBUG
filename:
	.byte "<Demo$Dir>.Seq",0
	.p2align 2
.endif
