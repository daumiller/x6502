#include "boot/boot.h"

/*============================================================================*/
entryPoint:
  lda #<strHello : sta ZPFUNCTION+0
  lda #>strHello : sta ZPFUNCTION+1
  jsr printString

halt:
  .byt $FF

/*============================================================================*/
printString:
  ; ZPFUNCTION[0|1] holds string location
  ; ZPCONVID        must be set
  PUSHALL
  ldy #0
printStringLoop:
  lda (ZPFUNCTION),Y
  cmp #0 : beq printStringComplete
  iny : tax : tya : pha : txa ; increment y + push y (preserving a)
  ldy #1 : sta (ZPCONVID),Y                        ; write character
  ldy #0 : lda #CONVID_CMD_PUTC : sta (ZPCONVID),Y ; write command
  pla : tay
  jmp printStringLoop:
printStringComplete:
  POPALL
  rts

/*============================================================================*/
strHello: .asc "Hello 6502!" : .byt $0A : .byt $00
