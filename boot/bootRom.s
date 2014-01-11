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
  ; find first storage device with a bootable fat16 filesystem
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
  ; verify size (>= 512)
  lda #STOR_CMD_SIZE
  sta (ZPIO),Y
  ; check the upper 3 bytes of size
  iny : iny : iny : lda #0 : cmp (ZPIO),Y : bne L0004 ; (size & 0xFF000000) >  0
  dey :             lda #0 : cmp (ZPIO),Y : bne L0005 ; (size & 0x00FF0000) >  0
  dey :             lda #2 : cmp (ZPIO),Y : bcs L0006 ; (size & 0x0000FF00) >= 2
  jmp L0002
L0004: dey
L0005: dey
L0006: dey
  ; seek to boot signature offset (510)
  iny : iny : iny : iny : lda #$00           : sta (ZPIO),Y
  dey :                   lda #$00           : sta (ZPIO),Y
  dey :                   lda #$01           : sta (ZPIO),Y
  dey :                   lda #$FE           : sta (ZPIO),Y
  dey :                   lda #STOR_CMD_SEEK : sta (ZPIO),Y
  ; read boot signature (2 bytes)
  iny : lda #2             : sta (ZPIO),Y
  dey : lda #STOR_CMD_READ : sta (ZPIO),Y
  ; test boot signature
  lda #$55 : cmp (ZPIO),Y : bne L0002 : iny
  lda #$AA : cmp (ZPIO),Y : bne L0002 : dey
  ; store zero-page entry for BOOTDISK
  pla
  asl : asl : asl : asl
  sta ZPBOOTDISK
  ldy #0

#define STOR_SEEK(disk,a,b,c,d)   \
  ldy #1 : lda a : sta (disk),Y : \
  ldy #2 : lda b : sta (disk),Y : \
  ldy #3 : lda c : sta (disk),Y : \
  ldy #4 : lda d : sta (disk),Y : \
  ldy #0 : lda #STOR_CMD_SEEK : sta (disk),Y
#define STOR_SEEK_ADDR(disk,zp)              \
  ldy #0 : lda (zp),Y : iny : sta (disk),Y : \
           lda (zp),Y : iny : sta (disk),Y : \
           lda (zp),Y : iny : sta (disk),Y : \
           lda (zp),Y : iny : sta (disk),Y : \
  ldy #0 : lda #STOR_CMD_SEEK : sta (disk),Y
#define STOR_READ(disk,a)         \
  ldy #1 : lda a : sta (disk),Y : \
  ldy #0 : lda #STOR_CMD_READ : sta (disk),Y
#define ZPASSIGN(addr,zp) \
  lda #<addr : sta zp   : \
  lda #>addr : sta zp+1
#define FATSTORE(disk,zp)              \
  ldy #0 : lda (disk),Y : sta (zp),Y : \
  ldy #1 : lda (disk),Y : sta (zp),Y : \
  ldy #2 : lda #$00     : sta (zp),Y : \
  ldy #3 : lda #$00     : sta (zp),Y
#define CPZP(a,b)   \
  lda a   : sta b : \
  lda a+1 : sta b+1
#define CPLONG(a,b)               \
  ldy #0 : lda (a),Y : sta(b),Y : \
  ldy #1 : lda (a),Y : sta(b),Y : \
  ldy #2 : lda (a),Y : sta(b),Y : \
  ldy #3 : lda (a),Y : sta(b),Y

  /* bytesPerSector    -- addr:0x0B size:2 -> ZPUSER+0  -> 0x8000 */
  STOR_SEEK(ZPBOOTDISK, #$0B, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$02)
  ZPASSIGN($8000, ZPUSER+0)
  FATSTORE(ZPBOOTDISK, ZPUSER+0)
  /* sectorsReserved   -- addr:0x0E size:2 -> ZPUSER+2  -> 0x8004 */
  STOR_SEEK(ZPBOOTDISK, #$0E, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$02)
  ZPASSIGN($8004, ZPUSER+2)
  FATSTORE(ZPBOOTDISK, ZPUSER+2)
  /* tableCount        -- addr0x10 size:1 -> ZPUSER+4  -> 0x8008 */
  STOR_SEEK(ZPBOOTDISK, #$10, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$01)
  ZPASSIGN($8008, ZPUSER+4)
  FATSTORE(ZPBOOTDISK, ZPUSER+4)
  ldy #1 : lda #$00 : sta (ZPUSER+6),y ; was only a u8 (not u16)
  /* rootCount         -- addr:0x11 size:2 -> ZPUSER+6  -> 0x800C */
  STOR_SEEK(ZPBOOTDISK, #$11, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$02)
  ZPASSIGN($800C, ZPUSER+6)
  FATSTORE(ZPBOOTDISK, ZPUSER+6)
  /* sectorsPerFAT     -- addr:0x16 size:2 -> ZPUSER+8 -> 0x8010 */
  STOR_SEEK(ZPBOOTDISK, #$16, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$02)
  ZPASSIGN($8010, ZPUSER+8)
  FATSTORE(ZPBOOTDISK, ZPUSER+8)
  /* sectorsPerCluster -- addr:0x0D size:1 -> ZPUSER+10 -> 0x8014 */
  STOR_SEEK(ZPBOOTDISK, #$0D, #$00, #$00, #$00)
  STOR_READ(ZPBOOTDISK, #$01)
  ZPASSIGN($8014, ZPUSER+10)
  FATSTORE(ZPBOOTDISK, ZPUSER+10)
  ldy #1 : lda #$00 : sta (ZPUSER+10),y ; was only a u8 (not u16)

  /* bytesRoot = (rootCount *= 32) */
  CPZP(ZPUSER+6, ZPFUNCTION+0)
  lda #$20     : sta $8018
  lda #$00     : sta $8019
  lda #$00     : sta $801A
  lda #$00     : sta $801B
  ZPASSIGN($8018, ZPFUNCTION+2)
  jsr u32mulBy

  ; zpBootTable = bytesSector * sectorsReserved
  ZPASSIGN((ZPBOOTTABLE+2), ZPBOOTTABLE)
  CPLONG(ZPUSER+0, ZPBOOTTABLE)
  CPZP(ZPBOOTTABLE, ZPFUNCTION+0)
  CPZP(ZPUSER+2  , ZPFUNCTION+2)
  jsr u32mulBy

  ; zpBootRoot = (sectorsReserved + (sectorsPerFAT * tableCount)) * bytesSector
  ZPASSIGN((ZPBOOTROOT+2), ZPBOOTROOT)
  CPLONG(ZPUSER+8, ZPBOOTROOT)  ;   sectorsPerFAT
  CPZP(ZPBOOTROOT, ZPFUNCTION+0)
  CPZP(ZPUSER+4, ZPFUNCTION+2)  ;   tableCount
  jsr u32mulBy                  ; (sectorsPerFAT * tableCount)
  CPZP(ZPUSER+2, ZPFUNCTION+2)  ;   sectorsReserved
  jsr u32addTo                  ; (sectorsReserved + (sectorsPerFAT * tableCount))
  CPZP(ZPUSER+0, ZPFUNCTION+2)  ;   bytesSector
  jsr u32mulBy                  ; (sectorsReserved + (sectorsPerFAT * tableCount)) * bytesSector

  ; zpBootData = (zpBootRoot + bytesRoot)
  ZPASSIGN((ZPBOOTDATA+2), ZPBOOTDATA)
  CPLONG(ZPBOOTROOT, ZPBOOTDATA)
  CPZP(ZPBOOTDATA, ZPFUNCTION+0)
  CPZP(ZPUSER+6  , ZPFUNCTION+2)
  jsr u32addTo

  ; zpBootClSz = (byteSector * sectorsPerCluster)
  ZPASSIGN((ZPBOOTCLSZ+2), ZPBOOTCLSZ)
  CPLONG(ZPUSER+0, ZPBOOTCLSZ)
  CPZP(ZPBOOTCLSZ, ZPFUNCTION+0)
  CPZP(ZPUSER+10 , ZPFUNCTION+2)
  jsr u32mulBy

  ; seek to offset root
  STOR_SEEK_ADDR(ZPBOOTDISK, ZPBOOTROOT)

  ; read root entries, looking for bootImage
  ZPASSIGN($8000, ZPUSER+0)
  ZPASSIGN($8010, ZPUSER+2)
rootList: ; read 32 byte entry
  STOR_READ(ZPBOOTDISK, #$10)
  CPZP(ZPBOOTDISK, ZPFUNCTION+0)
  CPZP(ZPUSER+0, ZPFUNCTION+2)
  lda #$10 : sta ZPFUNCTION+4 : lda #$00 : sta ZPFUNCTION+5
  jsr memCpy
  STOR_READ(ZPBOOTDISK, #$10)
  CPZP(ZPBOOTDISK, ZPFUNCTION+0)
  CPZP(ZPUSER+2, ZPFUNCTION+2)
  lda #$10 : sta ZPFUNCTION+4 : lda #$00 : sta ZPFUNCTION+5
  jsr memCpy
  ldy #0
  lda #$00 : cmp (ZPUSER+0),Y : bne L0007 : jmp noBootImage ; NULL/final entry (give up)
L0007:
  lda #$E5 : cmp (ZPUSER+0),Y : beq rootList                ; deleted entry (ignore)
  ldy #11
  lda (ZPUSER+0),Y : and #$0F : cmp #$0F : beq rootList     ; long file name entry (ignore)
  ; compare name
  lda #<strBootImg : sta ZPFUNCTION+0
  lda #>strBootImg : sta ZPFUNCTION+1
  CPZP(ZPUSER+0, ZPFUNCTION+2)
  lda #11 : sta ZPFUNCTION+4
  jsr strNCmp
  lda #0 : cmp ZPFUNCTION+5 : beq LRANGE0 : jmp rootList : LRANGE0: ; is this our "boot.img" file?
  ; get file size (maximum allowed = 27904 == 0x00006D00)
  ldy #15 : lda #$00 : cmp (ZPUSER+2),Y : beq L0008 : jmp bootImageLarge : L0008:
  ldy #14 : lda #$00 : cmp (ZPUSER+2),Y : beq L0009 : jmp bootImageLarge : L0009:
  ldy #13 : lda #$6D : cmp (ZPUSER+2),Y : bcs sizeOkay : beq L000A : jmp bootImageLarge : L000A:
  ldy #12 : lda #$00 : cmp (ZPUSER+2),Y : beq sizeOkay : jmp bootImageLarge
sizeOkay:
  ; 8000 = clusterCurr
  ldy #10 : lda (ZPUSER+2),Y : sta $8000
  ldy #11 : lda (ZPUSER+2),Y : sta $8001
            lda #0           : sta $8002
            lda #0           : sta $8003
  ; 8004 = sizeToRead
  ldy #12 : lda (ZPUSER+2),Y : sta $8004
  ldy #13 : lda (ZPUSER+2),Y : sta $8005
  ldy #14 : lda (ZPUSER+2),Y : sta $8006
  ldy #15 : lda (ZPUSER+2),Y : sta $8007
  ; 8008 = sizeRead
  lda #0 : sta $8008 : sta $8009 : sta $800A : sta $800B
  ; 800C = dataAddress
  lda #0 : sta $800C : sta $800D : sta $800E : sta $800F
  ; 8010 = clusterRead
  lda #0 : sta $8010 : sta $8011 : sta $8012 : sta $8013
  ; 8014 = 2
  lda #2 : sta $8014 : lda #0 : sta $8015 : sta $8016 : sta $8017
  ZPASSIGN($8000, ZPUSER+0 ) ; ZPUSER+0  = clusterCurr
  ZPASSIGN($8004, ZPUSER+2 ) ; ZPUSER+2  = sizeToRead
  ZPASSIGN($8008, ZPUSER+4 ) ; ZPUSER+4  = sizeRead
  ZPASSIGN($800C, ZPUSER+6 ) ; ZPUSER+6  = dataAddress
  ZPASSIGN($1300, ZPUSER+8 ) ; ZPUSER+8  = writePtr
  ZPASSIGN($8010, ZPUSER+10) ; ZPUSER+10 = clusterRead
  ; clusterCurr -= 2
  CPZP(ZPUSER+0, ZPFUNCTION+0)
  ZPASSIGN($8014, ZPFUNCTION+2)
  jsr u32subFrom
  ; seek to (dataAddress = (zpBootClSz * (u32)cluterCurr) + zpBootData)
  CPLONG(ZPBOOTCLSZ, ZPUSER+6)
  CPZP(ZPUSER+6, ZPFUNCTION+0)
  CPZP(ZPUSER+0, ZPFUNCTION+2)
  jsr u32mulBy
  CPZP(ZPBOOTDATA, ZPFUNCTION+2)
  jsr u32addTo
  STOR_SEEK_ADDR(ZPBOOTDISK, ZPUSER+6)

readEnoughFile:
  ldy #3 : lda (ZPUSER+4),Y : cmp (ZPUSER+2),Y : bcc readEnoughCluster
  ldy #2 : lda (ZPUSER+4),Y : cmp (ZPUSER+2),Y : bcc readEnoughCluster
  ldy #1 : lda (ZPUSER+4),Y : cmp (ZPUSER+2),Y : bcc readEnoughCluster
  ldy #0 : lda (ZPUSER+4),Y : cmp (ZPUSER+2),Y : bcc readEnoughCluster
  jmp bootJump
readEnoughCluster:
  ldy #3 : lda (ZPUSER+10),Y : cmp (ZPBOOTCLSZ),Y : bcc L000B : jmp readBootChunk : L000B: ; bcc readBootChunk
  ldy #2 : lda (ZPUSER+10),Y : cmp (ZPBOOTCLSZ),Y : bcc L000C : jmp readBootChunk : L000C: ; was out of range...
  ldy #1 : lda (ZPUSER+10),Y : cmp (ZPBOOTCLSZ),Y : bcc L000D : jmp readBootChunk : L000D:
  ldy #0 : lda (ZPUSER+10),Y : cmp (ZPBOOTCLSZ),Y : bcc L000E : jmp readBootChunk : L000E:
  ; clusterCurr += 2
  CPZP(ZPUSER+0, ZPFUNCTION+0)
  ZPASSIGN($8014, ZPFUNCTION+2)
  jsr u32addTo
  ; seek to (data ptr = (zpBootTable + (clusterCurr * 2)))
  CPLONG(ZPUSER+0, ZPUSER+6)
  CPZP(ZPUSER+6, ZPFUNCTION+0)
  ZPASSIGN($8012, ZPFUNCTION+2)
  jsr u32mulBy
  CPZP(ZPBOOTTABLE, ZPFUNCTION+2)
  jsr u32addTo
  STOR_SEEK_ADDR(ZPBOOTDISK,ZPUSER+6)
  ; clusterCurr = read(2)
  STOR_READ(ZPBOOTDISK, #2)
  ldy #0 : lda (ZPBOOTDISK),Y : sta (ZPUSER+0),Y
  ldy #1 : lda (ZPBOOTDISK),Y : sta (ZPUSER+0),Y
  ; if(clusterCurr == 0xFFFF) jmp bootJump
  lda #$FF
  cmp ZPUSER+0 : bne L000F
  cmp ZPUSER+1 : bne L000F
  jmp bootJump
  ; clusterCurr -= 2
  CPZP(ZPUSER+0, ZPFUNCTION+0)
  ZPASSIGN($8014, ZPFUNCTION+2)
  jsr u32subFrom
L000F:
  ; seek to (dataAddress = (zpBootClSz * (u32)cluterCurr) + zpBootData)
  CPLONG(ZPBOOTCLSZ, ZPUSER+6)
  CPZP(ZPUSER+6, ZPFUNCTION+0)
  CPZP(ZPUSER+0, ZPFUNCTION+2)
  jsr u32mulBy
  CPZP(ZPBOOTDATA, ZPFUNCTION+2)
  jsr u32addTo
  STOR_SEEK_ADDR(ZPBOOTDISK, ZPUSER+6)
readBootChunk:
  STOR_READ(ZPBOOTDISK,#16)
  CPZP(ZPBOOTDISK, ZPFUNCTION+0)
  CPZP(ZPUSER+8  , ZPFUNCTION+2)
  lda #$10 : sta ZPFUNCTION+4 : lda #$00 : sta ZPFUNCTION+5
  jsr memCpy
  clc : ldy #0 ; clusterRead += 16
  lda (ZPUSER+10),Y : adc #$10 : sta (ZPUSER+10),Y : iny
  lda (ZPUSER+10),Y : adc #$00 : sta (ZPUSER+10),Y : iny
  lda (ZPUSER+10),Y : adc #$00 : sta (ZPUSER+10),Y : iny
  lda (ZPUSER+10),Y : adc #$00 : sta (ZPUSER+10),Y
  clc : ldy #0 ; sizeRead += 16
  lda (ZPUSER+4),Y : adc #$10 : sta (ZPUSER+4),Y : iny
  lda (ZPUSER+4),Y : adc #$00 : sta (ZPUSER+4),Y : iny
  lda (ZPUSER+4),Y : adc #$00 : sta (ZPUSER+4),Y : iny
  lda (ZPUSER+4),Y : adc #$00 : sta (ZPUSER+4),Y
  clc : ; writePtr += 16
  lda ZPUSER+8 : adc #$10 : sta ZPUSER+8
  lda ZPUSER+9 : adc #$00 : sta ZPUSER+9
jmp readEnoughFile

noBootDisk:
  lda #<strStatus1 : sta ZPFUNCTION+0
  lda #>strStatus1 : sta ZPFUNCTION+1
  jsr printString
  jmp halt
noBootImage:
  lda #<strStatus2 : sta ZPFUNCTION+0
  lda #>strStatus2 : sta ZPFUNCTION+1
  jsr printString
  jmp halt
bootImageLarge:
  lda #<strStatus3 : sta ZPFUNCTION+0
  lda #>strStatus3 : sta ZPFUNCTION+1
  jsr printString
  jmp halt
bootJump:
  lda #<strStatus4 : sta ZPFUNCTION+0
  lda #>strStatus4 : sta ZPFUNCTION+1
  jsr printString
  jmp $1300

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

strNCmp:
  ; ZPFUNCTION[0|1] points to string A
  ; ZPFUNCTION[2|3] points to string B
  ; ZPFUNCTION[4]   holds compare length
  ; ZPFUNCTION[5]   returns result (0-equal, 1-notEqual)
  PUSHALL
  ldy #0
  lda #0 : sta ZPFUNCTION+5
strNCmpLoop:
  tya : cmp ZPFUNCTION+4 : beq strNCmpComplete
  lda (ZPFUNCTION+0),Y : cmp (ZPFUNCTION+2),Y : bne strNCmpDiff
  iny
  jmp strNCmpLoop
strNCmpDiff:
  lda #1 : sta ZPFUNCTION+5
strNCmpComplete:
  POPALL
  rts

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

memCpy:
  ; ZPFUNCTION[0|1] holds *source
  ; ZPFUNCTION[2|3] holds *destination
  ; ZPFUNCTION[4|5] holds u16 length
  PUSHALL
  ldy #0
memCpyLoop:
  lda #0
  cmp ZPFUNCTION+4 : bne memCpyContinue
  cmp ZPFUNCTION+5 : bne memCpyContinue
  jmp memCpyComplete
memCpyContinue:
  lda (ZPFUNCTION+0),Y : sta (ZPFUNCTION+2),Y
  clc
  lda ZPFUNCTION+0 : adc #1 : sta ZPFUNCTION+0
  lda ZPFUNCTION+1 : adc #0 : sta ZPFUNCTION+1
  clc
  lda ZPFUNCTION+2 : adc #1 : sta ZPFUNCTION+2
  lda ZPFUNCTION+3 : adc #0 : sta ZPFUNCTION+3
  sec
  lda ZPFUNCTION+4 : sbc #1 : sta ZPFUNCTION+4
  lda ZPFUNCTION+5 : sbc #0 : sta ZPFUNCTION+5
  jmp memCpyLoop
memCpyComplete:
  POPALL
  rts

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

u32addTo:
  ; ZPFUNCTION[0|1] u32 *addTo   (to += from)
  ; ZPFUNCTION[2|3] u32 *addFrom
  PUSHALL
  clc
  ldy #0 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #1 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #2 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #3 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  POPALL
  rts

u32subFrom:
  ; ZPFUNCTION[0|1] u32 *subFromA (a -= b)
  ; ZPFUNCTION[2|3] u32 *addFromB
  PUSHALL
  sec
  ldy #0 : lda (ZPFUNCTION+0),Y : sbc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #1 : lda (ZPFUNCTION+0),Y : sbc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #2 : lda (ZPFUNCTION+0),Y : sbc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #3 : lda (ZPFUNCTION+0),Y : sbc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  POPALL
  rts

u32mulBy:
  ; ZPFUNCTION[0|1] u32 *mulDest (dest *= mul)
  ; ZPFUNCTION[2|3] u32 *mul
  PUSHALL

  ; copy mulDest to ZPFUNCTION[4|5] -> ZPFUNCTION[6|7|8|9] as counter
  ; original mulDest now stores product (zero during copy)
  lda #<(ZPFUNCTION+6) : sta ZPFUNCTION+4
  lda #>(ZPFUNCTION+6) : sta ZPFUNCTION+5
  ldy #0 : lda (ZPFUNCTION+0),Y : sta (ZPFUNCTION+4),Y : lda #0 : sta (ZPFUNCTION+0),Y
  ldy #1 : lda (ZPFUNCTION+0),Y : sta (ZPFUNCTION+4),Y : lda #0 : sta (ZPFUNCTION+0),Y
  ldy #2 : lda (ZPFUNCTION+0),Y : sta (ZPFUNCTION+4),Y : lda #0 : sta (ZPFUNCTION+0),Y
  ldy #3 : lda (ZPFUNCTION+0),Y : sta (ZPFUNCTION+4),Y : lda #0 : sta (ZPFUNCTION+0),Y
u32mulByCheck:
  ; if(counter == 0) break
  lda #0
  ldy #0 : cmp (ZPFUNCTION+4),Y : bne u32mulByContinue
  ldy #1 : cmp (ZPFUNCTION+4),Y : bne u32mulByContinue
  ldy #2 : cmp (ZPFUNCTION+4),Y : bne u32mulByContinue
  ldy #3 : cmp (ZPFUNCTION+4),Y : bne u32mulByContinue
  jmp u32mulByDone
u32mulByContinue:
  ; mulDest += mul
  clc
  ldy #0 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #1 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #2 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
  ldy #3 : lda (ZPFUNCTION+0),Y : adc (ZPFUNCTION+2),Y : sta (ZPFUNCTION+0),Y
u32mulByDec:
  ; counter--
  sec
  ldy #0 : lda (ZPFUNCTION+4),Y : sbc #1 : sta (ZPFUNCTION+4),Y
  ldy #1 : lda (ZPFUNCTION+4),Y : sbc #0 : sta (ZPFUNCTION+4),Y
  ldy #2 : lda (ZPFUNCTION+4),Y : sbc #0 : sta (ZPFUNCTION+4),Y
  ldy #3 : lda (ZPFUNCTION+4),Y : sbc #0 : sta (ZPFUNCTION+4),Y
  jmp u32mulByCheck
u32mulByDone:
  POPALL
  rts

/*============================================================================*/

halt:
  .byt $FF

strConvid:  .asc "CONVID" : .byt $00
strBootImg: .asc "BOOT    IMG"
strStatus0: .asc "Searching for boot device..."           : .byt $0A : .byt $00
strStatus1: .asc "No valid boot device found..."          : .byt $0A : .byt $00
strStatus2: .asc "Boot image missing from boot device..." : .byt $0A : .byt $00
strStatus3: .asc "Boot image is too large..."             : .byt $0A : .byt $00
strStatus4: .asc "Boot image found. Loading..."           : .byt $0A : .byt $00
strTestA  : .asc "Reached Testing State A..."             : .byt $0A : .byt $00
strTestB  : .asc "Reached Testing State B..."             : .byt $0A : .byt $00
strTestC  : .asc "Reached Testing State C..."             : .byt $0A : .byt $00
strTestD  : .asc "Reached Testing State D..."             : .byt $0A : .byt $00
