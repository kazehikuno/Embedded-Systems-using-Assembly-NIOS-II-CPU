/* Christopher Hays */
/* ECE 178 Assignment 4 Part 3*/
/* Spring 2015 */
/* Hardware interrupts with a custom NIOS II system */


.section .reset, "ax"	/* label the reset vector */
RESET:
	movia sp, 0xff0 	/* the end of the stack */
	br _start			/* branch to start */
	
.section .exceptions, "ax"	/* label the exception vector */
EXCEPTION_HANDLER:
	
	addi sp, sp, -0xc	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	rdctl et, ctl4		/* read the ipending register */
	andi et, et, 0x4	/* binary 100, because our button is assigned to interrupt 2 */
	beq et, r0, EXCEPTIONS_DONE		/* if no interrupts are pending we are done here */

	
CHECK_HARDWARE_INTERRUPTS:	/* check for interrupts in the desired order of priority */
	subi ea, ea, 4		/* decrement the ea because this is a hardware interrupt */
	andi r22, et, 0x4	/* check for IRQ2 */
	beq r22, r0, EXCEPTIONS_DONE		/* if IRQ2 is not present we are done */
	stw r0, 8(r20)		/* disable the pio interrupt before calling the ISR */
	stw r0, 0xc(r20)	/* clear the edge capture register of the pio */
	call isr0			/* call the ISR */
	
EXCEPTIONS_DONE:
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0xc	/* de-allocate stack */
	eret				/* return from the exception handler */

/* constants */

.equ switches, 0x00002000
.equ redleds, 0x00002010
.equ buttons, 0x00001010
.equ greenleds, 0x00001000
.equ hex0, 0x00001040
.equ hex1, 0x00001030
.equ pio, 0x00001050

/* main */

.global _start

_start:
	movia sp, 0xff0		/* create a stack pointer address */
	movia r20, pio		/* set base address of the pio interrupt */
	movia r19, 0x1		/* a register to hold a 1 constant */
	stw r19, 8(r20)		/* enable the pio interrupt */

	movia r2, switches	/* set base address of the switches */
	movia r3, redleds	/* same for LEDS, buttons, and seven-segments */
	movia r4, buttons
	movia r5, greenleds
	movia r9, hex0
	movia r10, hex1
	mov r7, r0			/* set our accumulator to zero */
	
	movia r11, 1		/* write 1 to the status register */
	wrctl status, r11	/* this enables global interrupts */
	movia r11, 0x4		/* enable interrupt 0b100, IRQ2 */
	wrctl ienable, r11	/* bits correspond to the interrupt request priority */
	

	
LOOP:
	stw r19, 8(r20)		/* enable the pio interrupt */
	nop
	br LOOP				/* the main program just loops */

	.global isr0		/* label the ISR */
isr0:
	subi sp, sp, 4		/* push ra to the stack */
	stwio ra, 0(sp)		/* because we are going to call a nested subroutine */

	ldbio r6, 0(r2) 	/* read switches */
	stbio r6, 0(r5)		/* output to green led */
	add r7, r7, r6		/* add switch value to r7 */
	stbio r7, 0(r3) 	/* output to red led */

	andi r12, r7, 0xf			/* mask the last 4 bits */
	call subroutine				/* call the 7 segment decoder */
	mov r16, r8					/* move result into r16 */
	
	andi r12, r7, 0xf0			/* mask the second to last 4 bits */
	srli r12, r12, 4			/* shift to right from left by 4 */
	call subroutine				/* call the 7 segment decoder */
	mov r15, r8					/* move result into r15 */
	
	stbio r15, 0(r10) 	/* output hex1 */
	stbio r16, 0(r9)	/* output hex0 */
	
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 4		/* de-allocate */
	ret					/* return */
	

	.global subroutine
	
subroutine:				/* the decoder, stores return value in r8 */
CASE0:
	subi r13, r12, 0x0
	bne r13, r0, CASE1
	movia r8, 0x000000c0
CASE1:
	subi r13, r12, 0x1
	bne r13, r0, CASE2
	movia r8, 0x000000f9
CASE2:
	subi r13, r12, 0x2
	bne r13, r0, CASE3
	movia r8, 0x000000a4
CASE3:
	subi r13, r12, 0x3
	bne r13, r0, CASE4
	movia r8, 0x00000030
CASE4:
	subi r13, r12, 0x4
	bne r13, r0, CASE5
	movia r8, 0x00000019
CASE5:
	subi r13, r12, 0x5
	bne r13, r0, CASE6
	movia r8, 0x00000012
CASE6:
	subi r13, r12, 0x6
	bne r13, r0, CASE7
	movia r8, 0x00000002
CASE7:
	subi r13, r12, 0x7
	bne r13, r0, CASE8
	movia r8, 0x00000078
CASE8:
	subi r13, r12, 0x8
	bne r13, r0, CASE9
	movia r8, 0x00000000
CASE9:
	subi r13, r12, 0x9
	bne r13, r0, CASEa
	movia r8, 0x00000018
CASEa:
	subi r13, r12, 0Xa
	bne r13, r0, CASEb
	movia r8, 0x00000008
CASEb:
	subi r13, r12, 0xb
	bne r13, r0, CASEc
	movia r8, 0x00000003
CASEc:
	subi r13, r12, 0xc
	bne r13, r0, CASEd
	movia r8, 0x00000046
CASEd:
	subi r13, r12, 0xd
	bne r13, r0, CASEe
	movia r8, 0x00000021
CASEe:
	subi r13, r12, 0xe
	bne r13, r0, CASEf
	movia r8, 0x00000006
CASEf:
	subi r13, r12, 0xf
	bne r13, r0, DONE
	movia r8, 0x0000000e
DONE:
ret
	
.end


