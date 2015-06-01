/* Christopher Hays */
/* ECE 178 Final Project */
/* Spring 2015 */
/* SPI interface and SD card */
/* Read a sector of the card and output to vga */


/******** RESET VECTOR ********/
/******************************/

.section .reset, "ax"	/* label the reset vector */
reset:
	movia sp, 0xff0 	/* the end of the stack */
	br _start			/* branch to start */
	
	
/******** EXCEPTION VECTOR ********/
/**********************************/

.section .exceptions, "ax"	/* label the exception vector */
exception_handler:
	addi sp, sp, -0x4		/* allocate stack */
	stw ra, 0(sp)			/* store ra */
	
exceptions_done:
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	eret				/* return from the exception handler */


/******** CONSTANTS ********/
/***************************/

.equ switches, 0x24c0
.equ led_red, 0x24d0
.equ jtag, 0x24e8
.equ led_green, 0x24b0
.equ hex0, 0x24a0
.equ hex1, 0x2490
.equ keys, 0x2480
.equ sram, 0x100000
.equ timer, 0x2420
.equ timer_2, 0x2400
.equ lfsr, 0x2470
.equ binary_out, 0x2460
.equ bcd_in, 0x2450
.equ gpio, 0x2440
.equ sd_card, 0x2000
.equ sd_ram, 0x800000
.equ lcd, 0x1000
.equ char_addr, 0x4000


/******** START ********/
/***********************/

.global _start														

_start:
	movia r2, 0x1		/* a register to hold a 1 constant */
	movia sp, 0xff0		/* create a stack pointer address */
	movia r3, 0x0		/* register for computation results */
	movia r4, 0x0		/* return subroutine values here */
		
	movia r6, sd_card	/* the sd card base address */
	movia r7, led_red	/* red led base address */
	
	movia r20, 768		/* the current sector of the sd card */
	movia r21, 0x0		/* sd buffer byte index */
	
	movia r9, char_addr		/* base address of the vga character buffer */
	movia r15, 0x1			/* cursor x position */
	movia r16, 0x1			/* cursor y position */
	slli r10, r16, 7		/* multiply y by 128 */
	add r10, r10, r15		/* add x to this, starting at position 1,1 (x,y) */
	add r9, r9, r10			/* add to base address */
							/* position formula is (x + 128*y) */
	

/******** MAIN ********/
/**********************/	

main:
	call read_sd		/* read the sd card into the buffer */
	call delay			/* delay */
	call display		/* output to the vga */

end_main:
	br end_main
	
	
/******** SUBROUTINES ********/
/*****************************/

.global delay
delay:
	addi sp, sp, -0x4		/* allocate stack */
	stw ra, 0(sp)			/* store ra */

	movia r3, 1250000 
delay_loop:					/* delay loop */
	subi r3, r3, 1
	bne	r3, r0, delay_loop
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret

.global read_sd				/* read the sd card */
read_sd:
	addi sp, sp, -0x4		/* allocate stack */
	stw ra, 0(sp)			/* store ra */
	
verify:
	ldwio r3, 564(r6)		/* read the ASR of the SD Card IP Core */
	stwio r3, 0(r7)			/* output to red leds for debugging */
	andi r3, r3, 0x2		/* check for bit 1 */
	beq r3, r0, verify		/* loop if no card present */
	
	mov r3, r20				/* we want to read the current sector */
	slli r3, r3, 9			/* multiply by 512: shift logical left */
	stwio r3, 556(r6)		/* write this address to the CMDARG register */
	
	movia r3, 0x0011		/* read_block command */
	stwio r3, 560(r6)		/* write to CMD reg */
	
card_busy:
	ldwio r3, 564(r6)		/* read the ASR */
	stwio r3, 0(r7)			/* output to red leds for debugging */
	andi r3, r3, 0x4		/* check for bit 2 */
	bne r3, r0, card_busy	/* loop if busy */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret

.global write_sd			/* write to the sd card */
write_sd:
	addi sp, sp, -0x4		/* allocate stack */
	stw ra, 0(sp)			/* store ra */
	
verify_write:
	ldwio r3, 564(r6)				/* read the ASR of the SD Card IP Core */
	stwio r3, 0(r7)					/* output to red leds for debugging */
	andi r3, r3, 0x2				/* check for bit 1 */
	beq r3, r0, verify_write		/* loop if no card present */
	
	mov r3, r20				/* we want to write to the current sector */
	slli r3, r3, 9			/* multiply by 512 */
	stwio r3, 556(r6)		/* write this address to the CMDARG register */
	
	movia r3, 0x0018		/* write_block command */
	stwio r3, 560(r6)		/* write to CMD reg */
	
card_busy_write:
	ldwio r3, 564(r6)				/* read the ASR */
	stwio r3, 0(r7)					/* output to red leds for debugging */
	andi r3, r3, 0x4				/* check for bit 2 */
	bne r3, r0, card_busy_write		/* loop if busy */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret
	
.global display				/* writes the buffer to the vga */
display:
	addi sp, sp, -0x4		/* allocate stack */
	stw ra, 0(sp)			/* store ra */
	
	movia r21, 0x0			/* buffer byte index */
	
write_char:
	add r4, r21, r6				/* add buffer index to base address of buffer */
	ldbio r3, (r4)				/* read where the buffer index is pointing */
	
								/* calculate cursor position */
	slli r10, r16, 7			/* multiply y by 128 */
	add r10, r10, r15			/* add x to this */
	add r10, r9, r10			/* add to base address */
	
	stbio r3, 0(r10)			/* output character to vga */
	addi r15, r15, 1			/* increment the cursor x position */
	
	subi r3, r15, 79			/* check if 79 characters have been */
	bne r3, r0, continue_write	/* written to this line */
	addi r16, r16, 1			/* if so, increment y coordinate */
	movia r15, 0x1				/* set x coordinate to 1 */
	
continue_write:	
	addi r21, r21, 1			/* increment the buffer index */
	subi r3, r21, 512			/* buffer index - 512 */
	bne r3, r0, write_char		/* if zero we are done with the sector*/
	
	ldw ra, 0(sp)			/* restore the return address */
	addi sp, sp, 0x4		/* de-allocate stack */
	ret
	
.end
