#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <pthread.h>
#include "../machine/x6502.h"
#include "../machine/io.h"
#include "keyboard.h"

static ioDevice keyboard;
static u8 buffPos, buffLen, buffDat[16];
pthread_mutex_t buffMtx;

static void kbdWrite(ioDevice *device, u8 port, u8 data);
static void intAck  (ioDevice *device);
static void cleanup (ioDevice *device);
static void sysCommand(u8 data);
static void usrCommand(u8 data);

struct termios termOld;
pthread_t ioThread;
static void *ioFunction(void *d);

void deviceStart_keyboard()
{
  if(tcgetattr(STDIN_FILENO, &termOld) < 0) printf("damnit0\n");
  termOld.c_lflag &= ~(ICANON | ECHO);
  termOld.c_cc[VMIN]  = 1;
  termOld.c_cc[VTIME] = 0;
  if(tcsetattr(STDIN_FILENO, TCSANOW, &termOld) < 0) printf("damnit1\n");

  pthread_mutex_init(&buffMtx, NULL);
  pthread_create(&ioThread, NULL, ioFunction, NULL);

  keyboard.write   = (ioDeviceWrite  )kbdWrite;
  keyboard.intAck  = (ioDeviceIntAck )intAck;
  keyboard.cleanup = (ioDeviceCleanup)cleanup;
  for(int i=0; i<16; i++)
    keyboard.data[i] = 0x00;
  io_deviceRegister(&keyboard);
  buffLen = buffPos = 0;
}


static void kbdWrite(ioDevice *device, u8 port, u8 data)
{
  keyboard.data[port] = data; //copy to our internal buffer, which will be mirrored back to RAM
  if(port == 0)
  {
    if(data < 0x10)
      sysCommand(data);
    else
      usrCommand(data);
  }
}

static void intAck(ioDevice *device) { }

static void cleanup(ioDevice *device)
{
  pthread_cancel(ioThread);
  termOld.c_lflag |= (ICANON | ECHO);
  tcsetattr(STDIN_FILENO, TCSADRAIN, &termOld);
}

static void sysCommand(u8 data)
{
  switch(data)
  {
    case IO_CMD_RESET:
      buffLen = 0;
      for(int i=0; i<16; i++)
        keyboard.data[i] = 0x00;
      break;

    case IO_CMD_CLASS:
      keyboard.data[0] = IO_CLASS_TYPING;
      break;

    case IO_CMD_VID:
      keyboard.data[0] = 0xDE;
      keyboard.data[1] = 0xAD;
      keyboard.data[2] = 0xBE;
      keyboard.data[3] = 0xEF;
      break;

    case IO_CMD_PID:
      keyboard.data[0] = 'K';
      keyboard.data[1] = 'B';
      keyboard.data[2] = 'D';
      keyboard.data[3] = 0x00;
      break;

    case IO_CMD_NAME:
      keyboard.data[0] = 'S';
      keyboard.data[1] = 'T';
      keyboard.data[2] = 'D';
      keyboard.data[3] = 'K';
      keyboard.data[4] = 'B';
      keyboard.data[5] = 'D';
      keyboard.data[6] = 0x00;
      break;
  }
}

static void usrCommand(u8 data)
{
  pthread_mutex_lock(&buffMtx);
  switch(data)
  {
    case STDKBD_CMD_AVAILABLE:
      keyboard.data[0] = buffLen;
      break;

    case STDKBD_CMD_READ:
      if(buffLen == 0)
        keyboard.data[0] = 0;
      else
      {
        keyboard.data[0] = buffDat[buffPos];
        buffLen--;
        buffPos++;
        buffPos &= 0x0F;
      }
      break;
      
    case STDKBD_CMD_READN:
    {
      u8 size = keyboard.data[1];
      if(size > buffLen) size = buffLen;
      for(u8 i=0; i<size; i++)
      {
        keyboard.data[i] = buffDat[buffPos];
        buffLen--;
        buffPos++;
        buffPos &= 0x0F;
      }
    }
    break;

    case STDKBD_CMD_CLEAR:
      buffLen = 0;
      break;
  }
  pthread_mutex_unlock(&buffMtx);
}

static void *ioFunction(void *d)
{
  u8 ch;
  while(1)
  {
    read(STDIN_FILENO, &ch, 1);
    pthread_mutex_lock(&buffMtx);
    buffDat[(buffPos+buffLen) & 0x0F] = (u8)ch;
    buffLen++; buffLen &= 0x0F;
    //interrupt (if intack since last interrupt)
    pthread_mutex_unlock(&buffMtx);
  }
  return NULL;
}
