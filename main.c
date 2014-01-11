#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "machine/x6502.h"
#include "machine/cpu.h"

#include "devices/convid.h"
#include "devices/hdimg.h"
#include "devices/keyboard.h"
#include "devices/banking.h"

int main(int argc, char **argv)
{
  cpu *m = cpuCreate();
  int baseAddr=0; int b; int i=baseAddr;

  FILE *fin = fopen("boot.rom", "rb");
  while((b = fgetc(fin)) != EOF)
    m->ram[i++] = (u8)b;
  m->pc = baseAddr;
  fclose(fin);

  fin = fopen("hda.dmg", "r+b");
  deviceStart_hdimg(fin);
  deviceStart_convid();
  deviceStart_keyboard();
  deviceStart_banking(m, 0xFF); // consume 16MiB...

  cpuStart(m);
  return 0;
}
