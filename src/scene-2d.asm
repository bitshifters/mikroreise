; ============================================================================
; 2D Scene.
; 2D Wireframe objects that move in 3D space but are camera facing.
; Assume single face, no culling.
; Assume multiple objects with independent position, rotation, scale.
; TODO: What about clipping to screen edges?
; ============================================================================

.equ Scene2D_ObjectBuffer_Size, 10 * VECTOR3_SIZE * 10 + 10 * 4 ; 10 objects with max 10 verts each.
.equ Scene2D_MaxVerts, 32

; ============================================================================
; Scene data.
; Reuse most variables from 3d-scene?
;   camera_pos
;   LeftEye_X_Pos
;   RightEye_X_Pos
; etc.
; Assume a scene has multiple objects
; Can a scene contain a variety of objects?
; ============================================================================

scene2d_colour_index:
    .long 0

scene2d_reciprocal_table_p:
    .long reciprocal_table_no_adr

scene2d_update:
    str lr, [sp, #-4]!

    ; TODO: Move camera.
    ; TODO: Spawn objects.
    ; TODO: Move objects.
    
    ; TEMP: To update object_pos, object_rot.
    bl update_3d_scene

    ; Reset object list.
    adr r0, scene2d_object_buffer
    str r0, scene2d_object_list_p

    ; R0=Ptr to object position vector (3D).
    ; R1=Object rotation (just around Z for now).
    ; R2=Ptr to object data = a list of verts (currently VECTOR3)
    ; R3=Number of verts.
    ; R5=Object scale.

    adr r0, object_pos
    ldr r1, object_rot+8
    adr r2, model_square_verts
    mov r3, #4
    ldr r5, object_scale
    bl scene2d_transform_object

.if 1
; Position left.
    mov r0, #-32*PRECISION_MULTIPLIER
    str r0, object_pos+0
    ldr r0, object_pos+8
    str r0, [sp, #-4]!

    add r0, r0, #32*PRECISION_MULTIPLIER
    str r0, object_pos+8

    adr r0, object_pos
    ldr r1, object_rot+8
    sub r1, r1, #16*PRECISION_MULTIPLIER
    bic r1, r1, #0xff000000         ; brads
    adr r2, model_square_verts
    mov r3, #4
    mov r5, #2*PRECISION_MULTIPLIER
    bl scene2d_transform_object

; Position right.
    mov r0, #32*PRECISION_MULTIPLIER
    str r0, object_pos+0
    ldr r0, object_pos+8
    add r0, r0, #32*PRECISION_MULTIPLIER
    str r0, object_pos+8

    adr r0, object_pos
    ldr r1, object_rot+8
    add r1, r1, #32*PRECISION_MULTIPLIER
    bic r1, r1, #0xff000000         ; brads
    adr r2, model_square_verts
    mov r3, #4
    mov r5, #MATHS_CONST_HALF
    bl scene2d_transform_object

    mov r0, #0
    str r0, object_pos+0

    ldr r0, [sp], #4
    str r0, object_pos+8
.endif

    ; Terminate object list.
    ldr r0, scene2d_object_list_p
    mov r1, #-1
    str r1, [r0]

    ldr pc, [sp], #4

scene2d_draw_anaglyph:
    str lr, [sp, #-4]!

    ; Left eye.
    ldr r0, LeftEye_X_Pos
    str r0, camera_pos+0        ; camera_pos_x

    ; Subtract blue & green.
    mov r4, #7                  ; brightest red
    bl scene2d_draw

    ; Right eye.
    ldr r0, RightEye_X_Pos
    str r0, camera_pos+0        ; camera_pos_x

    ; Subtract red.
    mov r4, #11                 ; brightest cyan
    bl scene2d_draw

    ldr pc, [sp], #4

; Plot all objects in the scene.
; R4=colour index
; R12=screen addr
scene2d_draw:
    str lr, [sp, #-4]!

    str r4, scene2d_colour_index

    adr r2, scene2d_object_buffer
.1:
    ldr r1, [r2], #4                       ; load num verts
    cmp r1, #0
    blt .3

    ; Load camera [x, y, z].
    adr r0, camera_pos
    ldmia r0, {r6-r8}

    ldr r9, scene2d_reciprocal_table_p
    adr r10, scene2d_verts_buffer
.2:
    ; Load transformed verts [R3,R5,R5] = [x,y,z]
    ldmia r2!, {r3-r5}
    ; NOTE: Z is same for all verts currently.

    ; Subtract camera_pos from world_pos.
    sub r3, r3, r6
    sub r4, r4, r7
    sub r5, r5, r8

    ; Project to screen.

    ; Put divisor in table range.
    mov r5, r5, asr #16-LibDivide_Reciprocal_s    ; [16.6]    (b<<s)

    .if _DEBUG
    cmp r5, #0
    adrle r0,errbehindcamera    ; and flag an error
    swile OS_GenerateError      ; when necessary
    ; TODO: Probably just cull these objects?

    ; Limited precision.
    cmp r5, #1<<LibDivide_Reciprocal_t    ; Test for numerator too large
    adrge r0,divrange           ; and flag an error
    swige OS_GenerateError      ; when necessary
    .endif

    ; Lookup 1/z.
    ldr r5, [r9, r5, lsl #2]    ; [0.16]    (1<<16+s)/(b<<s) = (1<<16)/b

    ; x/z
    mov r3, r3, asr #16-LibDivide_Reciprocal_s    ; [16.6]    (a<<s)
    mul r3, r5, r3                      ; [10.22]   (a<<s)*(1<<16)/b = (a<<16+s)/b
    mov r3, r3, asr #LibDivide_Reciprocal_s       ; [10.16]   (a<<16)/b = (a/b)<<16

    ; y/z
    mov r4, r4, asr #16-LibDivide_Reciprocal_s    ; [16.6]    (a<<s)
    mul r4, r5, r4                      ; [10.22]   (a<<s)*(1<<16)/b = (a<<16+s)/b
    mov r4, r4, asr #LibDivide_Reciprocal_s       ; [10.16]   (a<<16)/b = (a/b)<<16

    ; screen_x = vp_centre_x + vp_scale * (x-cx) / (z-cz)
    mov r0, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r3, r0, r3              ; [12.20]
    mov r3, r3, asr #4           ; [12.16]
    mov r0, #VIEWPORT_CENTRE_X  ; [16.16]
    add r3, r3, r0

    ldrb r0, Anaglyph_Enable_Skew
    cmp r0, #0
    ldrne r0, camera_pos+0      ; camera_pos_x
    movne r0, r0, asl #1
    addne r3, r3, r0

    ; screen_y = vp_centre_y - vp_scale * (y-cy) / (z-cz)
    mov r0, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r4, r0, r4              ; [12.20]
    mov r4, r4, asr #4           ; [12.16]
    mov r0, #VIEWPORT_CENTRE_Y  ; [16.16]
    sub r4, r0, r4              ; [16.16]

    mov r3, r3, asr #16         ; [16.0]
    mov r4, r4, asr #16         ; [16.0]
    ; TODO: Could pack these [x:y] into one word?
    stmia r10!, {r3-r4}           ; or push to stack?

    ; Next vertex.
    subs r1, r1, #1
    bne .2

    str r2, [sp, #-4]!          ; stash ptr in r2

    ; R10=top of buffer
    ldr r4, scene2d_colour_index
    adr r11, scene2d_verts_buffer
.5:
    ldmia r11, {r0-r3}          ; (xstart,ystart,xend,yend)
    add r11, r11, #VECTOR2_SIZE
    cmp r11, r10
    bge .6

    ; TODO: When to clip to edges of screen? :S
    bl mode9_drawline_orr       ; trashes r5-r9
    ; NOTE: Can't reuse R3=yend as gets scaled by Screen_Stride.
    b .5

.6:
    ; Load vertex 0 as (xend,yend) for last line.
    adr r11, scene2d_verts_buffer
    ldmia r11, {r2-r3}
    bl mode9_drawline_orr       ; trashes r5-r9

    ; Next object.
    ldr r2, [sp], #4            ; unstash ptr in r2
    b .1

.3:
    ldr pc, [sp], #4

.if _DEBUG
    errbehindcamera: ;The error block
    .long 0
	.byte "Vertex behind camera."
	.align 4
	.long 0
.endif

; Transform an object into world coordinates.
; Assume 2D objects are just outlines.
; R0=Ptr to object position vector (3D).
; R1=Object rotation (just around Z for now).
; R2=Ptr to object data = a list of verts (currently VECTOR3)
; R3=Number of verts.
; R5=Object scale.
scene2d_transform_object:
    str lr, [sp, #-4]!

    ldmia r0, {r6-r8}                       ; object_pos

    mov r12, r3                             ; num verts
    str r4, scene2d_colour_index

    mov r0, r1                              ; A=object_rot_z
    bl sin_cos                              ; Trashes R9!
    mov r10, r0, asr #MULTIPLICATION_SHIFT  ; r10 = sin(A)
    mov r11, r1, asr #MULTIPLICATION_SHIFT  ; r11 = cos(A)

    mov r9, r5, asr #MULTIPLICATION_SHIFT   ; object_scale [8.8]

    ldr r14, scene2d_object_list_p
    str r12, [r14], #4                      ; push num verts.

.1:
    ; Load vertex.
    ldmia r2!, {r3-r5}                      ; [R3,R4,R5] = [x,y,z=0.0]
    mov r3, r3, asr #MULTIPLICATION_SHIFT
    mov r4, r4, asr #MULTIPLICATION_SHIFT

    ; Rotate X & Y around Z.

	; x'  = x*cos(A) + y*sin(A)
	; y'  = x*sin(A) - y*cos(A)  
    mul r0, r3, r11                     ; x*cos(A)
    mla r0, r4, r10, r0                 ; x' = y*sin(A) + x*cos(A)

    mul r1, r4, r11                     ; y*cos(A)
    rsb r1, r1, #0                      ; -y*cos(A)
    mla r4, r3, r10, r1                 ; y' = x*sin(A) - y*cos(A)

    mov r3, r0                          ; [R3,R4,R5] = [x',y',z=0.0]

    ; Apply object scale after rotation.
    ; TODO: Can we do this with a shift instead of MUL?
    mov r3, r3, asr #MULTIPLICATION_SHIFT
    mov r4, r4, asr #MULTIPLICATION_SHIFT
    mov r5, r5, asr #MULTIPLICATION_SHIFT   ; z=0.0

    ; Transform vertex into world space.
    mla r3, r9, r3, r6  ; world_x=x'*object_scale + object_pos_x
    mla r4, r9, r4, r7  ; world_y=y'*object_scale + object_pos_y
    mla r5, r9, r5, r8  ; world_z=z *object_scale + object_pos_z

    ; Save transformed verts in buffer.
    stmia r14!, {r3-r5}

    subs r12, r12, #1
    bne .1

    ; Save ptr into object buffer.
    str r14, scene2d_object_list_p
    ; TODO: Check for buffer overflow!

    ldr pc, [sp], #4

; ============================================================================
; Model data: SQUARE
;
;     0 +------+ 1
;       |      |
;       |      |
;       |      |
;       +------+
;      3        2
; ============================================================================

; TODO: Use VECTOR2?
model_square_verts:
    VECTOR3 -16.0,  16.0, 0.0
    VECTOR3  16.0,  16.0, 0.0
    VECTOR3  16.0, -16.0, 0.0
    VECTOR3 -16.0, -16.0, 0.0

; ============================================================================
; TODO: Model data for: triangle, pentagon, hexagon, stars, seagull etc.
; ============================================================================

scene2d_object_list_p:
    .long scene2d_object_buffer

; All objects transformed to world space.
scene2d_object_buffer:
    .skip Scene2D_ObjectBuffer_Size

scene2d_verts_buffer:
    .skip Scene2D_MaxVerts * VECTOR2_SIZE