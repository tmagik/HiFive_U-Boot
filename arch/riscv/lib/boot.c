// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (C) 2017 Andes Technology Corporation
 * Rick Chen, Andes Technology Corporation <rick@andestech.com>
 */

#include <common.h>
#include <command.h>

unsigned long do_go_exec(ulong (*entry)(int, char * const []),
			 int argc, char * const argv[])
{
	cleanup_before_linux();
	*((volatile uint32_t *)(0x2000004)) = 0x1;
	*((volatile uint32_t *)(0x2000008)) = 0x1;
	*((volatile uint32_t *)(0x200000C)) = 0x1;
	*((volatile uint32_t *)(0x2000010)) = 0x1;
	return entry(argc, argv);
}
