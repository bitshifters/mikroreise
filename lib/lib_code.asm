; ============================================================================
; Library code routines.
; ============================================================================

.include "lib/maths.h.asm"

; ============================================================================
; MACROS
; ============================================================================

; NOTE: This macro only works if rDst==rBase!!!
; TODO: Proper MLA_BY_CONST rDst, rBase, const
.macro CALC_SCANLINE_ADDR rDst, rBase, rY
.set val, Screen_Stride
.if val&256
    add \rDst, \rBase, \rY, lsl #8
    .set val, val&~256
.endif
.if val&128
    add \rDst, \rBase, \rY, lsl #7
    .set val, val&~128
.endif
.if val&64
    add \rDst, \rBase, \rY, lsl #6
    .set val, val&~64
.endif
.if val&32
    add \rDst, \rBase, \rY, lsl #5
    .set val, val&~32
.endif
.if val&16
    add \rDst, \rBase, \rY, lsl #4
    .set val, val&~16
.endif
.if val&8
    add \rDst, \rBase, \rY, lsl #3
    .set val, val&~8
.endif
.if val&4
    add \rDst, \rBase, \rY, lsl #2
    .set val, val&~4
.endif
.if val&2
    add \rDst, \rBase, \rY, lsl #1
    .set val, val&~2
.endif
.if val&1
    add \rDst, \rBase, \rY
    .set val, val&~1
.endif
.endm

; ============================================================================

lib_init:
    str lr, [sp, #-4]!
    .if LibSine_MakeSinusTable
    bl MakeSinus
    .endif
    .if LibDivide_UseReciprocalTable
    bl MakeReciprocal
    .endif
    .if LibConfig_IncludeCircles
    bl ClearCircleBuf
    .endif
    .if LibConfig_IncludeSpanGen
    bl gen_code
    .endif
    ; Keep this last so R12 returns top of RAM.
    ldr pc, [sp], #4

; ============================================================================

; TODO: Proper debug library with fast plot to screen.
; TODO: Extend Arculator to do fast debug logging to host file.

.if _DEBUG
; R0=fp value.
debug_write_fp:
    stmfd sp!, {r1, r2}
	adr r1, debug_string
	mov r2, #16
	swi OS_ConvertHex8
	adr r0, debug_string
	swi OS_WriteO
    mov r0, #32
    swi OS_WriteC
    ldmfd sp!, {r1, r2}
    mov pc, lr

.ifndef debug_string
debug_string:
    .skip 16
.endif
.endif

; ============================================================================

.if LibConfig_IncludeSine
.include "lib/sine.asm"
.endif
.if LibConfig_IncludeVector
.include "lib/vector.asm"
.endif
.if LibConfig_IncludeMatrix
.include "lib/matrix.asm"
.endif
.if LibConfig_IncludeDivide
.include "lib/divide.asm"
.endif
.if LibConfig_IncludeLine
.include "lib/line.asm"
.endif
.if LibConfig_IncludePolygon
.include "lib/polygon.asm"
.endif
.if LibConfig_IncludeTriangle
.include "lib/triangle.asm"
.endif
.if LibConfig_IncludeSqrt
.include "lib/sqrt.asm"
.endif
.if LibConfig_IncludeCircles
.include "lib/circles.asm"
.endif
.if LibConfig_IncludeSpanGen
.if Screen_Mode==0
.include "lib/mode0.asm"
.endif
.if Screen_Mode==13 || Screen_Mode==12
.include "lib/mode13.asm"
.endif
.if Screen_Mode==9
.include "lib/span_gen.asm"
.endif
.endif

; ============================================================================
