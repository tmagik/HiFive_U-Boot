/* SPDX-License-Identifier:	GPL-2.0+ */
/*
 * Copyright (C) 2018 Microsemi Corporation.
 * Padmarao Begari <Padmarao.Begari@microsemi.com>
 */


#include <common.h>
#include <asm/io.h>
#include <asm/encoding.h>

#if __riscv_xlen == 64 || __riscv64
	volatile uint64_t* mtime = (volatile uint64_t*)HIFIVE_BASE_MTIME;
	volatile uint64_t* timecmp = (volatile uint64_t*)HIFIVE_BASE_TIMECMP;
#else
 	volatile uint32_t* mtime = (volatile uint32_t*)HIFIVE_BASE_MTIME;
	volatile uint32_t* timecmp = (volatile uint32_t*)HIFIVE_BASE_TIMECMP;
#endif

#define CONFIG_SYS_RTCCLK_FREQ		1000000

volatile ulong timestamp = 0UL;

void timer_interrupt(struct pt_regs *regs)
{
    clear_csr(mie, MIP_MTIP);
    timestamp++;
    *timecmp = *mtime + CONFIG_SYS_RTCCLK_FREQ;
    set_csr(mie, MIP_MTIP);
}

int timer_init(void)
{
#if 0
    timestamp = 0;
    if (mtime && timecmp)
    {
    	*timecmp = *mtime + CONFIG_SYS_RTCCLK_FREQ;
    }
    set_csr(mie, MIP_MTIP);
    set_csr(mstatus, MSTATUS_MIE);
#endif
	return 0;
}

/*
 * return difference between timer ticks and base
 */
ulong get_timer(ulong base)
{
	return timestamp - base;
}

/* delay x useconds AND preserve advance timestamp value */
void __udelay(unsigned long usec)
{
	/*u32 i;
	i = get_timer(0);
	while ((get_timer(0) - i) < (usec / 1000));*/
	while(usec--);
}

/*
 * This function is derived from PowerPC code (read timebase as long long).
 * On RISC-V it just returns the timer value.
 */
unsigned long long get_ticks(void)
{
	return get_timer(0);
}

/*
 * This function is derived from PowerPC code (timebase clock frequency).
 * On RISC-V it returns the number of timer ticks per second.
 */
ulong get_tbclk(void)
{

	return CONFIG_SYS_HZ;
}
