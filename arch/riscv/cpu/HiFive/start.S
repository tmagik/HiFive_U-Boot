/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Startup Code for RISC-V Core
 *
 * Copyright (c) 2017 Microsemi Corporation.
 * Copyright (c) 2017 Padmarao Begari <Padmarao.Begari@microsemi.com>
 *
 * Copyright (C) 2017 Andes Technology Corporation
 * Rick Chen, Andes Technology Corporation <rick@andestech.com>
 */

#include <asm-offsets.h>
#include <config.h>
#include <common.h>
#include <elf.h>
#include <asm/encoding.h>
#include <asm/mtrap.h>

#ifdef CONFIG_32BIT
#define LREG            lw
#define SREG            sw
#define REGBYTES        4
#define RELOC_TYPE      R_RISCV_32
#define SYM_INDEX       0x8
#define SYM_SIZE        0x10
#else
#define LREG            ld
#define SREG            sd
#define REGBYTES        8
#define RELOC_TYPE      R_RISCV_64
#define SYM_INDEX       0x20
#define SYM_SIZE        0x18
#endif

#define BAD_TRAP_VECTOR                (0)
#define TRAP_FROM_MACHINE_MODE_VECTOR (13)

  .data
  .align 6
trap_table:
  .word bad_trap
  .word pmp_trap
  .word illegal_insn_trap
  .word bad_trap
  .word misaligned_load_trap
  .word pmp_trap
  .word misaligned_store_trap
  .word pmp_trap
  .word bad_trap
  .word mcall_trap
  .word bad_trap
  .word bad_trap
  .word bad_trap
  .word __trap_from_machine_mode
  .word bad_trap
  .word bad_trap


  .option norvc
  .section .text,"ax",@progbits
  .globl reset_vector
  .globl _start
  reset_vector:
_start:
  j do_reset

trap_vector:
#The mscratch register is an XLEN-bit read/write register dedicated for use by machine mode.
#Typically, it is used to hold a pointer to a machine-mode hart-local context space and swapped
#with a user register upon entry to an M-mode trap handler.
  csrrw sp, mscratch, sp                    #copy sp to mscratch, and mscrath to sp
  beqz sp, .Ltrap_from_machine_mode         #if zero, no HLS, jump

  SREG a0, 10*REGBYTES(sp)                 # we are now using HLS
  SREG a1, 11*REGBYTES(sp)                 # save a0, a1

  csrr a1, mcause                           #save cause in a1
  bgez a1, .Lhandle_trap_in_machine_mode

  # This is an interrupt.  Discard the mcause MSB and decode the rest.
  sll a1, a1, 1

  # Is it a machine timer interrupt?
  li a0, IRQ_M_TIMER * 2
  bne a0, a1, 1f

  # Yes. Simply clear MSIE and raise SSIP
  li a0, MIP_MTIP
  csrc mie, a0
  li a0, MIP_STIP
  csrs mip, a0

.Lmret:
  # Go back to whence we came.
  LREG a0, 10*REGBYTES(sp)
  LREG a1, 11*REGBYTES(sp)
  csrrw sp, mscratch, sp
  mret

1:
  # Is it an IPI?
  li a0, IRQ_M_SOFT * 2
  bne a0, a1, .Lbad_trap

  li s1, 0x2000000
  csrr s2, mhartid
  slli s2, s2, 2
  add s2, s2, s1
  sw zero, 0(s2)

  j .Lmret
  # Yes. First clear the MIPI bit.
  LREG a0, MENTRY_IPI_OFFSET(sp)
  sw x0, (a0)
  fence

  # Now, decode the cause(s).
#ifdef __riscv_atomic
  addi a0, sp, MENTRY_IPI_PENDING_OFFSET
  amoswap.w a0, x0, (a0)
#else
# error "only supporting atomic right now"
#endif
  and a1, a0, IPI_SOFT
  beqz a1, 1f
  csrs mip, MIP_SSIP
1:
  andi a1, a0, IPI_FENCE_I
  beqz a1, 1f
  fence.i
1:
  andi a1, a0, IPI_SFENCE_VMA
  beqz a1, 1f
  # sfence.vma - TODO
1:
  j .Lmret

.Lhandle_trap_in_machine_mode:
  # Preserve the registers.  Compute the address of the trap handler.
  SREG ra, 1*REGBYTES(sp)
  SREG gp, 3*REGBYTES(sp)
  SREG tp, 4*REGBYTES(sp)
  SREG t0, 5*REGBYTES(sp)
1:auipc t0, %pcrel_hi(trap_table)  # t0 <- %hi(trap_table)
  SREG t1, 6*REGBYTES(sp)
  sll t1, a1, 2                    # t1 <- mcause << 2
  SREG t2, 7*REGBYTES(sp)
  add t1, t0, t1                   # t1 <- %hi(trap_table)[mcause]
  SREG s0, 8*REGBYTES(sp)
  LWU t1, %pcrel_lo(1b)(t1)         # t1 <- trap_table[mcause]
  SREG s1, 9*REGBYTES(sp)
  mv a0, sp                        # a0 <- regs
  SREG a2,12*REGBYTES(sp)
  csrr a2, mepc                    # a2 <- mepc
  SREG a3,13*REGBYTES(sp)
  csrrw t0, mscratch, x0           # t0 <- user sp
  SREG a4,14*REGBYTES(sp)
  SREG a5,15*REGBYTES(sp)
  SREG a6,16*REGBYTES(sp)
  SREG a7,17*REGBYTES(sp)
  SREG s2,18*REGBYTES(sp)
  SREG s3,19*REGBYTES(sp)
  SREG s4,20*REGBYTES(sp)
  SREG s5,21*REGBYTES(sp)
  SREG s6,22*REGBYTES(sp)
  SREG s7,23*REGBYTES(sp)
  SREG s8,24*REGBYTES(sp)
  SREG s9,25*REGBYTES(sp)
  SREG s10,26*REGBYTES(sp)
  SREG s11,27*REGBYTES(sp)
  SREG t3,28*REGBYTES(sp)
  SREG t4,29*REGBYTES(sp)
  SREG t5,30*REGBYTES(sp)
  SREG t6,31*REGBYTES(sp)
  SREG t0, 2*REGBYTES(sp)         # sp

#ifndef __riscv_flen
  # commented out line below-  Not being used- cause issue with FreeRTOS
  #lw tp, (sp) # Move the emulated FCSR from x0's save slot into tp.
#endif
  SREG x0, (sp) # Zero x0's save slot.

  # Invoke the handler.
  jalr t1

#ifndef __riscv_flen
  # commented out line below-  Not being used- cause issue with FreeRTOS
  #sw tp, (sp) # Move the emulated FCSR from tp into x0's save slot.
#endif

restore_mscratch:
  # Restore mscratch, so future traps will know they didn't come from M-mode.
  csrw mscratch, sp

restore_regs:
  # Restore all of the registers.
  LREG ra, 1*REGBYTES(sp)
  LREG gp, 3*REGBYTES(sp)
  LREG tp, 4*REGBYTES(sp)
  LREG t0, 5*REGBYTES(sp)
  LREG t1, 6*REGBYTES(sp)
  LREG t2, 7*REGBYTES(sp)
  LREG s0, 8*REGBYTES(sp)
  LREG s1, 9*REGBYTES(sp)
  LREG a0,10*REGBYTES(sp)
  LREG a1,11*REGBYTES(sp)
  LREG a2,12*REGBYTES(sp)
  LREG a3,13*REGBYTES(sp)
  LREG a4,14*REGBYTES(sp)
  LREG a5,15*REGBYTES(sp)
  LREG a6,16*REGBYTES(sp)
  LREG a7,17*REGBYTES(sp)
  LREG s2,18*REGBYTES(sp)
  LREG s3,19*REGBYTES(sp)
  LREG s4,20*REGBYTES(sp)
  LREG s5,21*REGBYTES(sp)
  LREG s6,22*REGBYTES(sp)
  LREG s7,23*REGBYTES(sp)
  LREG s8,24*REGBYTES(sp)
  LREG s9,25*REGBYTES(sp)
  LREG s10,26*REGBYTES(sp)
  LREG s11,27*REGBYTES(sp)
  LREG t3,28*REGBYTES(sp)
  LREG t4,29*REGBYTES(sp)
  LREG t5,30*REGBYTES(sp)
  LREG t6,31*REGBYTES(sp)
  LREG sp, 2*REGBYTES(sp)
  mret

.Ltrap_from_machine_mode:
  csrr sp, mscratch                      # copy the mscratch to sp. mscratch can the the actual sp memory pointer or HLS at this point, depends on if HLS non-zero or not
  addi sp, sp, -INTEGER_CONTEXT_SIZE     # moves sp down stack to make INTEGER_CONTEXT_SIZE area
  SREG a0, 10*REGBYTES(sp)              # save a0,a1 in the created CONTEXT
  SREG a1, 11*REGBYTES(sp)
  li a1, TRAP_FROM_MACHINE_MODE_VECTOR   # not sure where we use this
  j .Lhandle_trap_in_machine_mode

.Lbad_trap:
  li a1, BAD_TRAP_VECTOR
  j .Lhandle_trap_in_machine_mode

  .globl __redirect_trap
__redirect_trap:
  # Reset sp to top of M-Mode stack
  li t0, MACHINE_STACK_SIZE
  add sp, sp, t0
  neg t0, t0
  and sp, sp, t0
  addi sp, sp, -MENTRY_FRAME_SIZE
  j restore_mscratch

__trap_from_machine_mode:
  jal trap_from_machine_mode
  j restore_regs

do_reset:
  la t0, trap_vector
  csrw mtvec, t0                    # initalise machine trap vector address
  csrw mie, 0
#  csrw mstatus, 0

  li  x1, 0
  li  x2, 0
  li  x3, 0
  li  x4, 0
  li  x5, 0
  li  x6, 0
  li  x7, 0
  li  x8, 0
  li  x9, 0
  li  x10,0
  li  x11,0
  li  x12,0
  li  x13,0
  li  x14,0
  li  x15,0
  li  x16,0
  li  x17,0
  li  x18,0
  li  x19,0
  li  x20,0
  li  x21,0
  li  x22,0
  li  x23,0
  li  x24,0
  li  x25,0
  li  x26,0
  li  x27,0
  li  x28,0
  li  x29,0
  li  x30,0
  li  x31,0
  csrw mscratch, 0
  # enable FPU and accelerator if present
  li t0, MSTATUS_FS | MSTATUS_XS
  csrs mstatus, t0

  # make sure XLEN agrees with compilation choice
  csrr t0, misa
#if __riscv_xlen == 64
  bltz t0, .LxlenCheck
#else
  bgez t0, .LxlenCheck
#endif
.LxlenCheck:

  # initialize global pointer, global data
  # The __global_pointer is allocated in the linker script. It points to a location 2k after sdata start
  # as the offsets used in the gp are +/- 2k
  # This location is a magic number that is used by the compiler
  # once
  # The sdata can be upto 4k
  # See https://www.sifive.com/blog/2017/08/28/all-aboard-part-3-linker-relaxation-in-riscv-toolchain/
  # fixme: did not like the above code, interrupt handler crashed when code below used >>>
  #.option push
  #.option norelax
  #1:auipc gp, %pcrel_hi(__global_pointer$)
  #addi  gp, gp, %pcrel_lo(1b)
  #.option pop
  # fixme: did not like the above code, interrupt handler crashed when code above used <<<
  #la gp, __global_pointer$
 # la gp, _gp
  # see: http://www.rowleydownload.co.uk/arm/documentation/gnu/as/RISC_002dV_002dDirectives.html
  #.option push
  #.option norelax
  #la gp, __global_pointer$
  #.option pop

  # the following forces end alignment to 64byte boundery
  la  tp, __bss_end + 63
  and tp, tp, -64

  # get core id
  csrr a0, mhartid

  # give each core 128KB of stack + TLS
# #define STKSHIFT 17
  #changed to 1K for the emulation platform
  #define STKSHIFT 10
  sll a2, a0, STKSHIFT
  add tp, tp, a2
  add sp, a0, 1
  sll sp, sp, STKSHIFT
  add sp, sp, tp

  # get core id
  csrr a0, mhartid
  li a1, 1
  bgeu a0, a1, .LbootOtherHart
  # core 0 jumps to main_first_hart
  j call_board_init_f

.LendFirstHart:
  # while 1
  # L below added by maalchy, remove
#  j main_other_hart
#  j .LendFirstHart

.LbootOtherHart:
  # L below added by maalchy, remove
  #j main_other_hart
  # core 1 jumps to main_other_hart
  # Set MSIE bit to receive IPI
  li a2, MIP_MSIP
  csrw mie, a2

.LwaitOtherHart:
  # Wait for an IPI to signal that its safe to boot
  #malachy fixme added code below while debugging
  #csrc sstatus, SSTATUS_SIE
  #csrs sie, SIP_SSIP
  #csrs sip, SIP_SSIP
#  set_csr(mstatus, MSTATUS_MIE);
#  csrs mstatus, MSTATUS_MIE;         #generates sw interrupt
  #FIXME: The wfi instruction here is not stopping code on startup. Assume there is interrupt pending? Will return and investigate.
#  csrw mscratch, 0
 # csrw mcause, 0
 # csrw mepc, 0
  wfi
 # j main_other_hart
  # Only start if MIP_MSIP is set
  csrr a2, mip
  andi a2, a2, MIP_MSIP
  beqz a2, .LwaitOtherHart
  fence
  csrw mip, 0
  li a2, 5
  bltu a0, a2, .Lmain_other_hart
  #j .LendFirstHart
 # j main_other_hart
  j .LwaitOtherHart

.LendOtherHart:
  # while 1
  j .LendOtherHart

.Lmain_other_hart:
  li t4, 0x80000000
  jr t4
/*
 * Set stackpointer in internal/ex RAM to call board_init_f
 */
call_board_init_f:
    li  t0, -16
    li  t1, CONFIG_SYS_INIT_SP_ADDR
    and sp, t1, t0  /* force 16 byte alignment */

#ifdef CONFIG_DEBUG_UART
    jal debug_uart_init
#endif

call_board_init_f_0:
    mv  a0, sp
    jal board_init_f_alloc_reserve
    mv  sp, a0
    jal board_init_f_init_reserve

    mv  a0, zero    /* a0 <-- boot_flags = 0 */
    la t5, board_init_f
    jr t5       /* jump to board_init_f() */

/*
 * void relocate_code (addr_sp, gd, addr_moni)
 *
 * This "function" does not return, instead it continues in RAM
 * after relocating the monitor code.
 *
 */
.globl relocate_code
relocate_code:
    mv  s2, a0  /* save addr_sp */
    mv  s3, a1  /* save addr of gd */
    mv  s4, a2  /* save addr of destination */

/*
 *Set up the stack
 */
stack_setup:
    mv sp, s2
 /* with relocation */
#if 1
    la t0, _start
    sub t6, s4, t0  /* t6 <- relocation offset */
    beq t0, s4, clear_bss   /* skip relocation */
#endif
/* without relocation*/
#if 0
    la t0, _start
    li s5, CONFIG_SYS_TEXT_BASE
    sub t6, s5, t0  /* t6 <- relocation offset */
    beq t0, s5, clear_bss
    beq t0, s4, clear_bss  /* skip relocation */
#endif

    mv t1, s4   /* t1 <- scratch for copy_loop */
    la t3, __bss_start
    sub t3, t3, t0  /* t3 <- __bss_start_ofs */
    add t2, t0, t3  /* t2 <- source end address */

copy_loop:
    LREG t5, 0(t0)
    addi t0, t0, REGBYTES
    SREG t5, 0(t1)
    addi t1, t1, REGBYTES
    blt t0, t2, copy_loop

/*
 * Update dynamic relocations after board_init_f
 */
fix_rela_dyn:
    la  t1, __rel_dyn_start
    la  t2, __rel_dyn_end
    beq t1, t2, clear_bss
    add t1, t1, t6          /* t1 <- rela_dyn_start in RAM */
    add t2, t2, t6          /* t2 <- rela_dyn_end in RAM */

/*
 * skip first reserved entry: address, type, addend
 */
    bne t1, t2, 7f

6:
    LREG  t5, -(REGBYTES*2)(t1) /* t5 <-- relocation info:type */
    li  t3, R_RISCV_RELATIVE    /* reloc type R_RISCV_RELATIVE */
    bne t5, t3, 8f          /* skip non-RISCV_RELOC entries */
    LREG t3, -(REGBYTES*3)(t1)
    LREG t5, -(REGBYTES)(t1)    /* t5 <-- addend */
    add t5, t5, t6          /* t5 <-- location to fix up in RAM */
    add t3, t3, t6          /* t3 <-- location to fix up in RAM */
    sw t5, 0(t3)
7:
    addi t1, t1, (REGBYTES*3)
    ble t1, t2, 6b

8:
    la  t4, __dyn_sym_start
    add t4, t4, t6

9:
    LREG  t5, -(REGBYTES*2)(t1) /* t5 <-- relocation info:type */
    srli t0, t5, SYM_INDEX      /* t0 <--- sym table index */
    andi t5, t5, 0xFF       /* t5 <--- relocation type */
    li  t3, RELOC_TYPE
    bne t5, t3, 10f         /* skip non-addned entries */

    LREG t3, -(REGBYTES*3)(t1)
    li t5, SYM_SIZE
    mul t0, t0, t5
    add s1, t4, t0
    LREG t5, REGBYTES(s1)
    add t5, t5, t6          /* t5 <-- location to fix up in RAM */
    add t3, t3, t6          /* t3 <-- location to fix up in RAM */
    sw t5, 0(t3)
10:
    addi t1, t1, (REGBYTES*3)
    ble t1, t2, 9b

/*
 * trap update
*/
    la t0, trap_vector
    add t0, t0, t6
    csrw mtvec, t0

clear_bss:
    la t0, __bss_start      /* t0 <- rel __bss_start in FLASH */
    add t0, t0, t6          /* t0 <- rel __bss_start in RAM */
    la t1, __bss_end        /* t1 <- rel __bss_end in FLASH */
    add t1, t1, t6          /* t1 <- rel __bss_end in RAM */
    li t2, 0x00000000       /* clear */
    beq t0, t1, call_board_init_r

clbss_l:
    SREG t2, 0(t0)          /* clear loop... */
    addi t0, t0, REGBYTES
    bne t0, t1, clbss_l

/*
 * We are done. Do not return, instead branch to second part of board
 * initialization, now running from RAM.
 */
call_board_init_r:
    la t0, board_init_r
    mv t4, t0           /* offset of board_init_r() */
    add t4, t4, t6          /* real address of board_init_r() */
/*
 * setup parameters for board_init_r
 */
    mv a0, s3           /* gd_t */
    mv a1, s4           /* dest_addr */

/*
 * jump to it ...
 */
    jr t4               /* jump to board_init_r() */

