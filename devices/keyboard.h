#ifndef KEYBOARD_HEADER
#define KEYBOARD_HEADER

#define STDKBD_CMD_AVAILABLE 0x80
#define STDKBD_CMD_READ      0x81
#define STDKBD_CMD_READN     0x82
#define STDKBD_CMD_CLEAR     0x83
#define STDKBD_CMD_INT_DIS   0x84
#define STDKBD_CMD_INT_EN    0x85

void deviceStart_keyboard();

#endif //KEYBOARD_HEADER
