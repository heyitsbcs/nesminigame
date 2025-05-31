;
; minigame.s
; MINIGAME launching
;

.include "common.inc"

.export _minigame_launch

.importzp ptr1
.importzp ptr2

.import _ppu_packet_reserve

.import _input_poll
.import _ppu_wait_frame

; minigames table entry:
;   .byte BANK
;   .byte PAD ($00)
;   .word HEADER (address in bank)

; minigame header:
;   .word INIT_ADDR - call once at start
;   .word UPDATE_ADDR - call once per frame, a = key input
;   .word TILE_DATA - 256 (or fewer?) 8x8 graphics tiles
;   .word INITIAL_MAP - initial tilemap to load
;   .word DEFAULT_PAL - palettes

.segment "FIXED"

_mg_play_song:
_mg_play_sfx:
_mg_func3:
_mg_func4:
_mg_func5:
_mg_func6:
_mg_func7:
    rts

_minigame_jump_base:
    jmp _mg_play_song
    jmp _mg_play_sfx
    jmp _ppu_packet_reserve
    jmp _mg_func3
    jmp _mg_func4
    jmp _mg_func5
    jmp _mg_func6
    jmp _mg_func7

minigames:
    .byte <.BANK(TEST_MINIGAME)
    .byte $00              ; padding to keep it 4 bytes, we'll use this for flags (has tiles, has map, has sound?)
    .addr TEST_MINIGAME

_minigame_launch: ; void minigame_launch(uint8 minigame_index)
    clc
    asl a
    asl a
    tax
    PUSH_BANK
    lda minigames,x
    SET_BANK_A

; ptr1 now contains the header data
    lda minigames+2,x
    sta ptr1
    lda minigames+3,x
    sta ptr1+1

    lda $2002

    lda #$00
    sta $2000   ; nametable at $2000, inc 1 byte, sprites at $0000, pattern at $0000, 8x8 sprites, vblank disabled
    sta $2001   ; disable video
    sta ppu_2000
    sta ppu_2001
    ; reset scroll to 0,0
    sta $2005
    sta $2005
    sta ppu_2005
    sta ppu_2005+1

; copy jump table
    ldx #0
_mgjumpcopy:
    lda _minigame_jump_base,x
    sta _minigamejump,x
    inx
    cpx #24
    bne _mgjumpcopy

; clear sprites
    ldx #$00
	lda #$FF
:
    sta _oam,x
    inx
    bne :-


; setup tiles
    ldy #$04
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda $2002
    ldy #$00
    sty $2006
    sty $2006
    
    ldx #16 ; 16 256-byte chunks for 256 16-byte tiles
copytileloop:
    lda (ptr2),y
    sta $2007
    iny
    bne copytileloop
    inc ptr2+1
    dex
    bne copytileloop

; setup map
    ldy #$06
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda $2002
    lda #$20
    sta $2006
    ldy #$00
    sty $2006

    ldx #4 ; 4 256-byte chunks for 1024 byte map+palette
copymaploop:
    lda (ptr2),y
    sta $2007
    iny
    bne copymaploop
    inc ptr2+1
    dex
    bne copymaploop

; setup palette
    ldy #$08
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda $2002
    lda #$3f
    sta $2006
    ldy #$00
    sty $2006

copypalloop:
    lda (ptr2),y
    sta $2007
    sta _palette,y
    iny
    cpy #32
    bne copypalloop

; setup audio
    ldy #$0a
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda #$80
    sta $2000   ; nametable at $2000, inc 1 byte, sprites at $0000, pattern at $0000, 8x8 sprites, vblank enabled
    sta ppu_2000

	lda #%00011110
    sta $2001
    sta ppu_2001

    bit $2002
    lda #$00
    sta $2005
    sta $2005
    sta ppu_2005
    sta ppu_2005+1

    lda #$01    ; oam-only mode
    sta ppu_ready

; call minigame's init
    ldy #$00
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda ptr1
    pha
    lda ptr1+1
    pha
    jsr jmpptr2
    pla
    sta ptr1+1
    pla
    sta ptr1

minigameloop:
    lda #$01    ; oam-only mode
    sta ppu_ready
    jsr _ppu_wait_frame

; call minigame's update
    ldy #$02
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1

    lda ptr1
    pha
    lda ptr1+1
    pha

    jsr _input_poll
	lda _input
    jsr jmpptr2

    tax
    pla
    sta ptr1+1
    pla
    sta ptr1
    txa
    cmp #$00
    beq minigameloop

    RTS_POP_BANK


jmpptr2:
    jmp (ptr2)



.segment "MINIGAME1"
TEST_MINIGAME:
    .incbin "../samples/minigame.bin"
