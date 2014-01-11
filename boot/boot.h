#define IOC_ADDR_COMMAND $0200
#define IOC_ADDR_REPLY   $0201
#define IOC_CMD_COUNT    $01
#define IO_CLASS_STORAGE $06
#define IO_CMD_RESET     $00
#define IO_CMD_CLASS     $01
#define IO_CMD_VID       $02
#define IO_CMD_PID       $03
#define IO_CMD_NAME      $04
#define IO_CMD_USER      $10
#define CONVID_CMD_PUTC  $10
#define STOR_CMD_SIZE    $10
#define STOR_CMD_SEEK    $11
#define STOR_CMD_READ    $13
#define BOOT_IMAGE_MAX   27904

#define PUSHALL   pha : txa : pha : tya : pha
#define POPALL    pla : tay : pla : tax : pla

#define ZPIO        $0000 /* system constants        reserved 00-1F */
#define ZPCONVID    $0002 /*    console video device                */
#define ZPBOOTDISK  $0004 /*    boot storage device                 */
#define ZPKEYBOARD  $0006 /*    keyboard device                     */
#define ZPBOOTTABLE $0008 /* [08|09] + [0A|0B|0C|0D]                */
#define ZPBOOTROOT  $000E /* [0E|0F] + [10|11|12|13]                */
#define ZPBOOTDATA  $0014 /* [14|15] + [16|17|18|19]                */
#define ZPBOOTCLSZ  $001A /* [1A|1B] + [1C|1D|1E|1F]                */
#define ZPSCRATCH   $0020 /* scratchpad                       20-CF */
#define ZPUSER      $00D0 /* user/local              reserved D0-EF */
#define ZPFUNCTION  $00F0 /* function params/returns reserved F0-FF */
