#include <stdio.h>
#include <string.h>
#include "x6502.h"

void *bailMalloc(u32 size)
{
  void *ret = malloc((size_t)size);
  if(!ret) { fprintf(stderr, "Error allocating memory (malloc(%u)).\n", size); exit(-1); }
  return ret;
}

void *bailCalloc(u32 size)
{
  void *ret = malloc((size_t)size);
  if(!ret) { fprintf(stderr, "Error allocating memory (malloc(%u)).\n", size); exit(-1); }
  memset(ret, 0, (size_t)size);
  return ret;
}

void *bailSalloc(u32 size, u8 byte)
{
  void *ret = malloc((size_t)size);
  if(!ret) { fprintf(stderr, "Error allocating memory (malloc(%u)).\n", size); exit(-1); }
  memset(ret, byte, (size_t)size);
  return ret;
}
