#include "boot/boot.h"

; Boot Signature
.byt $55
.byt $AA

; Boot Block Size (in 16-byte blocks)
.byt $3F
.byt $00

; Boot Block Offset (in bytes)
.byt $10
.byt $00

; Padding
.dsb $A

; Boot Code
  ldy #1 : lda #$55 : sta (ZPCONVID),Y ; 'U'
  ldy #0 : lda #$10 : sta (ZPCONVID),Y
  ldy #1 : lda #$50 : sta (ZPCONVID),Y ; 'P'
  ldy #0 : lda #$10 : sta (ZPCONVID),Y
  ldy #1 : lda #$21 : sta (ZPCONVID),Y ; '!'
  ldy #0 : lda #$10 : sta (ZPCONVID),Y
  ldy #1 : lda #$0A : sta (ZPCONVID),Y ; '\n'
  ldy #0 : lda #$10 : sta (ZPCONVID),Y
halt:
  .byt $FF

; Padding
padEnd:
  .dsb (1024-padEnd)
