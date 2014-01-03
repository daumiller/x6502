#include "boot/boot.h"

/*============================================================================*/

entryPoint:
  jmp $0300   ; $0000 = jmp to page 3
  .dsb $02FD  ; fill first 2 pages with zero

/*============================================================================*/

initEnvironment:
  sei            ; disable interrupts
  cld            ; disable decimal mode
  ldx #$FF : txs ; initialize stack pointer ($01FF)
initZeroPage:
  ; set ZPIO, and initialize other IO pointers to it
  lda #$00 : sta ZPIO   : sta ZPCONVID   : sta ZPBOOTDISK   : sta ZPKEYBOARD
  lda #$02 : sta ZPIO+1 : sta ZPCONVID+1 : sta ZPBOOTDISK+1 : sta ZPKEYBOARD+1

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

findConvid:
  ; iterate over IO devices
  ; find convid by it's device name
  lda #IOC_CMD_COUNT
  sta IOC_ADDR_COMMAND
  lda #0
  pha
L0000:
  pla
  cmp IOC_ADDR_REPLY
  bne L0001 : jmp halt ; 'beq halt'
L0001:
  ; addr = IO_PAGE + ((a+1)*16)
  clc : adc #1
  asl : asl : asl : asl
  tay
  lsr : lsr : lsr : lsr
  pha
  lda #IO_CMD_NAME
  sta (ZPIO),Y
  ; compare device's reported name to strConvid
  tya : clc : adc ZPIO+0  : sta ZPFUNCTION+0    ; (io addr offset won't carray)
              lda ZPIO+1  : sta ZPFUNCTION+1
  lda #<strConvid   : sta ZPFUNCTION+2
  lda #>strConvid   : sta ZPFUNCTION+3
  jsr strCmp
  lda #0 : cmp ZPFUNCTION+4 : bne L0000
foundConvid:
  ; store convid address
  pla
  asl : asl : asl : asl
  sta ZPCONVID
  lda #<strStatus0 : sta ZPFUNCTION+0
  lda #>strStatus0 : sta ZPFUNCTION+1
  jsr printString

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

findBootDisk:
  ; iterate over IO devices
  ; find first storage device with a valid boot sector
  lda #IOC_CMD_COUNT
  sta IOC_ADDR_COMMAND
  lda #0
  pha
L0002:
  pla
  cmp IOC_ADDR_REPLY
  bne L0003
  jmp noBootDisk
L0003:
  ; addr = IO_PAGE + ((a+1)*16)
  clc : adc #1
  asl : asl : asl : asl
  tay
  lsr : lsr : lsr : lsr
  pha
  ; compare class
  lda #IO_CMD_CLASS
  sta (ZPIO),Y
  lda #IO_CLASS_STORAGE
  cmp (ZPIO),Y
  bne L0002
  ; verify size (>= 256)
  lda #STOR_CMD_SIZE
  sta (ZPIO),Y
  lda #0 ; check the upper 3 bytes of size (for any non-zero)
  iny : cmp (ZPIO),Y : bne L0005
  iny : cmp (ZPIO),Y : bne L0004
  iny : cmp (ZPIO),Y : beq L0002 : dey
L0004: dey
L0005: dey
  ; read boot signature
  lda #2 : iny : sta (ZPIO),Y : dey
  lda #STOR_CMD_READ : sta (ZPIO),Y
  ; test boot signature
  lda #$55 : cmp (ZPIO),Y : bne L0002 : iny
  lda #$AA : cmp (ZPIO),Y : bne L0002 : dey
  ; store zero-page entry for BOOTDISK
  pla
  asl : asl : asl : asl
  sta ZPBOOTDISK
  ldy #0
  ; read boot block size
  ldy #1 : lda #2             : sta (ZPBOOTDISK),Y ; size - 2 bytes
  ldy #0 : lda #STOR_CMD_READ : sta (ZPBOOTDISK),Y ; cmd  - read
  ; ZPUSER[4|5] == boot block size
  ldy #0 : lda (ZPBOOTDISK),Y : sta ZPUSER+4
  ldy #1 : lda (ZPBOOTDISK),Y : sta ZPUSER+5
  ; read boot block offset
  ldy #1 : lda #2             : sta (ZPBOOTDISK),Y ; size - 2 bytes
  ldy #0 : lda #STOR_CMD_READ : sta (ZPBOOTDISK),Y ; cmd  - read
  ; seek to offset
  lda #0 ; zero 2 most-significant bytes
  ldy #3 : sta (ZPBOOTDISK),Y
  ldy #4 : sta (ZPBOOTDISK),Y
  ; shift 2 least-significant bytes
  ldy #1 : lda (ZPBOOTDISK),Y : ldy #2 : sta (ZPBOOTDISK),Y
  ldy #0 : lda (ZPBOOTDISK),Y : ldy #1 : sta (ZPBOOTDISK),Y
  ldy #0 : lda #STOR_CMD_SEEK : sta (ZPBOOTDISK),Y
  ; set ZPUSER[0|1] == boot block writing pointer
  lda #$00 : sta ZPUSER+0
  lda #$13 : sta ZPUSER+1
  ; set ZPUSER[2|3] == boot block reading pointer
  lda ZPBOOTDISK+0 : sta ZPUSER+2
  lda ZPBOOTDISK+1 : sta ZPUSER+3
  ; ZPUSER[6|7] == number of blocks wrote
  lda #0 : sta ZPUSER+6 : sta ZPUSER+7
  ; read boot blocks
L0006:
  ; (number of blocks wrote == boot block size)?
  lda ZPUSER+6 : cmp ZPUSER+4 : bne L0007
  lda ZPUSER+7 : cmp ZPUSER+5 : bne L0007
  jmp bootJump
L0007:
  lda #$10           : ldy #1 : sta (ZPBOOTDISK),Y ; size - 16 bytes
  lda #STOR_CMD_READ : ldy #0 : sta (ZPBOOTDISK),Y ; cmd  - read
  ; memcpy
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny    :    lda (ZPUSER+2),Y : sta (ZPUSER+0),Y : iny
  ; increment writing pointer
  lda ZPUSER+0 : clc : adc #16 : sta ZPUSER+0
  lda ZPUSER+1 :       adc #0  : sta ZPUSER+1
  ; increment block counter
  lda ZPUSER+6 : clc : adc #1 : sta ZPUSER+6
  lda ZPUSER+7 :       adc #0 : sta ZPUSER+7
  jmp L0006
  ; jump to boot sector
bootJump:
  lda #<strStatus3 : sta ZPFUNCTION+0
  lda #>strStatus3 : sta ZPFUNCTION+1
  jsr printString
  jmp $1300

noBootDisk:
  lda #<strStatus1 : sta ZPFUNCTION+0
  lda #>strStatus1 : sta ZPFUNCTION+1
  jsr printString
  jmp halt

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

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

strCmp:
  ; ZPFUNCTION[0|1] holds string A
  ; ZPFUNCTION[2|3] holds string B
  ; ZPFUNCTION[4] returns result (0 - equal, 1 - not equal)
  PUSHALL
  ldy #0
  lda #1 : sta ZPFUNCTION+4
strCmpLoop:
  lda (ZPFUNCTION+0),Y
  cmp (ZPFUNCTION+2),Y
  bne strCmpComplete
  iny
  cmp #0
  bne strCmpLoop
  lda #0 : sta ZPFUNCTION+4
strCmpComplete:  
  POPALL
  rts

/*============================================================================*/

halt:
  .byt $FF

strConvid:
  .asc "CONVID" : .byt $00
strStatus0:
  .asc "Searching for boot device..."  : .byt $0A : .byt $00
strStatus1:
  .asc "No valid boot device found..." : .byt $0A : .byt $00
strStatus3:
  .asc "Boot device found. Loading..." : .byt $0A : .byt $00
