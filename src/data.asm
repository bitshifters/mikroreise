; ============================================================================
; DATA.
; ============================================================================

.data   ; TODO: Do we need an rodata segment?

.p2align 6

; ============================================================================

.include "lib/lib_data.asm"

; ============================================================================

.if 0
.p2align 2
logo_data_no_adr:
.incbin "build/logo.bin"

.p2align 2
logo_mask_no_adr:
.incbin "build/logo.bin.mask"
.endif

; ============================================================================

.if 0
.p2align 2
scroller_font_data_no_adr:
.incbin "build/big-font.bin"
.endif

; ============================================================================

.p2align 2
changing_waves_mod_no_adr:
.incbin "build/three-dee.mod"

; ============================================================================

.if 0
.p2align 2
scroller_text_string_no_adr:
; Add 20 blank chars so that scroller begins on RHS of the screen, as per Amiga.
.byte "                    "
.include "src/scrolltxt-final.asm"
scroller_text_string_end_no_adr:
.p2align 2
.endif

; ============================================================================

.if 1
.p2align 6
dots_y_table_1_no_adr:
.incbin "data/dots_y_table_1.bin"
dots_y_table_1_end_no_adr:
.incbin "data/dots_y_table_1.bin"

dots_y_table_2_no_adr:
.incbin "data/dots_y_table_2.bin"
dots_y_table_2_end_no_adr:
.incbin "data/dots_y_table_2.bin"
.endif

; ============================================================================

.p2align 6
dot_tunnel_offset_x_no_adr:
    .incbin "data\dot_tunnel_x_offset.bin"

dot_tunnel_offset_y_no_adr:
    .incbin "data\dot_tunnel_y_offset.bin"

dot_tunnel_x_no_adr:
    .incbin "data\dot_tunnel_x.bin"

dot_tunnel_y_no_adr:
    .incbin "data\dot_tunnel_y.bin"

; ============================================================================

hammer_screen_no_adr:
    .incbin "build/hammer.bin"

hammer_pal_no_adr:
    .incbin "build/hammer.bin.pal"

.if 0
cactus_screen_no_adr:
    .incbin "build/cactus.bin"

cactus_pal_no_adr:
    .incbin "build/cactus.bin.pal"

house_screen_no_adr:
    .incbin "build/house.bin"

house_pal_no_adr:
    .incbin "build/house.bin.pal"

persepolis_screen_no_adr:
    .incbin "build/persepolis.bin"

persepolis_pal_no_adr:
    .incbin "build/persepolis.bin.pal"
.endif

; ============================================================================

.include "src/3d-model-data.asm"

; ============================================================================

.p2align 6
.rodata
seq_main_program:
.if _DO_SEQUENCE
.include "src/sequence-data.asm"
.else
.long 0         ; end sequence.
.endif
.p2align 14     ; 16K
