#ifndef IO_HEADER
#define IO_HEADER

#include <pthread.h>
#include "x6502.h"
#include "cpu.h"

#ifndef IO_SOURCE
extern pthread_mutex_t irqMutex;
#endif //IO_SOURCE

#define IO_CMD_RESET 0x00
#define IO_CMD_CLASS 0x01
#define IO_CMD_VID   0x02
#define IO_CMD_PID   0x03
#define IO_CMD_NAME  0x04
#define IO_CMD_USER  0x10

#define IOC_CMD_COUNT 0x01 // deviceCount > port[1]

#define IO_CLASS_INVALID   0x00
#define IO_CLASS_VIDEO     0x01
#define IO_CLASS_AUDIO     0x02
#define IO_CLASS_TYPING    0x03
#define IO_CLASS_POINTING  0x04
#define IO_CLASS_GAMEPAD   0x05
#define IO_CLASS_STORAGE   0x06
#define IO_CLASS_REMOVABLE 0x07
#define IO_CLASS_MEMORY    0x08
#define IO_CLASS_PRINTER   0x09
#define IO_CLASS_SERIAL    0x0A
#define IO_CLASS_NETWORK   0x0B
#define IO_CLASS_OTHER     0xFF

void io_startup    (cpu *m);
void io_updatePorts(cpu *m);
void io_handleWrite(cpu *m);
void io_cleanup    (cpu *m);
void io_serviceInt (cpu *m);

// (1) a real device could perform actions on read commands;
// but this source would take a large modification
// (and probably a large slow-down), to check every memory read...
//typedef   u8 (ioDeviceRead   )(ioDevice *device, u8 port); // (1)
typedef void (*ioDeviceWrite  )(void *device, u8 port, u8 data);
typedef void (*ioDeviceIntAck )(void *device); // runs on cpu thread; do NOT call io_deviceInterrupt from here...
typedef void (*ioDeviceCleanup)(void *device);

typedef struct {
  //ioDeviceRead    read; (1)
  ioDeviceWrite   write;
  ioDeviceIntAck  intAck;
  ioDeviceCleanup cleanup;
  u8 data[16]; // (1)
  void *deviceData;
} ioDevice;

void io_deviceRegister (ioDevice *device);
void io_deviceInterrupt(ioDevice *device);

#endif //IO_HEADER
