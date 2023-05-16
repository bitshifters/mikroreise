; ============================================================================
; Library module config header (include at start).
; ============================================================================

; TODO: Make lib dependencies clear in config somehow.
; TODO: Config should probably be in src not lib folder?
; TODO: Make #define naming conventions be consistent.
; TODO: Allow configuration of more than one screen mode?
; TODO: Rename maths.asm to lib_code.asm?
; TODO: Rename config.h.asm to lib_config.h.asm?
; TODO: Move MACROs into lib_macros.h.asm?

.equ _USE_RECIPROCAL_TABLE, 1
.equ _MAKE_SINUS_TABLE, 0       ; TODO: Put back sine table generation!

.equ _INCLUDE_SQRT, 0
.equ _INCLUDE_SPAN_GEN, 1       ; Required for polygon & triangle.

.equ _INCLUDE_LINE, 0
.equ _INCLUDE_TRIANGLE, 0

.equ MAXSPAN, Screen_Width
.equ _SPAN_GEN_MULTI_WORD, 2    ; Use 1, 2 or 4 words.

; ============================================================================
; Universal MACROS
; ============================================================================

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
