#include <stdint.h>

uint64_t* PLM4 = (uint64_t*)(0x9000);
uint64_t* PDPT = (uint64_t*)(0xa000);
uint64_t* PDE = (uint64_t*)(0xb000);
uint64_t* PAGE = (uint64_t*)(0xc000);

uint64_t* TEST = (uint64_t*)(0x200000);
uint64_t table[512] = {0};

int Start_Kernel(void)
{
		int *addr = (int *)0xffff800000a00000;
	int i;


	for(i = 0 ;i<1440*20;i++)
	{
		*((char *)addr+0)=(char)0x00;
		*((char *)addr+1)=(char)0x00;
		*((char *)addr+2)=(char)0xff;
		*((char *)addr+3)=(char)0x00;	
		addr +=1;	
	}
	for(i = 0 ;i<1440*20;i++)
	{
		*((char *)addr+0)=(char)0x00;
		*((char *)addr+1)=(char)0xff;
		*((char *)addr+2)=(char)0x00;
		*((char *)addr+3)=(char)0x00;	
		addr +=1;	
	}
	for(i = 0 ;i<1440*20;i++)
	{
		*((char *)addr+0)=(char)0xff;
		*((char *)addr+1)=(char)0x00;
		*((char *)addr+2)=(char)0x00;
		*((char *)addr+3)=(char)0x00;	
		addr +=1;	
	}
	for(i = 0 ;i<1440*20;i++)
	{
		*((char *)addr+0)=(char)0xff;
		*((char *)addr+1)=(char)0xff;
		*((char *)addr+2)=(char)0xff;
		*((char *)addr+3)=(char)0x00;	
		addr +=1;	
	}
    while (1)
        ;
	return 0;
}