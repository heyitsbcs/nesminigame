CSTACK_SIZE = 64

.include "ram.inc"

.global _prg_bankswitch
.global _trampoline
.global pla_jmp_bankswitch
.importzp tmp4, ptr4

; Bankswitching macros
;
; Use these instead of _prg_bankswitch directly, as they are able to do some safety checks.
;
; Favour RTS_POP_BANK_RTS over RETURN_POP_BANK by default unless inside an important loop.
; Use JSR/JMP_FIXED for calls where we need to ensure the target is FIXED (e.g. call to another file).
;
;   PUSH_BANK pushes the current bank to the stack (clobbers A)
;   POP_BANK pops the bank from the stack and sets it (clobbers A,Y)
;   RETURN_POP_BANK pops the bank then returns (clobbers A,Y)
;   RTS_POP_BANK also returns but is 1 byte smaller code, 5 cycles slower (clobbers A,Y)
;   SET_BANK switches to the bank of an address (clobbers A,Y)
;   SET_BANK_A switches the bank to A (clobbers Y)
;	RTS_BANK_A is a tail call version of SET_BANK_A (clobbers Y)
;   BANKED_CALL/JUMP is a full banked C call/jump, preserving A,X,Y (clobbers tmp1, tmp2, tmp4, ptr4)
;   JSR_BANK/JMP_BANK is an efficient banked jsr/jmp from the fixed bank only (clobbers A,Y)
;   JSR_FIXED/JMP_FIXED is jsr/jmp with a safety check that the target is in the fixed bank

.macro PUSH_BANK ; push last_prg_bank (clobbers A)
	lda last_prg_bank
	pha
.endmacro

.macro POP_BANK ; return to last_prg_bank (clobbers A,Y)
	.assert .bank(*)=.bank(_prg_bankswitch), error, "POP_BANK only allowed from FIXED"
	pla
	jsr _prg_bankswitch
.endmacro

.macro RETURN_POP_BANK ; pop and jmp to bankswitch (clobbers A,Y)
	pla
	jmp _prg_bankswitch
.endmacro

.macro RTS_POP_BANK ; RTS_POP_BANK_RETURN but saves 1 byte of code, losing 5 cycles (clobbers A,Y)
	jmp pla_jmp_bankswitch
.endmacro

.macro SET_BANK func__ ; set to bank of func__ (clobbers A,Y)
	.assert .bank(*)=.bank(_prg_bankswitch), error, "SET_BANK only allowed from FIXED"
	.assert .bank(func__)<>.bank(_prg_bankswitch), warning, "SET_BANK used on FIXED label?"
	lda #<.bank(func__)
	jsr _prg_bankswitch
.endmacro

.macro SET_BANK_A ; sets bank to A (clobbers Y)
	.assert .bank(*)=.bank(_prg_bankswitch), error, "SET_BANK_A not from FIXED"
	jsr _prg_bankswitch
.endmacro

.macro RTS_BANK_A ; a tail-call version of SET_BANK_A (clobbers Y)
	jmp _prg_bankswitch
.endmacro

.macro BANKED_CALL func__ ; assembly version of trampoline call (clobbers tmp1, tmp2, tmp4, ptr4)
	.assert .bank(func__)<>.bank(_prg_bankswitch), warning, "BANKED_CALL used on FIXED label?"
	pha
	lda #<.bank(func__)
	sta tmp4
	lda #<(func__)
	sta ptr4+0
	lda #>(func__)
	sta ptr4+1
	pla
	jsr _trampoline
.endmacro

.macro BANKED_JUMP func__ ; assembly version of trampoline tail call (clobbers tmp1, tmp2, tmp4, ptr4)
	.assert .bank(func__)<>.bank(_prg_bankswitch), warning, "BANKED_JUMP used on FIXED label?"
	pha
	lda #<.bank(func__)
	sta tmp4
	lda #<(func__)
	sta ptr4+0
	lda #>(func__)
	sta ptr4+1
	pla
	jmp _trampoline
.endmacro

.macro JSR_BANK func__ ; lightweight banked call from fixed (clobbers A,Y)
	.assert .bank(*)=.bank(_prg_bankswitch), error, "JSR_BANK not from FIXED"
	.assert .bank(func__)<>.bank(_prg_bankswitch), warning, "JSR_BANK used on FIXED label?"
	lda #<.bank(func__)
	jsr _prg_bankswitch
	jsr func__
.endmacro

.macro JMP_BANK func__ ; lightweight banked jump from fixed (clobbers A,Y)
	.assert .bank(*)=.bank(_prg_bankswitch), error, "JMP_BANK not from FIXED"
	.assert .bank(func__)<>.bank(_prg_bankswitch), warning, "JMP_BANK used on FIXED label?"
	lda #<.bank(func__)
	jsr _prg_bankswitch
	jmp func__
.endmacro

.macro JSR_FIXED func__ 
	.assert .bank(func__)=.bank(_prg_bankswitch), error, "JSR_FIXED not to FIXED"
	jsr func__
.endmacro

.macro JMP_FIXED func__
	.assert .bank(func__)=.bank(_prg_bankswitch), error, "JMP_FIXED not to FIXED"
	jmp func__
.endmacro
