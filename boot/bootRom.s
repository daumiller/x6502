; xa -bt0 boot.s -o boot.bin

#define IOC_CMD_ADDR     $0200
#define IOC_RES_ADDR     $0201
#define IOC_CMD_COUNT    $01
#define IO_CMD_RESET     $00
#define IO_CMD_CLASS     $01
#define IO_CMD_VID       $02
#define IO_CMD_PID       $03
#define IO_CMD_NAME      $04
#define IO_CMD_USER      $10
#define CONVID_CMD_PUTC  $10
#define IO_CLASS_STORAGE $06
#define STOR_CMD_SIZE    $10
#define STOR_CMD_SEEK    $11
#define STOR_CMD_READ    $13
#define PUSHALL   pha : txa : pha : tya : pha
#define POPALL    pla : tay : pla : tax : pla

/*============================================================================*/

init:
  jmp $0300   ; $0000 = jmp to page 3
  .dsb $02FD  ; fill first 2 pages with zero

/*============================================================================*/

startup:
  sei            ; disable interrupts
  cld            ; disable decimal mode
  ldx #$FF : txs ; initialize stack pointer
  /* initialize zero-page entries */
  ; zp[0|1] == USER
  ; zp[2|3] == IO_PAGE
  lda #$00 : sta $0002
  lda #$02 : sta $0003
  ; zp[4|5] == CONVID
  lda #$00 : sta $0004
  lda #$02 : sta $0005
  ; zp[6|7] == USER
  ; zp[8|9] == BOOTDEVICE
  lda #$00 : sta $0008
  lda #$02 : sta $0009
  ; zp[F0-FF] = functions

findConvid:
  ; ioController(IOC_CMD_COUNT)
  lda #IOC_CMD_COUNT
  sta IOC_CMD_ADDR
  lda #0
  pha
L0000:
  pla
  cmp IOC_RES_ADDR
  bne L0001 : jmp halt ; "beq halt"
L0001:
  adc #1
  ; addr = IO_PAGE + ((a+1)*16)
  asl : asl : asl : asl
  tay
  lsr : lsr : lsr : lsr
  pha
  lda #IO_CMD_NAME
  sta ($02),Y
  ; compare device's reported name to strConvid
  tya : adc $0002 : sta $0000
        lda $0003 : sta $0001
  lda #<strConvid : sta $0006
  lda #>strConvid : sta $0007
  jsr strCmp
  lda #0 : cmp $00F0 : bne L0000
foundConvid:
  pla
  asl : asl : asl : asl
  sta $0004                  ; store convid ptr in zp[4|5]
  lda #<strStatus0 : sta $0000
  lda #>strStatus0 : sta $0001
  jsr printString

findBootDisk:
  ; ioController(IOC_CMD_COUNT)
  lda #IOC_CMD_COUNT
  sta IOC_CMD_ADDR
  lda #0
  pha
L0002:
  pla
  cmp IOC_RES_ADDR
  bne L0003
  jmp noBootDisk
L0003:
  adc $1
  asl : asl : asl : asl
  tay
  lsr : lsr : lsr : lsr
  pha
  ; compare class
  lda #IO_CMD_CLASS
  sta ($02),Y
  lda #IO_CLASS_STORAGE
  cmp ($02),Y
  bne L0002
  ; verify size (>= 256)
  lda #STOR_CMD_SIZE
  sta ($02),Y
  lda #0
  iny : cmp ($02),Y : bne L0005
  iny : cmp ($02),Y : bne L0004
  iny : cmp ($02),Y : beq L0002 : dey
L0004: dey
L0005: dey
  ; read boot signature
  lda #2 : iny : sta ($02),Y : dey
  lda #STOR_CMD_READ : sta ($02),Y
  ; test boot signature
  lda #$55 : cmp ($02),Y : bne L0002 : iny
  lda #$AA : cmp ($02),Y : bne L0002 : dey
  ; store zero-page entry for BOOTDEVICE (in zp[8|9])
  pla
  asl : asl : asl : asl
  sta $0008
  ldy #0
  ; read boot block size
  lda #2 : ldy #1 : sta ($08),Y : ldy #0
  lda #STOR_CMD_READ : sta ($08),Y
  lda ($08),Y : sta $00FE : ldy #1
  lda ($08),Y : sta $00FF : ldy #0
  ; read boot block offset
  lda #2 : ldy #1 : sta ($08),Y : ldy #0
  lda #STOR_CMD_READ : sta ($08),Y
  ; seek to offset
  lda #0 ; zero 2 most-significant bytes
  ldy #3 : sta ($08),Y
  ldy #4 : sta ($08),Y
  ; shift 2 least-significant bytes
  ldy #1 : lda ($08),Y : ldy #2 : sta ($08),Y
  ldy #0 : lda ($08),Y : ldy #1 : sta ($08),Y
  ldy #0 : lda #STOR_CMD_SEEK : sta ($08),Y
  ; set zp[0|1] == boot block writing pointer
  lda #$00 : sta $0000
  lda #$13 : sta $0001
  ; set zp[6|7] == boot block reading pointer
  lda $0008 : sta $0006
  lda $0009 : sta $0007
  ; read boot blocks
  lda #0 : sta $00FC : sta $00FD
L0006:
  lda $00FC : cmp $00FE : bne L0007
  lda $00FD : cmp $00FF : bne L0007
  jmp bootJump
L0007:
  lda #$10           : ldy #1 : sta ($08),Y ; size    - 16 bytes
  lda #STOR_CMD_READ : ldy #0 : sta ($08),Y ; command - read
  ; memcpy
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  lda ($06),Y : sta ($00),Y : iny    :    lda ($06),Y : sta ($00),Y : iny
  ; increment writing pointer
  lda $0000 : adc #16 : sta $0000 : bcc L0008
  lda $0001 : adc #1  : sta $0001
L0008:
  ; increment block counter
  lda $00FC : adc #1 : sta $00FC : bcc L0009
  lda $00FD : adc #1 : sta $00FD
L0009:
  jmp L0006
  ; jump to boot sector
bootJump:
  jmp $1300

noBootDisk:
  lda #<strStatus1 : sta $0000
  lda #>strStatus1 : sta $0001
  jsr printString
  jmp halt

/*============================================================================*/

copyBlock:
  ; zp[0|1] holds write to location
  ; zp[6|7] holds read from location
  ; copy size is always 16 bytes
  

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

printString:
  ; zp[0|1] holds string location
  ; zp[4|5] holds convid location
  PUSHALL
  ldy #0
printStringLoop:
  lda ($00),Y
  cmp #0 : beq printStringComplete
  iny : tax : tya : pha : txa ; increment y + push y (preserving a)
  ldy #1 : sta ($04),Y
  ldy #0 : lda #CONVID_CMD_PUTC : sta ($04),Y
  pla : tay
  jmp printStringLoop:
printStringComplete:
  POPALL
  rts

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

strCmp:
  ; zp[0|1] holds string A
  ; zp[6|7] holds string B
  ; result will be returned in $00F0 (0 - equal, 1 - not equal)
  PUSHALL
  ldy #0
  lda #1 : sta $00F0
strCmpLoop:
  lda ($00),Y
  cmp ($06),Y
  bne strCmpComplete
  iny
  cmp #0
  bne strCmpLoop
  lda #0 : sta $00F0
strCmpComplete:
  POPALL
  rts

/*============================================================================*/

halt:
  .byt $FF

strConvid:
  .asc "CONVID" : .byt $00
strStatus0:
  .asc "Searching for boot device..." : .byt $0A : .byt $00
strStatus1:
  .asc "No valid boot device found..." : .byt $0A : .byt $00
