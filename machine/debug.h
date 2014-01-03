#ifndef DEBUG_HEADER
#define DEBUG_HEADER

#include "cpu.h"

void dump_cpu(cpu *m);

#ifdef DEBUG
#define DUMP_DEBUG(m) (dump_cpu(m))
#else
#define DUMP_DEBUG(m) 
#endif

#endif //DEBUG_HEADER
