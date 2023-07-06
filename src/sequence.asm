; ============================================================================
; The actual sequence for the demo.
; ============================================================================


seq_main_program:

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 particles_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,      screen_cls
    ; call_3 fx_set_layer_fns, 1, particles_tick_all,     particles_draw_all
    call_3 fx_set_layer_fns, 1, 0,     dot_tunnel_draw

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.
