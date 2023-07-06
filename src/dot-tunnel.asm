; ============================================================================
; Dot Tunnel.
; ============================================================================

.equ DotTunnel_Total, 1024      ; ?

dot_tunnel_t:
    .long 0

;    -- offset to add movement to the tunnel
;    oa=(i+t*2)/50
;    ox=(math.sin(oa)*z*amp)
;    oy=(math.cos(oa/2)*z*amp)
dot_tunnel_offset_x:
    .long dot_tunnel_offset_x_no_adr

dot_tunnel_offset_y:
    .long dot_tunnel_offset_y_no_adr

;    angle=i+t*3.01 -- decimal gives some rotation
;    x=math.sin(angle)*r
;    y=math.cos(angle)*r

dot_tunnel_x:
    .long dot_tunnel_x_no_adr

dot_tunnel_y:
    .long dot_tunnel_y_no_adr

; plot dot tunnel.
; for each dot
; calculate z position (stepping into screen)
; calculate tunnel path centre (x,y) for z
; calculate dot (x,y) position on tunnel at z with radius
; calculate camera relative pos (tpx+dx, tpy+dy, z)
; apply perspective and plot to screen.

; R12=screen addr
dot_tunnel_draw:
    str lr, [sp, #-4]!

    ldr r11, dot_tunnel_t           ; t

    ldr r9, dot_tunnel_x
    ldr r10, dot_tunnel_y

    ldr r7, dot_tunnel_offset_x
    ldr r8, dot_tunnel_offset_y

    adr r14, dot_tunnel_recip_z

    ; TODO: load ox[t] and oy[t]
    ldr r5, [r7, r11, lsl #2]       ; cx=ox[t]
    ldr r6, [r8, r11, lsl #2]       ; cy=oy[t]

.1:
    ldr r2, [r14], #4               ; 80/z [7.16]
    ldr r3, [r9, r11, lsl #2]       ; x[i+t] [s8.16]
    ldr r4, [r10, r11, lsl #2]      ; y[i+t] [s8.16]

    ldr r0, [r7, r11, lsl #2]       ; ox[i+t]
    ldr r1, [r8, r11, lsl #2]       ; oy[i+t]

    add r3, r0, r3                  ; x+ox
    add r4, r1, r4                  ; y+oy

    sub r3, r3, r5                  ; x+ox-cx
    sub r4, r4, r6                  ; y+oy-cy

    mov r2, r2, asr #8              ; [7.8]
    mov r3, r3, asr #8              ; [s8.8]
    mov r4, r4, asr #8              ; [s8.8]
    mul r0, r3, r2                  ; x/z   [s15.16]
    mul r1, r4, r2                  ; y/z   [s15.16]

    mov r0, r0, asr #16             ; [s15.0]
    mov r1, r1, asr #16             ; [s15.0]

    add r0, r0, #160
    add r1, r1, #128

    ; Clip.
    cmp r0, #0
    blt .2
    cmp r0, #Screen_Width
    bge .2
    cmp r1, #0
    blt .2
    cmp r1, #Screen_Height
    bge .2

    add r3, r12, r1, lsl #8
    add r3, r3, r1, lsl #6

;    mov r2, #0xff
    strb r2, [r3, r0]

.2:
    add r11, r11, #1
    cmp r11, #DotTunnel_Total
    movge r11, #0

    adr r0, dot_tunnel_recip_z_end
    cmp r14, r0
    blt .1

    ldr r11, dot_tunnel_t
    add r11, r11, #1
    cmp r11, #DotTunnel_Total
    movge r11, #0
    str r11, dot_tunnel_t

    ldr pc, [sp], #4

dot_tunnel_recip_z:
.set z, 120.0                ; distance to start of tunnel.
.rept DotTunnel_Total
    FLOAT_TO_FP (160.0/z)    ; scale to screen.
    .set z, z+1
.endr
dot_tunnel_recip_z_end:
