.include "../minigame.inc"

.export asample_init
.export asample_update

.import ppu_send_pos

.segment "RAM"
Temp: .res 1
PaddleX: .res 1
PaddleY: .res 1
BallX: .res 1
BallY: .res 1
BallVX: .res 1
BallVY: .res 1
PPUPacketAt: .res 1
Input: .res 1
ColX: .res 1
ColY: .res 1

Collision: .res 16*14

.segment "MINIGAME"

asample_init:
    lda #128
    sta BallX
    sta PaddleX
    lda #192
    sta BallY
    lda #216
    sta PaddleY

    lda #1
    sta BallVX
    sta BallVY

    ldx #0
colcopyloop:
    lda COLLISIONMAP,x
    sta Collision,x
    inx
    cpx #224
    bne colcopyloop
    rts


asample_update:
    sta Input

    jsr updateinput
    jsr updateball
    jsr updatesprites

    lda #0
    rts

updatesprites:
    SPRITE 0, BallX, BallY, #2, #0
    lda PaddleX
    clc
    adc #8
    sta Temp
    SPRITE 1, PaddleX, PaddleY, #3, #0
    SPRITE 2, Temp, PaddleY, #4, #0
    rts

updateinput:
checkleft:
    lda Input
    and #PAD_L
    beq checkright
    lda PaddleX
    cmp #17
    bcc checkright
    sec
    sbc #1
    sta PaddleX

checkright:
    lda Input
    and #PAD_R
    beq donechecks
    lda PaddleX
    cmp #224
    bcs donechecks
    clc
    adc #1
    sta PaddleX

donechecks:
    rts

updateball:
    lda BallX
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda BallY
    lsr a
    lsr a
    lsr a
    lsr a
    tay

    ; first we'll update left/right
    lda BallVX
    and #$80    ; is it negative?
    bne ballleft

ballright:
    inc BallX
    lda BallX
    and #$07
    cmp #$07
    bne updatebally

    lda BallX
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    inx ; check 1 to the right
    lda #0
    jsr colcheck
    bcc updatebally
    lda #$ff
    sta BallVX
    jmp updatebally

ballleft:
    dec BallX
    lda BallX
    and #$0f
    cmp #$00
    bne updatebally

    lda BallX
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    dex ; check 1 to the left
    lda #0
    jsr colcheck
    bcc updatebally
    lda #01
    sta BallVX

updatebally:
    lda BallX
    lsr a
    lsr a
    lsr a
    lsr a
    tax

    lda BallVY
    and #$80    ; is it negative?
    bne ballup

    inc BallY
    lda BallY
    and #$07
    cmp #$07
    bne doneball

    lda BallY
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    iny ; check 1 below
    lda #1
    jsr colcheck
    bcc doneball
    lda #$ff
    sta BallVY
    jmp doneball

ballup:
    dec BallY
    lda BallY
    and #$0f
    cmp #$00
    bne doneball

    lda BallY
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    dey ; check 1 above
    lda #0
    jsr colcheck
    bcc doneball
    lda #01
    sta BallVY

doneball:
    rts

; Does a collision check, X,Y as tile positions, A is 0 if we ignore paddle
; returns carry set if collision, clear if not
colcheck:
    stx ColX
    sty ColY
    cmp #1
    bne colcheckmap
    lda BallY
    clc
    adc #15
    cmp PaddleY
    bcc colcheckmap
    lda BallX
    clc
    adc #7
    cmp PaddleX
    bcc colcheckmap
    lda PaddleX
    clc
    adc #15
    sta Temp
    lda BallX
    cmp Temp
    bcs colcheckmap

    sec
    rts


colcheckmap:
    lda ColY
    asl a
    asl a
    asl a
    asl a
    sta Temp
    lda ColX
    clc
    adc Temp
    tax
    lda Collision,x
    cmp #00
    beq colclear
    sec
    rts
colclear:
    clc
    rts



COLLISIONMAP:
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
