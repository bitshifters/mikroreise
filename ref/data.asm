; data

xSinus:  ; used by the CD2-Logo
    dc.w $8,$8,$9,$9,$a,$a,$b,$b,$c,$c,$d,$d,$e,$e,$e,$f
    dc.w $f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$e,$e,$e
    dc.w $d,$d,$c,$c,$b,$b,$a,$a,$9,$8,$8,$7,$7,$6,$5,$5
    dc.w $4,$4,$3,$3,$2,$2,$1,$1,$1,$0,$0,$0,$0,$0,$0,$0
    dc.w $0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$2,$2,$3,$3,$4,$4
    dc.w $5,$5,$6,$6,$7,$7,$8,$9,$9,$a,$a,$b,$b,$c,$c,$d
    dc.w $d,$e,$e,$e,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f
    dc.w $f,$f,$e,$e,$e,$d,$d,$c,$c,$b,$b,$a,$a,$9,$8,$8
    dc.w $7,$7,$6,$5,$5,$4,$4,$3,$3,$2,$2,$1,$1,$1,$0,$0
    dc.w $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$2
    dc.w $2,$3,$3,$4,$4,$5,$5,$6,$6,$7,$7,$8,$9,$9,$a,$a
    dc.w $b,$b,$c,$c,$d,$d,$e,$e,$e,$f,$f,$f,$f,$f,$f,$f
    dc.w $f,$f,$f,$f,$f,$f,$f,$e,$e,$e,$d,$d,$c,$c,$b,$b
    dc.w $a,$a,$9,$8,$8,$7,$7,$6,$5,$5,$4,$4,$3,$3,$2,$2
    dc.w $1,$1,$1,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
    dc.w $0,$1,$1,$1,$2,$2,$3,$3,$4,$4,$5,$5,$6,$6,$7,$7
ySinus:  ; used by the CD2-Logo
   dc.w $8,$8,$8,$9,$9,$9,$a,$a,$b,$b,$b,$c,$c,$c,$d,$d
   dc.w $d,$d,$e,$e,$e,$e,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f
   dc.w $f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$e,$e,$e,$e,$d
   dc.w $d,$d,$d,$c,$c,$c,$b,$b,$a,$a,$a,$9,$9,$9,$8,$8
   dc.w $7,$7,$7,$6,$6,$5,$5,$5,$4,$4,$4,$3,$3,$3,$2,$2
   dc.w $2,$1,$1,$1,$1,$1,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
   dc.w $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$2
   dc.w $2,$2,$3,$3,$3,$4,$4,$4,$5,$5,$5,$6,$6,$7,$7,$7
   dc.w $8,$8,$8,$9,$9,$a,$a,$a,$b,$b,$b,$c,$c,$c,$d,$d
   dc.w $d,$e,$e,$e,$e,$e,$f,$f,$f,$f,$f,$f,$f,$f,$f,$f
   dc.w $f,$f,$f,$f,$f,$f,$f,$f,$f,$f,$e,$e,$e,$e,$e,$d
   dc.w $d,$d,$c,$c,$c,$b,$b,$b,$a,$a,$a,$9,$9,$8,$8,$8
   dc.w $7,$7,$6,$6,$6,$5,$5,$5,$4,$4,$3,$3,$3,$2,$2,$2
   dc.w $2,$1,$1,$1,$1,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
   dc.w $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$2,$2
   dc.w $2,$2,$3,$3,$3,$4,$4,$4,$5,$5,$6,$6,$6,$7,$7,$7


; master volume of each tune

volumeTable:
    dc.b    35-2  ; birdhouse
    dc.b    62-3  ; autumn
    dc.b    51-3  ; je suis k
    dc.b    60-3  ; square circles
    dc.b    54-3  ; la soupe
    dc.b    56-3  ; sajt
    dc.b    59-3  ; bodoaxian
    dc.b    64    ; holodash
    dc.b    39-1  ; squid ring
    dc.b    61-2  ; lies
    even

durationTable:
;    dcb.w   10,250
    dc.w    51*50       ; birdhouse
    dc.w    192*50      ; autumn
    dc.w    159*50      ; je suis k
    dc.w    173*50      ; square circles
    dc.w    120*50      ; la soupe
    dc.w    95*50       ; sajt
    dc.w    110*50      ; bodoaxian
    dc.w    116*50      ; holodash
    dc.w    174*50      ; squid ring
    dc.w    181*50      ; lies

; break between tunes
songpausetable:
    dc.w    50      ; birdhouse
    dc.w    10      ; autumn
    dc.w    70      ; je suis k
    dc.w    80      ; square circles
    dc.w    80      ; la soupe
    dc.w    50      ; sajt
    dc.w    70      ; bodoaxian
    dc.w    90      ; holodash
    dc.w    90      ; squid ring
    dc.w    50      ; lies

;----------------------------

COLORBAR0=$122 ; main background
COLORBAR1=$443 ;
COLORBAR2=$654 ;
COLORBAR3=$975 ;
COLORBAR4=$c97 ;
COLORBAR5=$fb8 ;



; cube-colors	
    dc.w color01,$2a9
	dc.w color02,$167
	dc.w color03,$234
; menu-colors
    dc.w color04,$ac7
    dc.w color05,$cfa  ; under the cube
    dc.w color06,$bfa  ; under the cube
    dc.w color07,$bf7  ; under the cube

    dc.w color12,$191  ; line marker  is set via menu
    dc.w color13,$3b3  ; line marker under the cube
    dc.w color14,$2b3  ; line marker under the cube
    dc.w color15,$2b2  ; line marker under the cube


    dc.w color01,$c31  ; scroller color