; minigame header:
;   .word INIT_ADDR - call once at start
;   .word UPDATE_ADDR - call once per frame, a = key input, see below for bit definitions
;   .word TILE_DATA - 256 (or fewer?) 8x8 graphics tiles
;   .word INITIAL_MAP - initial tilemap to load
;   .word DEFAULT_PAL - palettes

; Input definitions
PAD_A       = $80
PAD_B       = $40
PAD_SELECT  = $20
PAD_START   = $10
PAD_U       = $08
PAD_D       = $04
PAD_L       = $02
PAD_R       = $01

.importzp sp

MINIGAME_ZP = $C0   ; 48-bytes from $C0-$EF to be used freely by minigames - largely used already if using CC65

; RAM areas
OAM             = $0200 ; 256-byte OAM buffer, DMA'd to PPU in NMI interrupt
MINIGAME_RAM    = $0300 ; 256-bytes of available ram for minigames

.macro SPRITE spr, sx, sy, tile, flags
    lda sy
    sta OAM+(spr<<2)
    lda tile
    sta OAM+1+(spr<<2)
    lda flags
    sta OAM+2+(spr<<2)
    lda sx
    sta OAM+3+(spr<<2)
.endmacro