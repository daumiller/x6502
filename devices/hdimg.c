#include <stdio.h>
#include <string.h>
#include "../machine/x6502.h"
#include "../machine/io.h"
#include "hdimg.h"
#include "ioClassStorage.h"

static void write  (ioDevice *device, u8 port, u8 data);
static void intAck (ioDevice *device);
static void cleanup(ioDevice *device);
static void sysCommand(ioDevice *device, u8 data);
static void usrCommand(ioDevice *device, u8 data);

void deviceStart_hdimg(FILE *imageFile)
{
  ioDevice *hdimg = (ioDevice *)calloc(sizeof(ioDevice), 1);
  hdimg->write   = (ioDeviceWrite  )write;
  hdimg->intAck  = (ioDeviceIntAck )intAck;
  hdimg->cleanup = (ioDeviceCleanup)cleanup;
  memset(hdimg->data, 0, 16);
  hdimg->deviceData = imageFile;
  io_deviceRegister(hdimg);
}

static void write(ioDevice *device, u8 port, u8 data)
{
  device->data[port] = data; //copy to our internal buffer, which will be mirrored back to RAM
  if(port == 0)
  {
    if(data < 0x10)
      sysCommand(device, data);
    else
      usrCommand(device, data);
  }
}

static void intAck(ioDevice *device) { }

static void cleanup(ioDevice *device) { }

static void sysCommand(ioDevice *device, u8 data)
{
  FILE *fimg = (FILE *)device->deviceData;

  switch(data)
  {
    case IO_CMD_RESET:
      memset(device->data, 0, 16);
      fseek(fimg, 0, SEEK_SET);
      break;

    case IO_CMD_CLASS:
      device->data[0] = IO_CLASS_STORAGE;
      break;

    case IO_CMD_VID:
      device->data[0] = 0xDE;
      device->data[1] = 0xAD;
      device->data[2] = 0xBE;
      device->data[3] = 0xEF;
      break;

    case IO_CMD_PID:
      device->data[0] = 'D';
      device->data[1] = 'I';
      device->data[2] = 'M';
      device->data[3] = 'G';
      break;

    case IO_CMD_NAME:
      device->data[0] = 'D';
      device->data[1] = 'I';
      device->data[2] = 'S';
      device->data[3] = 'K';
      device->data[4] = 'I';
      device->data[5] = 'M';
      device->data[6] = 'A';
      device->data[7] = 'G';
      device->data[8] = 'E';
      device->data[9] = 0x00;
  }
}

static void usrCommand(ioDevice *device, u8 data)
{
  FILE *fimg = (FILE *)device->deviceData;

  switch(data)
  {
    case STOR_CMD_SIZE:
      {
        if(fimg == NULL) { device->data[0]=device->data[1]=device->data[2]=device->data[3]=0x00; break; }
        long pos = ftell(fimg);
        fseek(fimg, 0, SEEK_END);
        u32 size = (u32)ftell(fimg);
        fseek(fimg, pos, SEEK_SET);
        device->data[0] = (size & 0x000000FF)      ;
        device->data[1] = (size & 0x0000FF00) >>  8;
        device->data[2] = (size & 0x00FF0000) >> 16;
        device->data[3] = (size & 0xFF000000) >> 24;
      }
      break;

    case STOR_CMD_SEEK:
      {
        if(fimg == NULL) break;
        u32 pos = (((u32)device->data[1])    ) |
                  (((u32)device->data[2])<< 8) |
                  (((u32)device->data[3])<<16) |
                  (((u32)device->data[4])<<24) ;
        fseek(fimg, pos, SEEK_SET);
      }
      break;

    case STOR_CMD_TELL:
      {
        if(fimg == NULL) { device->data[0]=device->data[1]=device->data[2]=device->data[3]=0x00; break; }
        u32 pos = (u32)ftell(fimg);
        device->data[0] = (pos & 0x000000FF)      ; 
        device->data[1] = (pos & 0x0000FF00) >>  8; 
        device->data[2] = (pos & 0x00FF0000) >> 16; 
        device->data[3] = (pos & 0xFF000000) >> 24;
      }
      break;

    case STOR_CMD_READ:
      {
        u32 cur, tot=0, req = (u32)device->data[1]; if(req>16) req=16;
        memset(device->data, 0, 16);
        if(fimg == NULL) break;
        while(tot < req) {
          if((cur = fread(device->data+tot, 1, req-tot, fimg)) == 0) break;
          tot += cur;
        }
        //for(int i=0; i<req; i++) printf("%02X ", device->data[i]); printf("\n");
      }
      break;

    case STOR_CMD_WRITE:
      {
        if(fimg == NULL) break;
        u32 cur, tot=0, req = (u32)device->data[1]; if(req>14) req=14;
        while(tot < req) {
          if((cur = fwrite(device->data+tot+1, 1, req-tot, fimg)) == 0) break;
          tot += cur;
        }
      }
      break;

    case HDIMG_CMD_KSIZE:
      {
        if(fimg == NULL) { device->data[0]=device->data[1]=device->data[2]=device->data[3]=0x00; break; }
        long pos = ftell(fimg);
        fseek(fimg, 0, SEEK_END);
        u32 size = ((u32)ftell(fimg)) / 1000; // >> 10
        fseek(fimg, pos, SEEK_SET);
        device->data[0] = (size & 0x000000FF)      ;
        device->data[1] = (size & 0x0000FF00) >>  8;
        device->data[2] = (size & 0x00FF0000) >> 16;
        device->data[3] = (size & 0xFF000000) >> 24;
      }
      break;

    case HDIMG_CMD_MSIZE:
      {
        if(fimg == NULL) { device->data[0]=device->data[1]=device->data[2]=device->data[3]=0x00; break; }
        long pos = ftell(fimg);
        fseek(fimg, 0, SEEK_END);
        u32 size = ((u32)ftell(fimg)) / 1000000; // >> 20
        fseek(fimg, pos, SEEK_SET);
        device->data[0] = (size & 0x000000FF)      ;
        device->data[1] = (size & 0x0000FF00) >>  8;
        device->data[2] = (size & 0x00FF0000) >> 16;
        device->data[3] = (size & 0xFF000000) >> 24;
      }
      break;
  }
}
