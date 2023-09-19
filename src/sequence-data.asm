; ============================================================================
; The actual sequence for the demo.
; ============================================================================

.equ PatternLength_Secs, 4.4444

.macro on_pattern pattern_no, do_thing
    fork_and_wait_secs PatternLength_Secs*\pattern_no, \do_thing
.endm

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 init_3d_scene
    call_0 starfield_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                   screen_cls

    ; Static screen to begin.
    call_3 fx_set_layer_fns, 1, static_set_palette,  static_copy_screen
    write_addr static_palette_p, bs_logo_pal_no_adr
    write_addr static_screen_p, bs_logo_screen_no_adr

    ; This macro has to be front loaded at time 0.
    on_pattern 2, seq_do_starfield
    on_pattern 4, seq_do_dot_tunnel_1
    on_pattern 6, seq_do_dot_tunnel_1   ; number 2?
    on_pattern 8, seq_do_floating_cube
    on_pattern 10, seq_do_square_twist
    on_pattern 12, seq_do_solid_beat_cube
    on_pattern 14, seq_do_wire_beat_cube
    on_pattern 16, seq_do_sine_dots_1
    on_pattern 20, seq_do_floating_circles
    on_pattern 24, seq_do_starfield
    on_pattern 26, seq_do_sine_dots_1 ; variation 2!

    ; TODO: Fix palette change glitch.
    wait_secs PatternLength_Secs*2
    call_0 set_palette_for_3d_scene

    ; THE END.
    end_script

;    write_addr object_rot_speed+4, MATHS_CONST_1
;    write_addr object_rot_speed+8, MATHS_CONST_1
;    write_addr object_dir_z, MATHS_CONST_1
;    wait_secs PatternLength_Secs

; ============================================================================

seq_do_sine_dots_1:
    write_addr dots_visible, 0
    call_3 fx_set_layer_fns, 1, dots_tick,           dots_draw_all
    end_script

seq_do_starfield:
    call_3 fx_set_layer_fns, 1, starfield_update,    starfield_draw_anaglyph
    end_script

seq_do_dot_tunnel_1:
    call_3 fx_set_layer_fns, 1, dot_tunnel_update,   dot_tunnel_draw_anaglyph_spiral
    end_script

seq_do_square_twist:
    call_3 fx_set_layer_fns, 1, scene2d_update,      scene2d_draw_anaglyph
    end_script

seq_do_solid_beat_cube:
    gosub seq_set_cube_model
    write_addr object_pos+8, MATHS_CONST_1*36      ; object_pos_z = 16.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_solid
    end_script

seq_do_wire_beat_cube:
    gosub seq_set_cube_model
    write_addr object_pos+8, MATHS_CONST_1*36      ; object_pos_z = 16.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_cobra:
    gosub seq_set_cobra_model
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_floating_cube:
    gosub seq_set_cube_model
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_floating_circles:
    gosub seq_set_cube_model
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_circles
    end_script


; ============================================================================

seq_set_cube_model:
    write_addr object_scale, MATHS_CONST_1
    write_addr object_num_verts, Model_Cube_Num_Verts
    write_addr object_num_faces, Model_Cube_Num_Faces
    write_addr object_verts_p, model_cube_verts
    write_addr object_face_indices_p, model_cube_face_indices
    write_addr object_edge_list_per_face_p, model_cube_edges_per_face
    write_addr object_edge_indices_p, model_cube_edge_indices
    end_script

seq_set_cobra_model:
    write_addr object_scale, MATHS_CONST_1*1.5
    write_addr object_num_verts, Model_Cobra_Num_Verts
    write_addr object_num_faces, Model_Cobra_Num_Faces
    write_addr object_verts_p, model_cobra_verts
    write_addr object_face_indices_p, model_cobra_face_indices
    write_addr object_edge_list_per_face_p, model_cobra_edges_per_face
    write_addr object_edge_indices_p, model_cobra_edge_indices
    end_script

; ============================================================================
