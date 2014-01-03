#define IO_SOURCE
#include <string.h>
#include "io.h"
#include "debug.h"

#define DEVICEMAX 15

pthread_mutex_t  irqMutex;
static ioDevice *devices[DEVICEMAX] = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
static u8        interrupts[DEVICEMAX];
static cpu       *cpuRef;  // io_deviceInterrupt() -> shit...
static void io_controller(u8 port, u8 data);
static u8   io_controller_data[16];

void io_startup(cpu *m)
{
  for(int i=0; i<DEVICEMAX; i++) interrupts[i] = 0xFF;
  for(int i=0; i<16; i++) io_controller_data[i] = 0x00;
  pthread_mutex_init(&irqMutex, NULL);
}

void io_cleanup(cpu *m)
{
  for(int i=0; i<DEVICEMAX; i++)
    if(devices[i])
      devices[i]->cleanup(devices[i]);
}

void io_updatePorts(cpu *m)
{
  // we only ever ready this data; so, not going to worry about synchronization...
  memcpy(m->ram + PAGE_IO, io_controller_data, 16);
  for(int i=0; i<DEVICEMAX; i++)
    if(devices[i])
      memcpy(m->ram + PAGE_IO + ((i+1)<<4), devices[i]->data, 16);
}

void io_handleWrite(cpu *m)
{
  if((m->dirty & 0xFF00) != PAGE_IO) return;
  u8 device = (u8)((m->dirty & 0xF0) >> 4);
  u8 port   = (u8)(m->dirty & 0x0F);
  u8 data   = m->ram[m->dirty];
  if(device == 0)
    io_controller(port, data);
  else
  {
    device--;
    if(devices[device])
      devices[device]->write(devices[device], port, data);
  }
}

void io_serviceInt(cpu *m)
{
  devices[interrupts[0]]->intAck(devices[interrupts[0]]);
  for(int i=0; i<(DEVICEMAX-2); i++) interrupts[i] = interrupts[i+1];
  interrupts[DEVICEMAX-1] = 0x00;
  if(interrupts[0]) m->irq = true;
}

void io_deviceRegister(ioDevice *device)
{
  int index = -1;
  for(int i=0; i<DEVICEMAX; i++)
    if(devices[i] == NULL)
      { index=i; break; }
  if(index == -1) return;
  devices[index] = device;
}

void io_deviceInterrupt(ioDevice *device)
{
  int index = -1;
  for(int i=0; i<DEVICEMAX; i++)
    if(devices[i] == device)
      { index=i; break; }
  if(index == -1) return;

  pthread_mutex_lock(&irqMutex);
  cpuRef->irq = true;
  int idx;
  for(idx=0; idx<DEVICEMAX; idx++)
    if(interrupts[idx] == index) break;
  if(idx == DEVICEMAX)
    for(idx=0; idx<DEVICEMAX; idx++)
      if(interrupts[idx] == index)
        { interrupts[idx] = index; break; }
  pthread_mutex_unlock(&irqMutex);
}

static void io_controller(u8 port, u8 data)
{
  io_controller_data[port] = data;
  if(port > 0) return;
  switch(data)
  {
    case IOC_CMD_COUNT:
      io_controller_data[1] = 0;
      for(int i=0; i<DEVICEMAX; i++)
        if(devices[i]) io_controller_data[1]++;
      break;
  }
}
