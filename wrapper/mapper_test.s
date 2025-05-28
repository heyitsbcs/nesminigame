;
; performs test of mapper functionality (for emulators)
;

.include "common.inc"

.export _mapper_test

.segment "DEBUG"

_mapper_test:
	lda #0
	sta _i
	sta _j
	bit $2001 ; reset latch
	; check WRAM for read/write (i result)
	lda #$55
	jsr @test_canary
	lda #$00
	jsr @test_canary
	; write a value to PPU-space in 1k increments
	ldy #$01
	ldx #0
	:
		tya
		jsr @write_axa
		iny
		iny
		iny
		iny
		cpy #$30
		bcc :-
	; read back the values for nametables
	ldy #$21
	;ldx #0
	:
		tya
		jsr @test_axa
		iny
		iny
		iny
		iny
		cpy #$30
		bcc :-
	lda _j ; temp result
	sta _k ; nametable result
	lda #0
	sta _j ; reset temp result
	; read back the values for CHR
	ldy #$01
	;ldx #0
	:
		tya
		jsr @test_axa
		iny
		iny
		iny
		iny
		cpy #$20
		bcc :-
	; CHR result in j
	; check if failed
	lda _i
	ora _j
	ora _k
	bne :+
		;ldx #0
		rts ; X=0, A=0 (pass)
	:
	; play 2 beeps
	;ldx #0
	ldy #0
	:
		sty $4011
		jsr @wait
		stx $4011
		jsr @wait
		dey
		bne :-
	rts ; X=0, A=non-zero
@wait: ; ~1540 cycles to generate beep waveform
	jsr :+
:
	jsr :+
:
	jsr :+
:
	jsr :+
:
	jsr :+
:
	jsr :+
:
	jsr :+
:
	rts
@test_canary:
	sta canary
	cmp canary
	beq :+
		inc _i
	rts
@write_axa:
	sta $2006
	stx $2006
	sta $2007
	rts
@test_axa:
	sta $2006
	stx $2006
	bit $2007
	cmp $2007
	beq :+
		inc _j
	:
	rts
