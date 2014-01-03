#ifndef BANKING_HEADER
#define BANKING_HEADER

#define BANKING_CMD_BANKCOUNT 0x80
#define BANKING_CMD_BANKGET   0x81
#define BANKING_CMD_BANKSET   0x82

// 256 banks == 32 KiB lower + 8 MiB upper
void deviceStart_banking(cpu *m, u8 banks);

#endif //BANKING_HEADER
