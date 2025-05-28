;
; NES/C base library
; based on: https://github.com/bbbradsmith/boingnes
;

.export _ppu_latch          ; void ppu_latch(uint16 addr)
.export _ppu_latch_at       ; void ppu_latch_at(uint8 x, uint8 y)
.export _ppu_write          ; void ppu_write(uint8 value);
.export _ppu_load           ; void ppu_load(const uint8* data, uint16 count)
.export _ppu_fill           ; void ppu_fill(uint8 value, uint16 count)
.export _ppu_string         ; void ppu_string(const char* s)
.export _ppu_char           ; void ppu_char(char c)
.export _ppu_packet         ; void ppu_packet(uint16 addr, const uint8* data, uint8 count)
.export _ppu_packet_reserve ; uint8 ppu_packet_reserve(uint16 addr, uint8 count)
.export _ppu_ctrl           ; void ppu_ctrl(uint8 v)
.export _ppu_ctrl_apply     ; void ppu_ctrl_apply(uint8 v)
.export _ppu_ctrl_get       ; uint8 ppu_ctrl_get()
.export _ppu_mask           ; void ppu_mask(uint8 v)
.export _ppu_mask_apply     ; void ppu_mask_apply(uint8 v)
.export _ppu_scroll         ; void ppu_scroll(uint16 x, uint16 y)
.export _ppu_render_frame   ; void ppu_render_frame()
.export _ppu_wait_frame     ; void ppu_wait_frame()
.export _ppu_render_off     ; void ppu_render_off()
.export _ppu_nmi_off        ; void ppu_nmi_off()
.export _ppu_nmi_on         ; void ppu_nmi_on()

.export _sprite_begin       ; void sprite_begin()
.export _sprite_end         ; void sprite_end()
.export _sprite_tile        ; void sprite_tile(uint8 t, uint8 a, uint8 x, uint8 y)
;.export _sprite             ; void sprite(uint8 e, uint8 x, uint8 y)
;.export _sprite_flip        ; void sprite_flip(uint8 e, uint8 x, uint8 y)

.export _input_poll         ; uint8 input_poll()
.export _nescopy            ; void nescopy(void* dst, const void* src, uint8 count)
.export _nesset             ; void nesset(void* dst, uint8 value, uint8 count)

.export ppu_string_ptr1     ; added for internal access to ppu_string with ptr1 already set up

;.import SPRITE_COUNT
;.import sprite_data
.importzp _sprite_offset ; used by replaced sprite() routine

.import popa ; cc65
.import popax ; cc65
.import popptr1 ; cc65
.import incsp3 ; cc65
.importzp tmp1, tmp2, tmp3, tmp4 ; cc65
.importzp ptr1, ptr2 ; cc65

.include "../ram.inc"

.segment "FIXED"

; =========
; Rendering
; =========

_ppu_latch: ; void ppu_latch(uint16 addr)
	bit $2002
	stx $2006
	sta $2006
	rts

_ppu_latch_at: ; void ppu_latch_at(uint8 x, uint8 y)
	; X: .....6.. ...54321
	; Y: ....6.54 321.....
	; A = Y
	ldx #0
	stx ptr1+0
	lsr
	ror ptr1+0
	lsr
	ror ptr1+0
	pha
	lsr
	ror ptr1+0 ; ptr1+0 = Y 321.....
	and #%00000011
	sta ptr1+1
	pla
	and #%00001000
	ora ptr1+1
	ora #$20
	sta ptr1+1 ; ptr1+1 = Y ....6.54 | $20
	jsr popa ; A = X
	pha
	lsr
	lsr
	lsr
	and #%00000100
	ora ptr1+1
	tax ; X .....6.. | Y ....6... | $20
	pla
	and #%00011111
	ora ptr1+0 ; X ...54321 | Y 321.....
	jmp _ppu_latch

_ppu_write: ; void ppu_write(uint8 value);
	sta $2007
	rts

_ppu_load: ; void ppu_load(uint8* data, uint16 count)
	sta ptr2+0
	stx ptr2+1 ; ptr2 = count
	jsr popptr1 ; ptr1 = data
	ldy #0
@loop:
	; dec ptr2 (quit if 0)
	lda ptr2+0
	bne :+
		lda ptr2+1
		beq @rts
		dec ptr2+1
	:
	dec ptr2+0
	; load
	lda (ptr1), Y
	sta $2007
	; inc ptr1
	inc ptr1+0
	bne :+
		inc ptr1+1
	:
	jmp @loop
@rts:
	rts

_ppu_fill: ; void ppu_fill(uint8 value, uint16 count)
	sta ptr2+0
	stx ptr2+1
	jsr popa
@loop:
	; dec ptr2 (quit if 0)
	ldx ptr2+0
	bne :+
		ldx ptr2+1
		beq @rts
		dec ptr2+1
	:
	dec ptr2+0
	; fill
	sta $2007
	jmp @loop
@rts:
	rts

_ppu_string: ; void ppu_string(char* s)
	sta ptr1+0
	stx ptr1+1
ppu_string_ptr1:
	ldy #0
	:
		lda (ptr1), Y
		beq :+
		sec
		sbc _ascii_offset
		sta $2007
		iny
		bne :-
	:
	rts

_ppu_char: ; void ppu_char(char c)
	sec
	sbc _ascii_offset
	sta $2007
	rts

_ppu_packet: ; void ppu_packet(uint16 addr, uint8* data, uint8 count)
	ldy _ppu_send_pos
	sta _ppu_send+0, Y ; count
	sta tmp1
	jsr popptr1 ; ptr1 = data
	jsr popax ; X:A = addr
	ldy tmp1
	bne :+
		rts ; count of 0, no packet
	:
	ldy _ppu_send_pos
	sta _ppu_send+2, Y ; addr low byte second
	txa
	sta _ppu_send+1, Y ; addr high byte first
	iny
	iny
	iny
	tya
	tax
	ldy #0
	:
		lda (ptr1), Y
		sta _ppu_send, X
		inx
		iny
		cpy tmp1
		bcc :-
	lda #0
	sta _ppu_send, X ; 0 marks end of packets
	stx _ppu_send_pos
	rts

_ppu_packet_reserve: ; uint8 ppu_packet_reserve(uint16 addr, uint8 count)
	; note: does not clobber tmp/ptr C temporaries
	ldy _ppu_send_pos
	sta _ppu_send+0, Y
	jsr popax
	ldy _ppu_send_pos
	sta _ppu_send+2, Y
	txa
	sta _ppu_send+1, Y
	iny
	iny
	iny ; Y = ppu_send_pos + 3 (index to data)
	tya
	clc
	adc _ppu_send-3, Y ; ppu_send_pos + 3 + count
	tax
	stx _ppu_send_pos
	lda #0
	sta _ppu_send, X ; 0 marks end of packets
	tax
	tya
	rts

_ppu_ctrl_apply: ; void ppu_control_apply(uint8 v)
	sta $2000
_ppu_ctrl: ; void ppu_ctrl(uint8 v)
	sta ppu_2000
	rts

_ppu_ctrl_get: ; uint8 ppu_ctrl_get()
	ldx #0
	lda ppu_2000
	rts

_ppu_mask_apply: ; void ppu_mask_apply(uint8 v)
	sta $2001
_ppu_mask: ; void ppu_mask(uint8 v)
	sta ppu_2001
	rts

_ppu_scroll: ; void ppu_scroll(uint16 x, uint16 y)
	sta ppu_2005+1
	txa
	asl
	sta tmp1
	jsr popax
	sta ppu_2005+0
	txa
	and #%00000001
	ora tmp1
	and #%00000011
	sta tmp1
	lda ppu_2000
	and #%11111100
	ora tmp1
	sta ppu_2000
	rts

_ppu_render_frame: ; void ppu_render_frame()
	.assert (DEBUG_FLAG_PROFILE = $80), error, "DEBUG_FLAG_PROFILE is expected in hight bit for optimization"
	bit _debug_flag
	bpl :+
		lda ppu_2001
		ora #%00000001 ; turn on greyscale and all emphasis to mark the end of frame
		sta $2001
	:
	lda #1
	sta ppu_ready
ppu_ready_wait:
	lda ppu_ready
	bne ppu_ready_wait
	rts

_ppu_wait_frame: ; void ppu_wait_frame()
	lda _nmi_count
	:
		cmp _nmi_count
		beq :-
	rts

_ppu_render_off: ; void ppu_render_off()
	lda #2
	sta ppu_ready
	jmp ppu_ready_wait

_ppu_nmi_off: ; void ppu_nmi_off()
	lda ppu_2000
	and #%01111111
	sta $2000
	rts

_ppu_nmi_on: ; void ppu_nmi_on()
	bit $2002
	:
		bit $2002
		bpl :-
	lda ppu_2000
	ora #%10000000
	sta ppu_2000
	sta $2000
	rts

; =======
; Sprites
; =======

_sprite_begin:
	lda #0
	sta oam_pos
	sta _sprite_offset ; used in replaced sprite() routine
	rts

_sprite_end:
	ldx oam_pos
	txa
	and #3
	beq :+
		rts ; 255 = completely full, treat any non-4 multiple as "full" error
	:
	lda #255
	:
		sta _oam+0, X
		inx
		inx
		inx
		inx
		bne :-
	dex
	stx oam_pos
	rts

_sprite_tile: ; void sprite_tile(uint8 t, uint8 a, uint8 x, uint8 y)
	ldx oam_pos
	cpx #255
	bne :+
		jmp incsp3
	:
	sta _oam+0, X ; X
	jsr popa
	sta _oam+3, X ; Y
	jsr popa
	sta _oam+2, X ; attribute
	jsr popa
	sta _oam+1, X ; tile
	inx
	inx
	inx
	inx
	bne :+
		dex ; 255 = mark as full
	:
	stx oam_pos
	rts

.if 0 ; replaced with customized sprite routine

_sprite: ; void sprite(uint8 e, uint8 x, uint8 y)
	sta tmp2 ; Y
	jsr popa
	sta tmp1 ; X
	lda #0
	sta tmp3 ; X eor
	sta tmp4 ; A eor
sprite_common:
	jsr popa
	tax
	lda #<sprite_data
	clc
	adc sprite_data, X
	sta ptr1+0
	lda #>sprite_data
	adc sprite_data+SPRITE_COUNT, X
	sta ptr1+1
	; ptr1 = sprite data, (tmp1,tmp2) = (X,Y)
	ldx oam_pos
	ldy #0
@loop:
	cpx #255
	beq @end
	; attribute
	lda (ptr1), Y
	beq @end ; 0 marks end of sprite
	eor tmp4
	sta _oam+2, X
	; Y
	iny
	lda (ptr1), Y
	clc
	adc tmp2
	sta _oam+0, X
	; X
	iny
	lda (ptr1), Y
	eor tmp3
	clc
	adc tmp1
	sta _oam+3, X
	; tile
	iny
	lda (ptr1), Y
	sta _oam+1, X
	; loop
	iny
	inx
	inx
	inx
	inx
	bne @loop
	ldx #255 ; OAM is full
@end:
	stx oam_pos
	rts

_sprite_flip: ; void sprite_flip(uint8 e, uint8 x, uint8 y)
	sta tmp2 ; Y
	jsr popa
	sec
	sbc #(8-1)
	sta tmp1 ; X - (8-1)
	lda #$FF
	sta tmp3 ; X eor (X^$FF = -(X+1))
	lda #%01000000
	sta tmp4 ; A eor (horizontal flip)
	jmp sprite_common

.endif

; =====
; Input
; =====

_input_poll: ; polls controller 1
	lda _input
	pha ; remember last poll value for comparison
@poll:
	ldy #1
	sty $4016 ; latch strobe
	dey
	sty $4016
	lda #$01 ; 1 bit guard marks end of 8 bit read
	sta _input
	:
		lda $4016
		and #%00000011
		cmp #%01
		rol _input
		bcc :- ; guard reached when carry set
	pla
	cmp _input
	beq @done ; last 2 polls match: done
	; mismatch = probable DPCM conflict, try again
	lda _input
	pha
	jmp @poll
@done:
	eor input_last ; changes since last poll
	and _input ; keep presses, ignore releases
	sta _input_new
	lda _input
	sta input_last ; remember last press for next time
	rts

; =======
; Utility
; =======

_nescopy: ; void nescopy(void* dst, void* src, uint8 count)
	sta tmp1
	jsr popptr1
	jsr popax
	sta ptr2+0
	stx ptr2+1
	ldy tmp1
	beq :++
:
	dey
	lda (ptr1), Y
	sta (ptr2), Y
	cpy #0
	bne :-
:
	rts

_nesset: ; void nesset(void* dst, uint8 value, uint8 count)
	sta tmp1
	jsr popa
	pha
	jsr popptr1
	pla
	ldy #0
	cpy tmp1
	bcs :++
:
	sta (ptr1), Y
	iny
	cpy tmp1
	bcc :-
:
	rts
