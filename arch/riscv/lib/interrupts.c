// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (c) 2016-17 Microsemi Corporation.
 * Padmarao Begari, Microsemi Corporation <padmarao.begari@microsemi.com>
 *
 * Copyright (C) 2017 Andes Technology Corporation
 * Rick Chen, Andes Technology Corporation <rick@andestech.com>
 */

#include <common.h>
#include <asm/ptrace.h>
#include <asm/system.h>
#include <asm/encoding.h>

/*static void _exit_trap(int code, uint epc, struct pt_regs *regs);*/

int interrupt_init(void)
{
	return 0;
}

/*
 * enable interrupts
 */
void enable_interrupts(void)
{
}

/*
 * disable interrupts
 */
int disable_interrupts(void)
{
	return 0;
}
void bad_trap(uintptr_t* regs, uintptr_t dummy, uintptr_t mepc)
{
	volatile uint32_t i;

	while(1)
	{
		/* add code here */
		i++;				/* added some code as debugger hangs if in loop doing nothing */
		if(i == 0x1000)
			i = 0;
	}
}

void pmp_trap(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc)
{

}
void illegal_insn_trap(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc)
{
	uintptr_t mstatus = read_csr(mstatus);
	uintptr_t insn = read_csr(mbadaddr);

	volatile uint32_t i;

	while(1)
	{
		/* add code here */
		i++;				/* added some code as debugger hangs if in loop doing nothing */
		if(i == 0x1000)
			i = 0;
	}
}
void misaligned_store_trap(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc)
{
	volatile uint32_t i;

	while(1)
	{
		/* add code here */
		i++;				/* added some code as debugger hangs if in loop doing nothing */
		if(i == 0x1000)
			i = 0;
	}
}
void misaligned_load_trap(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc)
{
	volatile uint32_t i;

	while(1)
	{
		/* add code here */
		i++;				/* added some code as debugger hangs if in loop doing nothing */
		if(i == 0x1000)
			i = 0;
	}
}
void mcall_trap(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc)
{


}
void handle_m_ext_interrupt(void)
{

}
/*------------------------------------------------------------------------------
 *
 */
void handle_local_interrupt(uint8_t interrupt_no)
{

}

/*------------------------------------------------------------------------------
 * RISC-V interrupt handler for machine timer interrupts.
 */
void handle_m_timer_interrupt(struct pt_regs *regs)
{
	timer_interrupt(regs);
}


/**
 *
 */
void handle_m_soft_interrupt(void)
{

}
void trap_from_machine_mode(uintptr_t * regs, uintptr_t dummy, uintptr_t mepc)
{
  uintptr_t mcause = read_csr(mcause);

  if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_EXT))
  {
      handle_m_ext_interrupt();
  }
  else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE)  > 15)&& ((mcause & MCAUSE_CAUSE)  < 63))
  {
      handle_local_interrupt(mcause & MCAUSE_CAUSE);
  }
  else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_TIMER))
  {
      handle_m_timer_interrupt(regs);
  }
  else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_SOFT))
  {
      handle_m_soft_interrupt();
  }
  else
  {
#if 1
	volatile uint32_t i;

	while(1)
	{
		/* add code here */
		i++;				/* added some code as debugger hangs if in loop doing nothing */
		if(i == 0x1000)
			i = 0;
	}
	switch(mcause)
	{

		case CAUSE_LOAD_PAGE_FAULT:
		case CAUSE_STORE_PAGE_FAULT:
		case CAUSE_FETCH_ACCESS:
		case CAUSE_LOAD_ACCESS:
		case CAUSE_STORE_ACCESS:
			//pse_printf("%s(): mcause: %x\n", __func__, mcause);
			break;
		default:
			bad_trap(regs, dummy, mepc);
	}
#else
	//write(1, "trap\n", 5);
	//_exit(1 + mcause);
#endif

  }

}
#if 0
uint handle_trap(uint mcause, uint epc, struct pt_regs *regs)
{
	uint is_int;

	is_int = (mcause & MCAUSE_INT);
	if ((is_int) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_EXT))
		external_interrupt(0);	/* handle_m_ext_interrupt */
	else if ((is_int) && ((mcause & MCAUSE_CAUSE)  == IRQ_M_TIMER))
		timer_interrupt(0);	/* handle_m_timer_interrupt */
	else
		_exit_trap(mcause, epc, regs);

	return epc;
}

/*
 *Entry Point for PLIC Interrupt Handler
 */
__attribute__((weak)) void external_interrupt(struct pt_regs *regs)
{
}

__attribute__((weak)) void timer_interrupt(struct pt_regs *regs)
{
}

static void _exit_trap(int code, uint epc, struct pt_regs *regs)
{
	static const char * const exception_code[] = {
		"Instruction address misaligned",
		"Instruction access fault",
		"Illegal instruction",
		"Breakpoint",
		"Load address misaligned"
	};

	printf("exception code: %d , %s , epc %08x , ra %08lx\n",
		code, exception_code[code], epc, regs->ra);
}
#endif
