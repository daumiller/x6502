#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "x6502.h"
#include "cpu.h"

#include "../devices/convid.h"
#include "../devices/hdimg.h"

int main(int argc, char **argv)
{
  cpu *m = cpuCreate();
  int baseAddr=0; int b; int i=baseAddr;

  FILE *fin = fopen("boot.rom", "rb");
  while((b = fgetc(fin)) != EOF)
    m->ram[i++] = (u8)b;
  m->pc = baseAddr;
  fclose(fin);

  deviceStart_convid();

  fin = fopen("hda.img", "r+b");
  deviceStart_hdimg(fin);

  cpuStart(m);

  return 0;
}
