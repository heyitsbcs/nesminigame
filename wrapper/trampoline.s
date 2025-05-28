; cc65 wrapped call trampoline

.include "common.inc"

.export _trampoline

.importzp tmp1
.importzp tmp2
.importzp tmp4
.importzp ptr4

.segment "FIXED"

_trampoline:
	; preserve A/Y
	sta tmp1
	sty tmp2
	; remember current bank
	PUSH_BANK
	; bankswitch
	lda tmp4
	SET_BANK_A
	; call function
	lda tmp1
	ldy tmp2
	jsr @call
	; restore original bank
	sta tmp1
	sty tmp2
	POP_BANK
	lda tmp1
	ldy tmp2
	rts
@call:
	jmp (ptr4)
