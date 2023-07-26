; ============================================================================
; 3D Scene.
; ============================================================================

.equ OBJ_MAX_VERTS, 8
.equ OBJ_MAX_FACES, 6
.equ OBJ_MAX_VISIBLE_FACES, 3       ; True for cube.
.equ OBJ_VERTS_PER_FACE, 4
.equ OBJ_MAX_EDGES_PER_FACE, OBJ_VERTS_PER_FACE

.equ Model_Cube_Num_Verts, 8
.equ Model_Cube_Num_Faces, 6

; The camera viewport is assumed to be [-1,+1] across its widest axis.
; Therefore we multiply all projected coordinates by the screen width/2
; in order to map the viewport onto the entire screen.

.equ VIEWPORT_SCALE,    (Screen_Width /2) * PRECISION_MULTIPLIER
.equ VIEWPORT_CENTRE_X, 160 * PRECISION_MULTIPLIER
.equ VIEWPORT_CENTRE_Y, 128 * PRECISION_MULTIPLIER

.equ EyeDistance_Default_Setting,   5

; ============================================================================
; Scene data.
; ============================================================================

LeftEye_X_Pos:
    FLOAT_TO_FP 0.0

RightEye_X_Pos:
    FLOAT_TO_FP 0.0

; For simplicity, we assume that the camera has a FOV of 90 degrees, so the
; distance to the view plane is 'd' is the same as the viewport scale. All
; coordinates (x,y) lying on the view plane +d from the camera map 1:1 with
; screen coordinates.
;
;   h = viewport_scale / d.
;
; However as much of our maths in the scene is calculated as [8.16] maximum
; precision, having a camera distance of 160 only leaves 96 untis of depth
; to place objects within z=[0, 96] before potential problems occur.
;
; To solve this we use a smaller camera distance. d=80, giving h=160/80=2.
; This means that all vertex coordinates will be multiplied up by 2 when
; transformed to screen coordinates. E.g. the point (32,32,0) will map
; to (64,64) on the screen.
;
; This now gives us z=[0,176] to play with before any overflow errors are
; likely to occur. If this does happen, then we can further reduce the
; coordinate space and use d=40, h=4, etc.


camera_pos:
    VECTOR3 0.0, 0.0, -80.0

; Note camera is fixed to view down +z axis.
; TODO: Camera rotation/direction/look at?

object_pos:
    VECTOR3 0.0, 0.0, 16.0

object_pos_camera_relative:
    VECTOR3 0.0, 0.0, 0.0

object_rot:
    VECTOR3 0.0, 0.0, 0.0

object_scale:
    FLOAT_TO_FP 1.0

object_dir_z:
    FLOAT_TO_FP 1.0

; ============================================================================

object_num_verts:
    .long Model_Cube_Num_Verts

object_num_faces:
    .long Model_Cube_Num_Faces

object_verts_p:
    .long model_cube_verts

object_face_indices_p:
    .long model_cube_face_indices

object_edge_list_per_face_p:
    .long model_cube_edges_per_face

object_edge_indices_p:
    .long model_cube_edge_indices

; ============================================================================
; ============================================================================

eye_distance_table:
    FLOAT_TO_FP 0.0         ; 0
    FLOAT_TO_FP 0.4         ; 1
    FLOAT_TO_FP 0.8         ; 2
    FLOAT_TO_FP 1.2         ; 3
    FLOAT_TO_FP 1.6         ; 4
    FLOAT_TO_FP 2.0         ; 5
    FLOAT_TO_FP 2.4         ; 6
    FLOAT_TO_FP 2.8         ; 7
    FLOAT_TO_FP 3.2         ; 8
    FLOAT_TO_FP 3.6         ; 9

; R0=distance index.
set_eye_distance:

    adr r1, eye_distance_table
    ldr r0, [r1, r0, lsl #2]

    ; For now assume camera is fixed at X=0.
    str r0, RightEye_X_Pos
    mvn r0, r0
    str r0, LeftEye_X_Pos
    mov pc, lr


init_3d_scene:
    str lr, [sp, #-4]!

    mov r0, #EyeDistance_Default_Setting
    bl set_eye_distance

    ldr pc, [sp], #4

; ============================================================================
; ============================================================================

transform_3d_scene:
    str lr, [sp, #-4]!

    ; Skip matrix multiplication altogether.
    ; Transform (x,y,z) into (x'',y'',z'') directly.
    ; Uses 12 muls / rotation.

    ldr r0, object_rot + 8
    bl sin_cos
    mov r10, r0, asr #MULTIPLICATION_SHIFT  ; r10 = sin(A)
    mov r11, r1, asr #MULTIPLICATION_SHIFT  ; r11 = cos(A)

    ldr r0, object_rot + 0
    bl sin_cos
    mov r6, r0, asr #MULTIPLICATION_SHIFT  ; r6 = sin(C)
    mov r7, r1, asr #MULTIPLICATION_SHIFT  ; r7 = cos(C)

    ldr r0, object_rot + 4
    bl sin_cos                  ; uses r9
    mov r8, r0, asr #MULTIPLICATION_SHIFT  ; r8 = sin(B)
    mov r9, r1, asr #MULTIPLICATION_SHIFT  ; r9 = cos(B)

    ldr r1, object_verts_p
    adr r2, transformed_verts
    ldr r12, object_num_verts
    ldr r3, object_num_faces
    add r12, r12, r3                      ; object_num_verts + object_num_faces
    ; ASSUMES THAT VERTEX AND NORMAL ARRAYS ARE CONSECUTIVE!
    .1:
    ldmia r1!, {r3-r5}                    ; x,y,z
    mov r3, r3, asr #MULTIPLICATION_SHIFT
    mov r4, r4, asr #MULTIPLICATION_SHIFT
    mov r5, r5, asr #MULTIPLICATION_SHIFT

	; x'  = x*cos(A) + y*sin(A)
	; y'  = x*sin(A) - y*cos(A)  
    mul r0, r3, r11                     ; x*cos(A)
    mla r0, r4, r10, r0                 ; x' = y*sin(A) + x*cos(A)
    mov r0, r0, asr #MULTIPLICATION_SHIFT

    mul r14, r4, r11                    ; y*cos(A)
    rsb r14, r14, #0                    ; -y*cos(A)
    mla r4, r3, r10, r14                ; y' = x*sin(A) - y*cos(A)
    mov r4, r4, asr #MULTIPLICATION_SHIFT

	; x'' = x'*cos(B) + z*sin(B)
	; z'  = x'*sin(B) - z*cos(B)

    mul r14, r0, r9                     ; x'*cos(B)
    mla r3, r5, r8, r14                 ; x'' = z*sin(B) + x'*cos(B)

    mul r14, r5, r9                     ; z*cos(B)
    rsb r14, r14, #0                    ; -z*cos(B)
    mla r5, r0, r8, r14                 ; z' = x'*sin(B) - z*cos(B)
    mov r5, r5, asr #MULTIPLICATION_SHIFT

	; y'' = y'*cos(C) + z'*sin(C)
	; z'' = y'*sin(C) - z'*cos(C)

    mul r14, r4, r7                     ; y'*cos(C)
    mla r0, r5, r6, r14                 ; y'' = y'*cos(C) + z'*sin(C)

    mul r14, r5, r7                     ; z'*cos(C)
    rsb r14, r14, #0                    ; -z'*cos(C)
    mla r5, r4, r6, r14                 ; z'' = y'*sin(C) - z'*cos(C)

    ; x''=r3, y''=r0, z''=r5
    mov r4, r0
    stmia r2!, {r3-r5}                  ; x'',y'',z'''
    subs r12, r12, #1
    bne .1

    ; Subtract camera position from object position.
    adr r12, camera_pos
    ldmia r12, {r3-r5}

    adr r11, object_pos
    ldmia r11, {r6-r8}

    sub r6, r6, r3
    sub r7, r7, r4
    sub r8, r8, r5

    ; Apply object scale after rotation.
    ldr r0, object_scale
    mov r0, r0, asr #MULTIPLICATION_SHIFT

    adr r2, transformed_verts
    ldr r12, object_num_verts
    .2:
    ldmia r2, {r3-r5}

    ; Scale rotated verts.
    ; TODO: Can we do this with a shift instead of MUL?
    mov r3, r3, asr #MULTIPLICATION_SHIFT
    mov r4, r4, asr #MULTIPLICATION_SHIFT
    mov r5, r5, asr #MULTIPLICATION_SHIFT

    mul r3, r0, r3      ; x_scaled=x*object_scale
    mul r4, r0, r4      ; y_scaled=y*object_scale
    mul r5, r0, r5      ; z_scaled=z*object_scale

    ; Make object vertices camera relative.
    add r3, r3, r6      ; x_scaled + object_pos_x - camera_pos_x
    add r4, r4, r7      ; y_scaled + object_pos_y - camera_pos_y
    add r5, r5, r8      ; z_scaled + object_pos_z - camera_pos_z

    stmia r2!, {r3-r5}
    subs r12, r12, #1
    bne .2

    ldr pc, [sp], #4

update_3d_scene:
    str lr, [sp, #-4]!

    ; Update any scene vars, camera, object position etc. (Rocket?)
    .if 1
    mov r1, #MATHS_CONST_HALF    ; ROTATION_X
    ldr r0, object_rot+0
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+0

    mov r1, #MATHS_CONST_HALF    ; ROTATION_Y
    ldr r0, object_rot+4
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+4

    mov r1, #MATHS_CONST_HALF    ; ROTATION_Z
    ldr r0, object_rot+8
    add r0, r0, r1
    bic r0, r0, #0xff000000         ; brads
    str r0, object_rot+8


    ldr r0, object_pos+8            ; POSTION_Z
    ldr r1, object_dir_z
    add r0, r0, r1
    cmp r0, #64.0*PRECISION_MULTIPLIER
    mvnge r1, r1                    ; invert dir
    cmp r0, #-24.0*PRECISION_MULTIPLIER
    mvnle r1, r1                    ; invert dir
    str r0, object_pos+8
    str r1, object_dir_z

    .else
	mov r0, #0
	swi QTM_ReadVULevels
	; R0 = word containing 1 byte per channel 1-4 VU bar heights 0-64
    ; TODO: Finalise mapping of vu levels to scale & rotation deltas.
    and r10, r0, #0xff              ; channel 1 = scale
    mov r1, #MATHS_CONST_1
    add r1, r1, r10, asl #11         ; scale maps [1, 2]
    str r1, object_scale

    ; TODO: Make this code more compact?
  	mov r10, r0, lsr #8             ; channel 2 = inc_x
	and r10, r10, #0xff
    mov r10, r10, asl #11           ; inc_x maps [0, 2]
    ldr r1, object_rot + 0
    add r1, r1, r10                 ; object_rot_x += inc_x
    str r1, object_rot + 0

  	mov r10, r0, lsr #16            ; channel 3 = inc_y
	and r10, r10, #0xff
    mov r10, r10, asl #11           ; inc_y maps [0, 2]
    ldr r1, object_rot + 4
    add r1, r1, r10                 ; object_rot_y += inc_y
    str r1, object_rot + 4

  	mov r10, r0, lsr #24            ; channel 4 = inc_z
	and r10, r10, #0xff
    mov r10, r10, asl #11           ; inc_z maps [0, 2]
    ldr r1, object_rot + 8
    add r1, r1, r10                 ; object_rot_z += inc_z
    str r1, object_rot + 8
    .endif

    ldr pc, [sp], #4

; ============================================================================
; ============================================================================

; R12=screen addr
anaglyph_draw_3d_scene:
    str lr, [sp, #-4]!

    ; Left eye.
    ldr r0, LeftEye_X_Pos
    str r0, camera_pos+0        ; camera_pos_x

    stmfd sp!, {r12}
    bl transform_3d_scene
    ldmfd sp!, {r12}

    ; Subtract blue & green.
    mov r4, #7                  ; brightest red
    bl draw_3d_scene

    ; Right eye.
    ldr r0, RightEye_X_Pos
    str r0, camera_pos+0        ; camera_pos_x

    stmfd sp!, {r12}
    bl transform_3d_scene
    ldmfd sp!, {r12}

    ; Subtract red.
    mov r4, #11                 ; brightest cyan
    bl draw_3d_scene

    ldr pc, [sp], #4

draw_3d_scene_in_colour:
    .long 0

; R4=colour index
; R12=screen addr
draw_3d_scene:
    str lr, [sp, #-4]!

    ; Stash screen addr for now.
    str r12, [sp, #-4]!

    str r4, draw_3d_scene_in_colour

    ; Project vertices to screen.
    adr r2, transformed_verts
    ldr r11, object_num_verts
    adr r12, projected_verts
    .1:
    ; R2=ptr to world pos vector
    bl project_to_screen
    ; R0=screen_x, R1=screen_y [16.16]
    mov r0, r0, asr #16         ; [16.0]
    mov r1, r1, asr #16         ; [16.0]
    stmia r12!, {r0, r1}
    add r2, r2, #VECTOR3_SIZE
    subs r11, r11, #1
    bne .1

    ldr r12, [sp], #4           ; pop screen addr

    ; Plot faces as polys.
    ldr r11, object_face_indices_p
    mov r9, #0                  ; face count
    str r9, edge_plot_cache

    ldr r9, object_num_faces
    sub r9, r9, #1

    .2:
    ldrb r5, [r11, r9, lsl #2]  ; vertex0 of polygon N.
    
    adr r1, transformed_verts
    add r1, r1, r5, lsl #3
    add r1, r1, r5, lsl #2      ; transformed_verts + index*12
    adr r2, transformed_normals
    add r2, r2, r9, lsl #3      ; face_normal
    add r2, r2, r9, lsl #2      ; face_normal

    ; Backfacing culling test (vertex - camera_pos).face_normal
    ; Parameters:
    ;  R1=ptr to transformed vertex in camera relative space
    ;  R2=ptr to face normal vector
    ; Return:
    ;  R0=dot product of (v0-cp).n
    ; Trashes: r3-r8
    ; vector A = (v0 - camera_pos)
    ; vector B = face_normal
    bl vector_dot_product

    cmp r0, #0                  
    bpl .3                      ; normal facing away from the view direction.

    .if 0
    adr r2, projected_verts     ; projected vertex array.
    ldr r3, [r11, r9, lsl #2]   ; quad indices.

    stmfd sp!, {r9,r11,r12}
    ldr r4, draw_3d_scene_in_colour
    bl line_plot_quad_indexed
    ldmfd sp!, {r9,r11,r12}
    .else

    ldr r4, draw_3d_scene_in_colour
    ldr r5, object_edge_indices_p
    adr r6, projected_verts     ; projected vertex array.
    ldr r7, object_edge_list_per_face_p
    ldr r7, [r7, r9, lsl #2]    ; edge list word.

    stmfd sp!, {r9,r11}         ; TODO: Don't store r11?
    bl plot_face_edge_list
    ldmfd sp!, {r9,r11}
    .endif

    .3:
    subs r9, r9, #1
    bpl .2

    ldr pc, [sp], #4

edge_plot_cache:
    .long 0

; Plot all edges in a list.
; Parameters:
;  R12=screen addr
;  R4=colour index
;  R5=ptr to array of edge indices.
;  R6=ptr to projected vertex array (x,y) in screen coords [16.0]
;  R7=edge list word (one bit per edge to be plotted)
plot_face_edge_list:
	str lr, [sp, #-4]!			; push lr on stack

    ldr r11, edge_plot_cache
    mov r8, #0                  ; edge no.
.1:
    ; Convert edge no. to bit no.
    mov r9, #1

    ; Test edge list cache.
    tst r11, r9, lsl r8         ; already plotted?
    bne .2

    ; Test if this edge is in the face.
    tst r7, r9, lsl r8
    beq .2

    ; Look up vertex indices for edge.
    ldr r0, [r5, r8, lsl #1]    ; misaligned read!
    mov r2, r0, lsr #8          ; end index
    and r0, r0, #0xff           ; start index
    and r2, r2, #0xff

    ; Load (x,y) for start vertex
    add r9, r6, r0, lsl #3      ; projected_verts[start_index]
    ldmia r9, {r0,r1}           ; start_x, start_y

    ; Load (x,y) for end vertex
    add r9, r6, r2, lsl #3      ; projected_verts[start_index]
    ldmia r9, {r2,r3}           ; end_x, end_y

    stmfd sp!, {r5-r8}
    bl mode9_drawline_orr       ; trashes r5-r10
    ldmfd sp!, {r5-r8}

    ; Mark edge as plotted in cache.
    mov r9, #1
    orr r11, r11, r9, lsl r8

.2:
    ; Early out when edge list word is zero.
    bics r7, r7, r9, lsl r8
    beq .3

    ; Next edge no.
    add r8, r8, #1
    cmp r8, #32
    blt .1

.3:
    str r11, edge_plot_cache
    ldr pc, [sp], #4


; Plot a quad, but lines.
; Parameters:
;  R12=screen addr
;  R2=ptr to projected vertex array (x,y) in screen coords [16.0]
;  R3=4x vertex indices for quad
;  R4=colour index
line_plot_quad_indexed:
	str lr, [sp, #-4]!			; push lr on stack

    mov r8, r2
    mov r9, r3

    and r6, r9, #0xff           ; index 0
    add r5, r8, r6, lsl #3      ; projected_verts + index*8
    ldmia r5, {r0, r1}          ; x_start, y_start

    mov r6, r9, lsr #8          ; 
    and r6, r6, #0xff           ; index 1
    add r5, r8, r6, lsl #3      ; projected_verts + index*8
    ldmia r5, {r2, r3}          ; x_end, y_end

    stmfd sp!, {r8,r9}
    bl mode9_drawline_orr       ; trashes r5-r10
    ldmfd sp!, {r8,r9}

    mov r0, r2                  ; x_start = x_end
    mov r1, r3                  ; y_start = y_end

    mov r6, r9, lsr #16         ; 
    and r6, r6, #0xff           ; index 2
    add r5, r8, r6, lsl #3      ; projected_verts + index*8
    ldmia r5, {r2, r3}          ; x_end, y_end

    stmfd sp!, {r8,r9}
    bl mode9_drawline_orr       ; trashes r5-r10
    ldmfd sp!, {r8,r9}

    mov r0, r2                  ; x_start = x_end
    mov r1, r3                  ; y_start = y_end

    mov r6, r9, lsr #24         ; 
    and r6, r6, #0xff           ; index 3
    add r5, r8, r6, lsl #3      ; projected_verts + index*8
    ldmia r5, {r2, r3}          ; x_end, y_end

    stmfd sp!, {r8,r9}
    bl mode9_drawline_orr       ; trashes r5-r10
    ldmfd sp!, {r8,r9}

    mov r0, r2                  ; x_start = x_end
    mov r1, r3                  ; y_start = y_end

    and r6, r9, #0xff           ; index 0
    add r5, r8, r6, lsl #3      ; projected_verts + index*8
    ldmia r5, {r2, r3}          ; x_end, y_end

    bl mode9_drawline_orr       ; trashes r5-r10

    ldr pc, [sp], #4


; Project world position to screen coordinates.
; TODO: Try weak perspective model, i.e. a single distance for all vertices in the objects.
;       Means that we can calculate the reciprocal once (1/z) and use the same value in
;       all perspective calculations. Suspect this is what most Amiga & ST demos do...
;
; R2=ptr to camera relative transformed position
; Returns:
;  R0=screen x
;  R1=screen y
; Trashes: R3-R10
project_to_screen:
    str lr, [sp, #-4]!

    ; Vertex already transformed and camera relative.
    ldmia r2, {r3-r5}           ; (x,y,z)

    ; vp_centre_x + vp_scale * (x-cx) / (z-cz)
    mov r0, r3                  ; (x-cx)
    mov r1, r5                  ; (z-cz)
    bl divide                   ; (x-cx)/(z-cz)
                                ; [0.16]
    mov r7, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r6, r0, r7              ; [12.20]
    mov r6, r6, asr #4          ; [12.16]
    mov r8, #VIEWPORT_CENTRE_X  ; [16.16]
    add r6, r6, r8

    ; Flip Y axis as we want +ve Y to point up the screen!
    ; vp_centre_y - vp_scale * (y-cy) / (z-cz)
    mov r0, r4                  ; (y-cy)
    mov r1, r5                  ; (z-cz)
    bl divide                   ; (y-cy)/(z-cz)
                                ; [0.16]
    mov r7, #VIEWPORT_SCALE>>12 ; [16.4]
    mul r1, r0, r7              ; [12.20]
    mov r1, r1, asr #4          ; [12.16]
    mov r8, #VIEWPORT_CENTRE_Y  ; [16.16]
    sub r1, r8, r1              ; [16.16]

    mov r0, r6
    ldr pc, [sp], #4


; ============================================================================
; Object data: CUBE
;
;         4         5        y
;          +------+          ^  z
;         /      /|          |/
;        /      / |          +--> x
;     0 +------+ 1|
;       | 7 +  |  + 6
;       |      | /
;       |      |/
;       +------+
;      3        2
; ============================================================================

model_cube_verts:
    VECTOR3 -16.0,  16.0, -16.0
    VECTOR3  16.0,  16.0, -16.0
    VECTOR3  16.0, -16.0, -16.0
    VECTOR3 -16.0, -16.0, -16.0
    VECTOR3 -16.0,  16.0,  16.0
    VECTOR3  16.0,  16.0,  16.0
    VECTOR3  16.0, -16.0,  16.0
    VECTOR3 -16.0, -16.0,  16.0

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

model_cube_face_normals:
    VECTOR3  0.0,  0.0, -1.0
    VECTOR3  1.0,  0.0,  0.0
    VECTOR3  0.0,  1.0,  0.0
    VECTOR3  0.0,  0.0,  1.0
    VECTOR3 -1.0,  0.0,  0.0
    VECTOR3  0.0  -1.0,  0.0

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

; Winding order is clockwise (from outside)
model_cube_face_indices:
    .byte 0, 1, 2, 3
    .byte 1, 5, 6, 2
    .byte 0, 4, 5, 1
    .byte 5, 4, 7, 6
    .byte 4, 0, 3, 7
    .byte 2, 3, 7, 6

; TODO: Determine this from model_cube_face_indices.
; TODO: Handle more than 32 total edges.
model_cube_edges_per_face:
;            3         2         1         
;           10987654321098765432109876543210
    .long 0b00000000000000000000000000001111
    .long 0b00000000000000000000011000100010
    .long 0b00000000000000000000001100010001
    .long 0b00000000000000000000000011110000
    .long 0b00000000000000000000100110001000
    .long 0b00000000000000000000110001000100

; TODO: Determine this from model_cube_face_indices.
model_cube_edge_indices:
    .byte 0, 1              ; 0
    .byte 1, 2              ; 1
    .byte 2, 3              ; 2
    .byte 3, 0              ; 3
    .byte 4, 5              ; 4
    .byte 5, 6              ; 5
    .byte 6, 7              ; 6
    .byte 7, 4              ; 7
    .byte 0, 4              ; 8
    .byte 1, 5              ; 9
    .byte 2, 6              ; 10
    .byte 3, 7              ; 11
.p2align 2

 ;TODO: Object face colours or vertex colours etc.

; ============================================================================
; Scene data.
; ============================================================================

transformed_verts:
    .skip OBJ_MAX_VERTS * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

transformed_normals:
    .skip OBJ_MAX_FACES * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

projected_verts:
    .skip OBJ_MAX_VERTS * 2 * 4

; ============================================================================
