;
; reset routine
; mapper setup
; bankswitch routine
; cc65 C startup
; ROM header
;

RAM_EXPORT = 1
.include "common.inc"

.export _soft_reset
.export _prg_bankswitch ; A = bank, clobbers A,Y (main thread)
.export pla_jmp_bankswitch
.export irq_prg_bankswitch ; A = bank, clobbers A,Y (irq threads)
.export irq_prg_bank_restore ; clobbers A,Y (irq threads)
.export _mapper_number
.export __STARTUP__: absolute = 1 ; identify this as startup module for cc65

.import nmi
.import debug_crash

.import _main
.importzp sp ; cc65 C stack pinter

; the only mapper features needed are
; 16k PRG banking at $8000
;  8k CHR-RAM
;  8k PRG-RAM at $6000 (battery save)
;  4-screen nametables
; MMC3 can support this, but UxROM can do it with simpler hardware
; (just change this number to switch)

;MAPPER = 4 ; MMC3
MAPPER = 2 ; UxROM

.segment "STARTUP"
reset:
	sei
	lda #0
	sta $2000 ; disable NMI
	.if MAPPER = 4
		sta $8000 ; MMC3 $C000-FFFF now fixed bank
	.endif
	jmp init

.segment "FIXED"
init:
	; A = 0, NMI off, MMC3 fixed bank
	sta $2001 ; rendering off
	sta $4010 ; disable DMC IRQ
	sta $4015 ; disable APU sound
	.if MAPPER = 4
		sta $E000 ; disable MMC3 IRQ
		sta $A000 ; reset MMC3 mirroring
		lda #$80
		sta $A001  ; enable MMC3 WRAM
	.endif
	lda #$40
	sta $4017 ; disable APU IRQ
	cld       ; disable decimal mode
	ldx #$FF
	txs       ; setup stack
	; wait for vblank #1
	bit $2002
	:
		bit $2002
		bpl :-
	.if MAPPER = 4
		; initialize MMC3 registers
		ldx #0
		stx last_prg_bank
		:
			stx $8000 ; select register
			lda mmc3_register_init, X
			sta $8001 ; write register
			inx
			cpx #8
			bcc :-
	.endif
	; clear RAM
	lda #0
	tax
	:
		sta $0000, X
		sta $0100, X
		sta $0200, X
		sta $0300, X
		sta $0400, X
		sta $0500, X
		sta $0600, X
		sta $0700, X
		inx
		bne :-
	; clear OAM
	lda #$FF
	:
		sta _oam, X
		inx
		bne :-
	; wait for vblank #2
	:
		bit $2002
		bpl :-
	; initialize internal variables
	; TODO initialize sound
	; TODO initialize non-save part of WRAM?
	lda #%00011110
	sta ppu_2001
	lda #%10001000
	sta ppu_2000
	sta $2000
	; initialize cc65 and enter main()
	lda #<(cstack + CSTACK_SIZE)
	sta sp+0
	lda #>(cstack + CSTACK_SIZE)
	sta sp+1
	jsr _main
_soft_reset:
	jmp ($FFFC)

.if MAPPER = 4

mmc3_register_init:
.byte $00 ; 2k CHR $0000
.byte $02 ; 2k CHR $0800
.byte $04 ; 1k CHR $1000
.byte $05 ; 1k CHR $1500
.byte $06 ; 1k CHR $1800
.byte $07 ; 1k CHR $1C00
.byte $00 ; 4k PRG $8000
.byte $01 ; 4k PRG $A000

_prg_bankswitch: ; A = bank, A,Y = clobbered
	sta last_prg_bank ; store in case NMI interrupts
@retry:
	ldy #1
	sty prg_bankswitch_active ; switch in progress
	asl
	ldy #6
	sty $8000
	sta $8001
	iny
	ora #1
	sty $8000
	sta $8001
	dec prg_bankswitch_active ; returns to 0 if uninterrupted, but -1 if interrupted
	bne @interrupted
	rts
@interrupted:
	lda last_prg_bank
	jmp @retry

irq_prg_bank_restore: ; restore main thread bank after switching in IRQ
	lda prg_bankswitch_active
	beq :+
		dec prg_bankswitch_active ; bankswitch in progress, set it to 0 to indicate interruption
	:
	lda last_prg_bank
irq_prg_bankswitch: ; bankswitch during IRQ
	asl
	ldy #6
	sty $8000
	sta $8001
	iny
	ora #1
	sty $8000
	sta $8001
	rts

.elseif MAPPER = 2

irq_prg_bank_restore:
	lda last_prg_bank
_prg_bankswitch: ; A = bank, A,Y = clobbered
	sta last_prg_bank
irq_prg_bankswitch:
	tay
	sta uxrom_table, Y
	rts

uxrom_table:
	.repeat 32,I
		.byte I
	.endrepeat

.endif

pla_jmp_bankswitch:
	pla
	jmp _prg_bankswitch

irq:
	pha
	lda #0
	sta $2000 ; disable NMI
	txa
	pha
	tya
	pha
	lda last_prg_bank
	pha
	; Stack: [IRQ],A,X,Y,bank
:
	jmp :-

.segment "DEBUG"
_mapper_number:
	.byte '0' + MAPPER, 0

; =======
; NES ROM
; =======

.segment "HEADER"

INES_MAPPER     = MAPPER
INES_MIRROR     = 8 ; 4-screen nametables
INES_PRG_16K    = 16 ; 256KB
INES_CHR_8K     = 0 ; 8k CHR-RAM
INES_BATTERY    = 1 ; 8k battery WRAM
INES2           = %00001000 ; NES 2.0 flag for bit 7
INES2_SUBMAPPER = 0
INES2_PRGRAM    = 0
INES2_PRGBAT    = 7 ; 8k battery WRAM
INES2_CHRRAM    = 7 ; 8k CHR-RAM
INES2_CHRBAT    = 0
INES2_REGION    = 2 ; 0=NTSC, 1=PAL, 2=Dual

; iNES 1 header
.byte 'N', 'E', 'S', $1A ; ID
.byte <INES_PRG_16K
.byte INES_CHR_8K
.byte INES_MIRROR | (INES_BATTERY << 1) | ((INES_MAPPER & $f) << 4)
.byte (<INES_MAPPER & %11110000) | INES2
; iNES 2 section
.byte (INES2_SUBMAPPER << 4) | (INES_MAPPER>>8)
.byte ((INES_CHR_8K >> 8) << 4) | (INES_PRG_16K >> 8)
.byte (INES2_PRGBAT << 4) | INES2_PRGRAM
.byte (INES2_CHRBAT << 4) | INES2_CHRRAM
.byte INES2_REGION
.byte $00 ; VS system
.byte $00, $00 ; padding/reserved
.assert * = 16, error, "NES header must be 16 bytes."

.segment "VECTORS"
.word nmi
.word reset
.word irq

; end of file
