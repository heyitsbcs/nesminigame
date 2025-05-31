; ram.inc
; global RAM reservations
;
; in one file define RAM_EXPORT and include this file to produce the reservations,
; otherwise include this file to import all RAM labels.

.macro RESZP label, size
	.if .defined(RAM_EXPORT)
		label: .res size
		.exportzp label
	.else
		.importzp label
	.endif
.endmacro

.macro RES label, size
	.if .defined(RAM_EXPORT)
		label: .res size
		.export label
	.else
		.import label
	.endif
.endmacro

.struct uint8xy
	_x .byte
	_y .byte
.endstruct
; if passed or returned in registers to C code:
;   X = _y
;   A = _x

.segment "ZEROPGWR"
RESZP last_prg_bank, 1 ; last used PRG bank (outside of NMI)
RESZP prg_bankswitch_active, 1 ; guard for IRQ interference with bankswitching

; cnes variables
RESZP ppu_ready, 1
RESZP _nmi_count, 1
RESZP nmi_lock, 1
RESZP ppu_2000, 1
RESZP ppu_2001, 1
RESZP ppu_2005, 2
RESZP _ppu_send_pos, 1
RESZP oam_pos, 1
RESZP input_last, 1
RESZP _input, 1
RESZP _input_new, 1
RESZP _ascii_offset, 1
RESZP _i, 1
RESZP _j, 1
RESZP _k, 1
RESZP _l, 1
RESZP _mx, 2
RESZP _nx, 2
RESZP _ox, 2
RESZP _px, 2

RESZP _ppu_on, 1
RESZP _temp_ptrw, 2
RESZP _xy, .sizeof(uint8xy)

RESZP _sprite_offset, 1

RESZP nmi_temp, 1 ; temporary variable for NMI thread

; debug
RESZP _debug_flag, 1

DEBUG_FLAG_PROFILE = $80

; bottom of stack used for PPU data
.segment "STACK"
RES _ppu_send, 133 ; accomodate at least 4 x 30-byte packets, or 1 x 128-byte
RES ppu_send_stop, 1 ; breakpoint this for protection
RES _palette, 32
RES stack_stop, 1 ; breakpoint this for protection

.segment "OAM"
RES _oam, 256

; BSS used for C-only variables
.segment "BSS"
RES cstack, CSTACK_SIZE

; RAM used for assembly-accessible variables
.segment "RAM"

RES _scratch, 256

RES _minigamejump, 24

; WRAM used for save and other bulk memory
.segment "WRAM"

RES canary, 1 ; for testing WRAM function
RES crc, 4 ; CRC to validate saved game data
