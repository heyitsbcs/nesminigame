;
; nmi handler
;

.include "common.inc"

.export nmi
.export _ppu_packet_apply
.import irq_prg_bankswitch
.import irq_prg_bank_restore
.import famistudio_update

.segment "FIXED"

; ===
; NMI
; ===

nmi:
	inc _nmi_count
	pha
	lda nmi_lock
	beq :+
		pla
		rti
	:
	lda #$FF
	sta nmi_lock ; prevent re-entry
	txa
	pha
	tya
	pha
	lda ppu_ready
	beq @post_send ; 0 = no update
	cmp #4	  ; 4 = only send OAM data
	beq @oamonly
	cmp #2 
	bcc @send ; 2 = render off
	lda ppu_2001
	and #%11100001
	sta $2001
	lda #0
	sta _ppu_on ; remember off
	sta _ppu_send_pos ; cancel any unsent update
	sta _ppu_send+0
	jmp @post_send

@oamonly:
	; OAM
	ldx #0
	stx $2003
	lda #>_oam
	sta $4014
	jmp @post_send

@send: ; 1 = send ppu data
	; OAM
	ldx #0
	stx $2003
	lda #>_oam
	sta $4014
	; palettes
	;ldx #0
	stx $2000 ; set horizontal increment
	bit $2002
	lda #>$3F00
	sta $2006
	;ldx #<$3F00
	stx $2006
	;ldx #0
	lda _palette+0
	sta $2007 ; shared background colour
	ldx #0
	:
		lda _palette+1, X
		sta $2007
		lda _palette+2, X
		sta $2007
		lda _palette+3, X
		sta $2007
		lda $2007 ; skip shared colour
		inx
		inx
		inx
		inx
		cpx #32
		bcc :-
	; upload _ppu_send
	jsr nmi_ppu_packet_apply
	; set scroll and mask
	lda ppu_2000
	sta $2000
	lda ppu_2005+0
	sta $2005
	lda ppu_2005+1
	sta $2005
	lda ppu_2001
	sta $2001
	sta _ppu_on
@post_send:
	lda #<.bank(famistudio_update)
	jsr irq_prg_bankswitch
	; jsr famistudio_update
	; TODO status bar
	; restore bank
	jsr irq_prg_bank_restore
	lda #0
	sta ppu_ready
	sta nmi_lock
	pla
	tay
	pla
	tax
	pla
	rti

; applies all packets stored in _ppu_send (nmi_thread only)
.proc nmi_ppu_packet_apply
	; set $2000 to requested state
	lda ppu_2000
	sta $2000
	; move _ppu_send address to stack
	.assert (>_ppu_send = $01), error, "_ppu_send expected on stack page."
	tsx
	stx nmi_temp ; save stack position
	ldx #<(_ppu_send-1)
	txs
send_packet:
	; first byte of packet = count
	pla
	beq send_finish ; 0 = done
	tax
	pla
	sta $2006
	pla
	sta $2006
	cpx #30
	beq send_30 ; special case for packet of 30
	txa
	and #7
	beq send_8
	; 1-7 bytes individually
	tay
	:
		pla
		sta $2007
		dey
		bne :-
send_8: ; 8 bytes at a time
	txa
	lsr
	lsr
	lsr
	beq send_packet
	tax
send_8x:
	:
		.repeat 8
			pla
			sta $2007
		.endrepeat
		dex
		bne :-
	beq send_packet
send_finish:
	; restore stack
	ldx nmi_temp
	txs
ppu_apply_finish:
	lda #0
	sta _ppu_send ; clear packet
	sta _ppu_send_pos
	rts
send_30:
	.repeat 6
		pla
		sta $2007
	.endrepeat
	ldx #24/8
	jmp send_8x
.endproc

_ppu_packet_apply: ; void ppu_packet_apply()
	; set $2000 to requested state
	lda ppu_2000
	sta $2000
	; send packets
	ldx #0
@send_packet:
	lda _ppu_send, X
	beq nmi_ppu_packet_apply::ppu_apply_finish
	tay
	inx
	lda _ppu_send, X
	inx
	sta $2006
	lda _ppu_send, X
	inx
	sta $2006
	:
		lda _ppu_send, X
		inx
		sta $2007
		dey
		bne :-
	beq @send_packet ; branch always
