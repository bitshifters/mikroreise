; ============================================================================
; Library module config header (include at start).
; ============================================================================

; TODO: Make lib dependencies clear in config somehow.
; TODO: Config should probably be in src not lib folder?
; TODO: Make #define naming conventions be consistent.

.equ _USE_RECIPROCAL_TABLE, 1
.equ _MAKE_SINUS_TABLE, 0       ; TODO: Put back sine table generation!

.equ _INCLUDE_SQRT, 0
.equ _INCLUDE_SPAN_GEN, 1       ; Required for polygon.
