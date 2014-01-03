#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../machine/x6502.h"
#include "../machine/cpu.h"
#include "../machine/io.h"
#include "banking.h"

static ioDevice banking;
static u8 bankMax, bankCur;
static cpu *bankCpu;
static u8 **bankMem;

static void write  (ioDevice *device, u8 port, u8 data);
static void intAck (ioDevice *device);
static void cleanup(ioDevice *device);
static void sysCommand(u8 data);
static void usrCommand(u8 data);

void deviceStart_banking(cpu *m, u8 banks)
{
  bankCur = 0;
  bankMax = banks;
  bankCpu = m;
  bankMem = (u8 **)malloc(sizeof(u8 *) * banks); if(!bankMem) { printf("Error allocating banks\n"); exit(-1); }
  // wastefully creating double-sized banks to avoid splitting cpu's ram array
  bankMem[0] = bankCpu->ram;
  for(u8 i=1; i<(bankMax-1); i++)
  {
    bankMem[i] = (u8 *)malloc(sizeof(u8) * SIZE_RAM);
    if(!bankMem[i]) { printf("Error allocating bank\n"); exit(-1); }
  }

  banking.write   = (ioDeviceWrite  )write;
  banking.intAck  = (ioDeviceIntAck )intAck;
  banking.cleanup = (ioDeviceCleanup)cleanup;
  for(int i=0; i<16; i++)
    banking.data[i] = 0x00;
  io_deviceRegister(&banking);
}


static void write(ioDevice *device, u8 port, u8 data)
{
  banking.data[port] = data; //copy to our internal buffer, which will be mirrored back to RAM
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
  bankCpu->ram = bankMem[0];
  for(u8 i=1; i<bankMax; i++)
    free(bankMem[i]);
  free(bankMem);
}

static void sysCommand(u8 data)
{
  switch(data)
  {
    case IO_CMD_RESET:
      for(int i=0; i<16; i++)
        banking.data[i] = 0x00;
      // we would do a clear_screen here, but i don't want to trash our conlog
      break;

    case IO_CMD_CLASS:
      banking.data[0] = IO_CLASS_MEMORY;
      break;

    case IO_CMD_VID:
      banking.data[0] = 0xDE;
      banking.data[1] = 0xAD;
      banking.data[2] = 0xBE;
      banking.data[3] = 0xEF;
      break;

    case IO_CMD_PID:
      banking.data[0] = 'B';
      banking.data[1] = 'A';
      banking.data[2] = 'N';
      banking.data[3] = 'K';
      break;

    case IO_CMD_NAME:
      banking.data[0] = 'B';
      banking.data[1] = 'A';
      banking.data[2] = 'N';
      banking.data[3] = 'K';
      banking.data[4] = 'I';
      banking.data[5] = 'N';
      banking.data[6] = 'G';
      banking.data[7] = 0x00;
      break;
  }
}

static void usrCommand(u8 data)
{
  switch(data)
  {
    case BANKING_CMD_BANKCOUNT:
      banking.data[0] = bankMax;
      break;

    case BANKING_CMD_BANKGET:
      banking.data[0] = bankCur;
      break;

    case BANKING_CMD_BANKSET:
    {
      u8 bankNew = banking.data[1];
      if(bankNew >  bankMax) break;
      if(bankNew == bankCur) break;
      memcpy(bankMem[bankNew], bankMem[bankCur], 32768); // copy lower 32K
      bankCur = bankNew;
      bankCpu->ram = bankMem[bankCur]; // switch over (to access new bank's upper 32K)
    }
    break;
  }
}
