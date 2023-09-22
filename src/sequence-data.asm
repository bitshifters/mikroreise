; ============================================================================
; The actual sequence for the demo.
; ============================================================================

.equ Fade_Fast, 1
.equ Fade_Med, 2
.equ Fade_Slow, 4
.equ Fade_VerySlow, 8

.macro on_pattern pattern_no, do_thing
    fork_and_wait_secs PatternLength_Secs*\pattern_no, \do_thing
.endm

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 init_3d_scene            ; sets 3D palette.
    call_0 starfield_init
    call_0 scene2d_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                   screen_cls

    ; This macro has to be front loaded at time 0.

    ; 0,1,2,3 = long melody alone                 => slow build up
    on_pattern 0, seq_do_bitshifters_with_fade_out
    on_pattern 1, seq_do_torment_with_fade_out
    on_pattern 2, seq_fade_up_3d_palette_very_slow
    on_pattern 2, seq_do_starfield_with_fade_out

    ; 4,5,4,5 = wobbly bass added                 => some movement added
    on_pattern 4, seq_fade_up_3d_palette_medium
    on_pattern 4, seq_do_dot_tunnel_1
    on_pattern 6, seq_fade_up_3d_palette_medium
    on_pattern 6, seq_do_dot_tunnel_2           ; <= DEMO NAME?
    
    ; 6,7,6,7 = bass kick added, short melody     => we're off!
    on_pattern 8, seq_do_square_twist
    on_pattern 10, seq_do_square_twist_2

    ; 9,8,9,8 = percusion added                   => more energy
    on_pattern 12, seq_do_solid_beat_cube
    on_pattern 14, seq_do_wire_beat_cube

    ; 10,11,12,11 = short melody drops out        => slow down
    on_pattern 16, seq_do_sine_dots_1

    ; 16,17,15,14 = long melody w/ percusion      => high intensity 
    on_pattern 20, seq_do_credits_1                    ; <= GREETS HERE!

    ; 18,19,18,19 = both melodies                 => full intensity
    on_pattern 24, seq_do_floating_circles

    ; 20,21,20,21 = both melodies w/ highlights   => full intensity (show off)
    on_pattern 28, seq_do_credits_2                   ; <= GREETS HERE!

    ; 22,23,24,25 = percusion drops out           => the end
    on_pattern 32, seq_do_sine_dots_2
    on_pattern 36, seq_do_bitshifters_with_fade_out ; <= CREDITS

    ; THE END.
    end_script

; ============================================================================

seq_do_bitshifters_with_fade_out:
    ; Static screen.
    call_3 fx_set_layer_fns, 1, static_set_palette,  static_copy_screen
    write_addr static_palette_p, bs_logo_pal_no_adr
    write_addr static_screen_p, bs_logo_screen_no_adr

    wait PatternLength_Frames-(16*Fade_Med)

    ; Initialise fade out.
    call_3 palette_init_fade_to_black, 0, Fade_Med, bs_logo_pal_no_adr
    call_3 fx_set_layer_fns, 1, palette_update_fade_to_black,  static_copy_screen
    end_script

seq_do_torment_with_fade_out:
    ; Static screen.
    call_3 palette_init_fade_from_black, 0, Fade_Med, tmt_logo_pal_no_adr

    call_3 fx_set_layer_fns, 1, palette_update_fade_from_black,  static_copy_screen
    write_addr static_palette_p, tmt_logo_pal_no_adr
    write_addr static_screen_p, tmt_logo_screen_no_adr

    wait 16*Fade_Med
    call_3 fx_set_layer_fns, 1, static_set_palette,  static_copy_screen

    wait PatternLength_Frames-(2*16*Fade_Med)

    ; Initialise fade out.
    call_3 palette_init_fade_to_black, 0, Fade_Med, tmt_logo_pal_no_adr
    call_3 fx_set_layer_fns, 1, palette_update_fade_to_black,  static_copy_screen
    end_script

seq_fade_up_3d_palette_very_slow:
    ; Initialise fade up.
    call_3 palette_init_fade_from_black, 0, Fade_VerySlow, palette_red_cyan
    call_3 fx_set_layer_fns, 2, palette_update_fade_from_black,  0
    wait 16*Fade_VerySlow
    call_3 fx_set_layer_fns, 2, 0,  0
    end_script

seq_fade_up_3d_palette_medium:
    ; Initialise fade up.
    call_3 palette_init_fade_from_black, 0, Fade_Med, palette_red_cyan
    call_3 fx_set_layer_fns, 2, palette_update_fade_from_black,  0
    wait 16*Fade_Med
    call_3 fx_set_layer_fns, 2, 0,  0
    end_script

seq_do_sine_dots_1:
    call_0 set_palette_for_3d_scene
    write_addr dots_visible, 0
    write_addr dots_y_t, 0
    write_addr dots_y_table_1_p, dots_y_table_1_no_adr
    write_addr dots_y_table_2_p, dots_y_table_2_no_adr
    write_addr dots_code_p, dots_gen_code_a
    call_3 fx_set_layer_fns, 1, dots_tick,           dots_draw_all
    end_script

seq_do_sine_dots_2:
    call_0 set_palette_for_3d_scene
    write_addr dots_visible, 0
    write_addr dots_y_t, Dots_Total/2
    write_addr dots_y_table_1_p, dots_y_table_1_b_no_adr
    write_addr dots_y_table_2_p, dots_y_table_2_b_no_adr
    write_addr dots_code_p, dots_gen_code_b
    call_3 fx_set_layer_fns, 1, dots_tick,           dots_draw_all
    end_script

seq_do_starfield_with_fade_out:
    write_addr starfield_speed, 1
    call_3 fx_set_layer_fns, 1, starfield_update,    starfield_draw_anaglyph

    wait PatternLength_Frames*2-(16*Fade_Med)
    call_3 palette_init_fade_to_black, 0, Fade_Med, palette_red_cyan
    call_3 fx_set_layer_fns, 2, palette_update_fade_to_black,  0
    end_script

seq_do_starfield_fast:
    write_addr starfield_speed, 4
    call_3 fx_set_layer_fns, 1, starfield_update,    starfield_draw_anaglyph
    end_script

seq_do_dot_tunnel_1:
    call_0 dot_tunnel_patch_to_straight
    write_addr dot_tunnel_speed, 1
    call_3 fx_set_layer_fns, 1, dot_tunnel_update,   dot_tunnel_draw_anaglyph_spiral
    end_script

seq_do_dot_tunnel_2:
    call_0 dot_tunnel_patch_to_curved
    write_addr dot_tunnel_speed, 2
    call_3 fx_set_layer_fns, 1, dot_tunnel_update,   dot_tunnel_draw_anaglyph_spiral
    end_script

seq_do_square_twist:
    call_0 set_palette_for_3d_scene
    gosub seq_set_square_tunnel
    call_3 fx_set_layer_fns, 1, scene2d_update,      scene2d_draw_anaglyph
    end_script

seq_do_square_twist_2:
    gosub seq_set_square_tunnel_2
    call_3 fx_set_layer_fns, 1, scene2d_update,      scene2d_draw_anaglyph
    end_script

seq_do_solid_beat_cube:
    call_0 set_palette_for_3d_scene
    gosub seq_set_cube_model
    write_fp object_pos+8, 16.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_solid
    end_script

seq_do_wire_beat_cube:
    call_0 set_palette_for_3d_scene
    gosub seq_set_cube_model
    write_fp object_pos+8, 16.0
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vu_bars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_cobra:
    gosub seq_set_cobra_model
    write_addr object_rot_speed+0, MATHS_CONST_HALF
    write_addr object_rot_speed+4, MATHS_CONST_HALF
    write_addr object_rot_speed+8, MATHS_CONST_HALF
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_floating_cube:
    call_0 set_palette_for_3d_scene

    gosub seq_set_cube_model
    write_addr object_dir_z, MATHS_CONST_1*2
    write_addr object_rot_speed+0, MATHS_CONST_HALF
    write_addr object_rot_speed+4, MATHS_CONST_HALF
    write_addr object_rot_speed+8, MATHS_CONST_HALF
    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_wire
    end_script

seq_do_floating_circles:
    call_0 set_palette_for_3d_scene
    gosub seq_set_circle_model
    write_addr object_dir_z, 0
    write_addr object_pos+8, 32
    write_addr object_rot_speed+0, MATHS_CONST_1*2
    write_addr object_rot_speed+4, -MATHS_CONST_1
    write_addr object_rot_speed+8, MATHS_CONST_1*1.5

    call_3 fx_set_layer_fns, 1, update_3d_scene_from_vars,     anaglyph_draw_3d_scene_as_circles
    end_script

seq_do_credits_1:
    call_0 set_palette_for_3d_scene
    call_3 fx_set_layer_fns, 1, update_3d_scene_move_in_z,     anaglyph_draw_3d_scene_as_outline
    call_3 fx_set_layer_fns, 2, update_3d_scene_from_vars,     0

    gosub seq_set_2d_model
    write_fp object_dir_min_z, -50.0
    write_fp object_dir_max_z, 256.0

    ; 1. Rab
    write_addr object_num_verts, Rab_Num_Verts
    write_addr object_num_edges, Rab_Num_Lines
    write_addr object_verts_p, model_rab_verts
    write_addr object_edge_indices_p, model_rab_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, -0.03, 0.02
    wait 111

    ; 2. Slp
    write_addr object_num_verts, Slp_Num_Verts
    write_addr object_num_edges, Slp_Num_Lines
    write_addr object_verts_p, model_slp_verts
    write_addr object_edge_indices_p, model_slp_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.03, -0.02
    wait 111

    ; 3. Dsr
    write_addr object_num_verts, Dsr_Num_Verts
    write_addr object_num_edges, Dsr_Num_Lines
    write_addr object_verts_p, model_dsr_verts
    write_addr object_edge_indices_p, model_dsr_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.0, 0.1
    wait 111

    ; 4. Lgc
    write_addr object_num_verts, Lgc_Num_Verts
    write_addr object_num_edges, Lgc_Num_Lines
    write_addr object_verts_p, model_lgc_verts
    write_addr object_edge_indices_p, model_lgc_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 20.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.5, 0.0, 0.0
    wait 111

    ; 5. Prx
    write_addr object_num_verts, Prx_Num_Verts
    write_addr object_num_edges, Prx_Num_Lines
    write_addr object_verts_p, model_prx_verts
    write_addr object_edge_indices_p, model_prx_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 148.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.5, 0.0
    wait 111

    ; 6. Rft
    write_addr object_num_verts, Rft_Num_Verts
    write_addr object_num_edges, Rft_Num_Lines
    write_addr object_verts_p, model_rft_verts
    write_addr object_edge_indices_p, model_rft_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.01, 0.01, 0.0
    wait 111

    ; 7. Nva
    write_addr object_num_verts, Nva_Num_Verts
    write_addr object_num_edges, Nva_Num_Lines
    write_addr object_verts_p, model_nva_verts
    write_addr object_edge_indices_p, model_nva_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, -0.02, 0.0, -0.02
    wait 111

    ; 8. Iph
    write_addr object_num_verts, Iph_Num_Verts
    write_addr object_num_edges, Iph_Num_Lines
    write_addr object_verts_p, model_iph_verts
    write_addr object_edge_indices_p, model_iph_edge_indices

    write_fp object_pos+8, 172.0
    write_fp object_dir_z, -2.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, -0.02, 0.0, -0.02
    wait 112

    call_3 fx_set_layer_fns, 2, 0,                             0

    end_script

seq_do_credits_2:
    call_0 set_palette_for_3d_scene
    call_3 fx_set_layer_fns, 1, update_3d_scene_move_in_z,     anaglyph_draw_3d_scene_as_outline
    call_3 fx_set_layer_fns, 2, update_3d_scene_from_vars,     0

    gosub seq_set_2d_model
    write_fp object_dir_min_z, -50.0
    write_fp object_dir_max_z, 256.0

    ; 1. Ate
    write_addr object_num_verts, Ate_Num_Verts
    write_addr object_num_edges, Ate_Num_Lines
    write_addr object_verts_p, model_ate_verts
    write_addr object_edge_indices_p, model_ate_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, -0.03, 0.02
    wait 111

    ; 2. Ymr
    write_addr object_num_verts, Ymr_Num_Verts
    write_addr object_num_edges, Ymr_Num_Lines
    write_addr object_verts_p, model_ymr_verts
    write_addr object_edge_indices_p, model_ymr_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.03, -0.02
    wait 111

    ; 3. Smf
    write_addr object_num_verts, Smf_Num_Verts
    write_addr object_num_edges, Smf_Num_Lines
    write_addr object_verts_p, model_smf_verts
    write_addr object_edge_indices_p, model_smf_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.0, 0.1
    wait 111

    ; 4. Pro
    write_addr object_num_verts, Pro_Num_Verts
    write_addr object_num_edges, Pro_Num_Lines
    write_addr object_verts_p, model_pro_verts
    write_addr object_edge_indices_p, model_pro_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 0.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.5, 0.0, 0.0
    wait 111

    ; 5. Mst
    write_addr object_num_verts, Mst_Num_Verts
    write_addr object_num_edges, Mst_Num_Lines
    write_addr object_verts_p, model_mst_verts
    write_addr object_edge_indices_p, model_mst_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 128.0, 0.0
    write_vec3 object_rot_speed, 0.0, 0.5, 0.0
    wait 111

    ; 6. Hoo
    write_addr object_num_verts, Hoo_Num_Verts
    write_addr object_num_edges, Hoo_Num_Lines
    write_addr object_verts_p, model_hoo_verts
    write_addr object_edge_indices_p, model_hoo_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, 0.01, 0.01, 0.0
    wait 111

    ; 7. Far
    write_addr object_num_verts, Far_Num_Verts
    write_addr object_num_edges, Far_Num_Lines
    write_addr object_verts_p, model_far_verts
    write_addr object_edge_indices_p, model_far_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, -0.02, 0.0, -0.02
    wait 111

    ; 8. Crt
    write_addr object_num_verts, Crt_Num_Verts
    write_addr object_num_edges, Crt_Num_Lines
    write_addr object_verts_p, model_crt_verts
    write_addr object_edge_indices_p, model_crt_edge_indices

    write_fp object_pos+8, -50.0
    write_fp object_dir_z, 1.0
    write_vec3 object_rot, 128.0, 0.0, 0.0
    write_vec3 object_rot_speed, -0.02, 0.0, -0.02
    wait 112

    call_3 fx_set_layer_fns, 2, 0,                             0

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
    write_addr object_colour_p, model_cube_colour_per_face
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

seq_set_circle_model:
    write_addr object_scale, MATHS_CONST_1
    write_addr object_num_verts, Model_Circle_Num_Verts
    write_addr object_num_faces, Model_Circle_Num_Faces
    write_addr object_verts_p, model_circle_verts
    write_addr object_face_indices_p, 0
    write_addr object_edge_list_per_face_p, 0
    write_addr object_edge_indices_p, 0
    end_script

seq_set_2d_model:
    write_fp object_scale, 8.0
    write_addr object_num_faces, 0
    write_addr object_face_indices_p, 0
    write_addr object_edge_list_per_face_p, 0
    end_script

seq_set_square_tunnel:
    write_addr scene2d_object_vert_p, model_square_verts
    write_addr scene2d_object_num_verts, 4
    write_addr scene2d_object_num, 1            ; for ARM2
    write_fp scene2d_object_z_speed, 1.152      ; z-=speed
    write_fp scene2d_object_rot_speed, 0.5      ; brads/frame
    write_fp scene2d_object_twist, 16           ; brads/square
    write_fp scene2d_object_gap, 32             ; z-=gap
    write_fp scene2d_object_spawn_z, 128        ; in z
    write_fp scene2d_object_spawn_adjust_rot, (32*0.5)  ; rot*gap
    end_script

seq_set_square_tunnel_2:
    ; TODO: These numbers are the same as above!
    write_addr scene2d_object_vert_p, model_hexagon_verts
    write_addr scene2d_object_num_verts, 3
    write_addr scene2d_object_num, 1            ; for ARM2
    write_fp scene2d_object_z_speed, 1.152      ; z-=speed
    write_fp scene2d_object_rot_speed, 0.5      ; brads/frame
    write_fp scene2d_object_twist, 16           ; brads/square
    write_fp scene2d_object_gap, 32             ; z-=gap
    write_fp scene2d_object_spawn_z, 128        ; in z
    write_fp scene2d_object_spawn_adjust_rot, (32*0.5)  ; rot*gap
    end_script

; ============================================================================
