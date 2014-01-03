#include <stdio.h>
#include "../machine/x6502.h"
#include "../machine/io.h"
#include "convid.h"

static ioDevice convid;

static void write  (ioDevice *device, u8 port, u8 data);
static void intAck (ioDevice *device);
static void cleanup(ioDevice *device);
static void sysCommand(u8 data);
static void usrCommand(u8 data);

void deviceStart_convid()
{
  convid.write   = (ioDeviceWrite  )write;
  convid.intAck  = (ioDeviceIntAck )intAck;
  convid.cleanup = (ioDeviceCleanup)cleanup;
  for(int i=0; i<16; i++)
    convid.data[i] = 0x00;
  io_deviceRegister(&convid);
}


static void write(ioDevice *device, u8 port, u8 data)
{
  convid.data[port] = data; //copy to our internal buffer, which will be mirrored back to RAM
  if(port == 0)
  {
    if(data < 0x10)
      sysCommand(data);
    else
      usrCommand(data);
  }
}

static void intAck(ioDevice *device) { }

static void cleanup(ioDevice *device) { }

static void sysCommand(u8 data)
{
  switch(data)
  {
    case IO_CMD_RESET:
      for(int i=0; i<16; i++)
        convid.data[i] = 0x00;
      // we would do a clear_screen here, but i don't want to trash our conlog
      break;

    case IO_CMD_CLASS:
      convid.data[0] = IO_CLASS_VIDEO;
      break;

    case IO_CMD_VID:
      convid.data[0] = 0xDE;
      convid.data[1] = 0xAD;
      convid.data[2] = 0xBE;
      convid.data[3] = 0xEF;
      break;

    case IO_CMD_PID:
      convid.data[0] = 'V';
      convid.data[1] = 'I';
      convid.data[2] = 'D';
      convid.data[3] = 0x00;
      break;

    case IO_CMD_NAME:
      convid.data[0] = 'C';
      convid.data[1] = 'O';
      convid.data[2] = 'N';
      convid.data[3] = 'V';
      convid.data[4] = 'I';
      convid.data[5] = 'D';
      convid.data[6] = 0x00;
      break;
  }
}

static void usrCommand(u8 data)
{
  putc((int)convid.data[1], stdout);
  fflush(stdout);
}
