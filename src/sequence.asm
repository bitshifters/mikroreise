; ============================================================================
; The actual sequence for the demo.
; ============================================================================


seq_main_program:

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 init_3d_scene
    call_0 starfield_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                   screen_cls

.if 1
    call_3 fx_set_layer_fns, 1, static_set_palette,  static_copy_screen
    write_addr static_palette_p, hammer_pal_no_adr
    write_addr static_screen_p, hammer_screen_no_adr
    wait_secs 5.0
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

    call_3 fx_set_layer_fns, 1, starfield_update,    starfield_draw_anaglyph
    wait_secs 20.0

    call_3 fx_set_layer_fns, 1, dot_tunnel_update,   dot_tunnel_draw_anaglyph_spiral
    wait_secs 20.0

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_wire
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_circles
    wait_secs 10.0

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_solid
    wait_secs 10.0

    fork effect_loop
    end_script

    ; TODO: End demo or loop etc.
