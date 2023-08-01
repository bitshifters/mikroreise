; ============================================================================
; Library module data tables.
; ============================================================================

.p2align 6

; ============================================================================

.if LibConfig_IncludeSine
sinus_table_no_adr:
	.incbin "data/sine_8192.bin"
.endif

; ============================================================================

.if LibConfig_IncludeSqrt
sqrt_table_no_adr:
	.incbin "data/sqrt_1024.bin"

rsqrt_table_no_adr:
	.incbin "data/rsqrt_1024.bin"
.endif

; ============================================================================

.if LibConfig_IncludeCircles
.include "lib/circledat.asm"
.endif

; ============================================================================
