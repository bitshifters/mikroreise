; ============================================================================
; The actual sequence for the demo.
; ============================================================================


seq_main_program:

    ; TODO: Setup music etc. here also?

    ; Init FX modules.
    call_0 particles_init

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, emitters_tick_all,      screen_cls
    call_3 fx_set_layer_fns, 1, particles_tick_all,     particles_draw_all
    ; call_3 fx_set_layer_fns, 1, 0,     dots_draw_all

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.
