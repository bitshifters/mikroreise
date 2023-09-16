; ============================================================================
; The actual sequence for the demo.
; ============================================================================

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 init_3d_scene
    call_0 starfield_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                   screen_cls

.if 0
    call_3 fx_set_layer_fns, 1, static_set_palette,  static_copy_screen
    write_addr static_palette_p, hammer_pal_no_adr
    write_addr static_screen_p, hammer_screen_no_adr
    wait_secs 1.0
.endif
.if 0
    write_addr static_palette_p, cactus_pal_no_adr
    write_addr static_screen_p, cactus_screen_no_adr
    wait_secs 5.0

    write_addr static_palette_p, house_pal_no_adr
    write_addr static_screen_p, house_screen_no_adr
    wait_secs 5.0

    write_addr static_palette_p, persepolis_pal_no_adr
    write_addr static_screen_p, persepolis_screen_no_adr
    wait_secs 5.0
.endif

    call_0 set_palette_for_3d_scene
    fork effect_loop

    ; THE END.
    end_script

effect_loop:

    ;write_addr object_dir_z, 1
    ;write_addr object_pos+8, 0
    ;write_addr object_rot_speed+0, MATHS_CONST_1
    ;write_addr object_rot_speed+4, 0
    ;write_addr object_rot_speed+8, 0

    ; Set Cobra model.
    gosub seq_set_cobra_model
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_wire

    wait_secs 2.0
    write_addr object_rot_speed+4, MATHS_CONST_1

    wait_secs 2.0
    write_addr object_rot_speed+8, MATHS_CONST_1

    wait_secs 5.0
    write_addr object_dir_z, MATHS_CONST_1

    wait_secs 5.0

    call_3 fx_set_layer_fns, 1, scene2d_update,      scene2d_draw_anaglyph
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, dots_tick,           dots_draw_all
    wait_secs 20.0

    call_3 fx_set_layer_fns, 1, starfield_update,    starfield_draw_anaglyph
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, dot_tunnel_update,   dot_tunnel_draw_anaglyph_spiral
    wait_secs 10.0

    ; Set Cube model.
    gosub seq_set_cube_model
    write_addr object_pos+8, 0

    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,        anaglyph_draw_3d_scene_as_circles
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_solid
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_wire
    wait_secs 5.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_solid
    wait_secs 1.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_wire
    wait_secs 0.5
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_solid
    wait_secs 0.2
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_wire

    fork effect_loop
    end_script

    ; TODO: End demo or loop etc.

; ============================================================================
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
    write_addr object_scale, MATHS_CONST_1*1.9
    write_addr object_num_verts, Model_Cobra_Num_Verts
    write_addr object_num_faces, Model_Cobra_Num_Faces
    write_addr object_verts_p, model_cobra_verts
    write_addr object_face_indices_p, model_cobra_face_indices
    write_addr object_edge_list_per_face_p, model_cobra_edges_per_face
    write_addr object_edge_indices_p, model_cobra_edge_indices
    end_script
