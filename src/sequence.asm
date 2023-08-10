; ============================================================================
; The actual sequence for the demo.
; ============================================================================


seq_main_program:

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 init_3d_scene

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                   screen_cls

    fork effect_loop

    ; THE END.
    end_script

effect_loop:

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_wire
    wait_secs 5.0

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_circles
    wait_secs 5.0

    call_3 fx_set_layer_fns, 1, update_3d_scene,     anaglyph_draw_3d_scene_as_solid
    wait_secs 5.0

    fork effect_loop
    end_script

    ; TODO: End demo or loop etc.
