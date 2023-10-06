; ============================================================================
; BSS.
; ============================================================================

.bss

.p2align 6

; ============================================================================

stack_no_adr:
    .skip 1024
stack_base_no_adr:

; ============================================================================

.if 0
scroller_font_data_shifted_no_adr:
	.skip Scroller_Max_Glyphs * Scroller_Glyph_Height * 12 * 8
.endif

; ============================================================================

.if 0
logo_data_shifted_no_adr:
	.skip Logo_Bytes * 7

logo_mask_shifted_no_adr:
	.skip Logo_Bytes * 7
.endif

; ============================================================================

starfield_x_no_adr:
    .skip Starfield_Total * 4

starfield_y_no_adr:
    .skip Starfield_Total * 4

; ============================================================================

transformed_verts_no_adr:
    .skip OBJ_MAX_VERTS * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

;transformed_normals:       ; this is dynamic depending on num_verts.
    .skip OBJ_MAX_FACES * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

projected_verts_no_adr:
    .skip OBJ_MAX_VERTS * VECTOR2_SIZE

; ============================================================================

; All objects transformed to world space.
scene2d_object_buffer_no_adr:
    .skip Scene2D_ObjectBuffer_Size

scene2d_verts_buffer_no_adr:
    .skip Scene2D_MaxVerts * VECTOR2_SIZE

; ============================================================================

.include "lib/lib_bss.asm"

; ============================================================================
