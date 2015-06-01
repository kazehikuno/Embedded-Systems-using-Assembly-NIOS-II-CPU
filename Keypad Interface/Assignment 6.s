/* Christopher Hays */
/* ECE 178 Assignment 6 */
/* Spring 2015 */
/* Keypad interface */



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
	addi sp, sp, -0x4	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	eret				/* return from the exception handler */

	
/******** CONSTANTS ********/
/***************************/

.equ redleds, 0x00002010
.equ greenleds, 0x00001000
.equ gpio, 0x00001140
.equ binary_out, 0x00001130
.equ bcd_in, 0x00001120
.equ hex0, 0x00001040
.equ hex1, 0x00001030
.equ hex2, 0x000010e0
.equ hex3, 0x000010d0
.equ hex4, 0x000010c0
.equ hex5, 0x000010b0
.equ hex6, 0x000010a0
.equ hex7, 0x00001010

.equ key_table, 0x320					/* the address of the lookup tables */
.equ seven_segment_lookup, 0x420


/******** START ********/
/***********************/

.global _start														

_start:
	movia r2, 0x1		/* a register to hold a 1 constant */
	movia sp, 0xff0		/* create a stack pointer address */
	
	call clear_display
	
	movia r4, gpio
	movia r5, redleds
	movia r6, greenleds
	movia r15, binary_out
	movia r16, bcd_in
	
	movia r3, 0x7
	stwio r3, 4(r4)		/* set inputs and outputs of gpio */
	
	
/******** MAIN ********/
/**********************/	
	
main_loop:
	movia r23, 0x0			/* no key press flag*/
	movia r22, 0x0			/* position of the current key */
	
	movia r3, 0b110			/* ground the first column */
	stwio r3, 0(r4)			/* output to gpio */
	call check_key			/* scan the rows */
	beq r23, r0, first_done		/* call display if key press */
	call display
first_done:
	
	movia r3, 0b101			/* ground the second column */
	stwio r3, 0(r4)			/* output to gpio */
	call check_key			/* scan the rows */
	beq r23, r0, second_done	/* call display if key press */
	call display
second_done:
	
	movia r3, 0b011			/* ground the third column */
	stwio r3, 0(r4)			/* output to gpio */
	call check_key			/* scan the rows */
	beq r23, r0, third_done		/* call display if key press */
	call display
third_done:

	br main_loop
	
	
/******** SUBROUTINES ********/
/*****************************/
.global check_key		/* scans the rows for a key press */
check_key:
	addi sp, sp, -0x4	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	movia r7, 0x4		/* counter to loop 4 times */
	ldwio r3, 0(r4)		/* read the gpio input */
	andi r10, r3, 0x78	/* mask input bits, store in r10 */
	stwio r3, 0(r6)		/* output to green leds */
check_loop:
	srli r10, r10, 0x1				/* shift logical right */
	andi r3, r10, 0x4				/* mask bit 2 */
	bne r3, r0, continue_scan		/* if zero call debounce */
	call debounce
continue_scan:
	addi r22, r22, 0x1			/* increment the key counter */
	subi r7, r7, 0x1			/* decrement row counter */
	bne r7, r0, check_loop		/* loop if not zero */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret
	
.global debounce		/* debounces the current key press */
debounce:
	addi sp, sp, -0x4	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
debounce_loop:			/* loops until the input is all ones */
						/* the key has been let go */
	ldwio r3, 0(r4)		/* read the gpio input */
	andi r11, r3, 0x78	/* mask input bits, store in r11 */
	
	srli r11, r11, 0x1			/* shift logical right */
	andi r3, r11, 0x4			/* mask bit 2 */
	beq r3, r0, debounce_loop	/* if zero, start the loop over */
	
	srli r11, r11, 0x1
	andi r3, r11, 0x4
	beq r3, r0, debounce_loop
	
	srli r11, r11, 0x1
	andi r3, r11, 0x4
	beq r3, r0, debounce_loop
	
	srli r11, r11, 0x1
	andi r3, r11, 0x4
	beq r3, r0, debounce_loop
	
	addi r23, r23, 0x1		/* set the key pressed flag */
	movia r7, 0x1			/* set the scan loop counter */
	subi r22, r22, 0x1		/* correct the key position */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret
	
.global display			/* displays the current key press */
display:
	addi sp, sp, -0x8	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	movia r8, key_table
	add r20, r8, r22	/* add key position to the lookup table address */
	ldbio r22, 0(r20)	/* read the byte at this address */
						/* now we have the final key value */
	stwio r22, 0(r5)	/* write key value to the red leds */
	
	movia r8, seven_segment_lookup
	stwio r22, 0(r15)	/* write to binary out */
	nop
	ldwio r22, 0(r16)	/* read the bcd in */
	stw r22, 4(sp)		/* write the bcd to the stack */
	
	andi r22, r22, 0xf	/* mask lower 4 bits */
	add r20, r8, r22	/* add bcd value to table address */
	ldbio r22, 0(r20)	/* read decoded value */
	movia r8, hex0		/* 7 segment address */
	stwio r22, 0(r8)	/* write to seven segment */
	
	movia r8, seven_segment_lookup
	ldw r22, 4(sp)		/* load from the stack */
	andi r22, r22, 0xf0	/* mask middle 4 bits */
	srli r22, r22, 4	/* shift right logical */
	add r20, r8, r22	/* add bcd value to table address */
	ldbio r22, 0(r20)	/* read decoded value */
	movia r8, hex1		/* 7 segment address */
	stwio r22, 0(r8)	/* write to seven segment */
	
	movia r23, 0x0		/* clear the key pressed flag */
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x8	/* de-allocate stack */
	ret

.global clear_display
clear_display:
	addi sp, sp, -0x4	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	movia r3, 0xff		/* clear the 7 segments */
	movia r4, hex0
	stwio r3, 0(r4)
	movia r4, hex1
	stwio r3, 0(r4)
	movia r4, hex2
	stwio r3, 0(r4)
	movia r4, hex3
	stwio r3, 0(r4)
	movia r4, hex4
	stwio r3, 0(r4)
	movia r4, hex5
	stwio r3, 0(r4)
	movia r4, hex6
	stwio r3, 0(r4)
	movia r4, hex7
	stwio r3, 0(r4)
	
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	ret
	
.org 0x300
key_lookup_table:
.byte 11, 9, 6, 3, 0, 8, 5, 2, 10, 7, 4, 1	

.org 0x400
seven_segment_lookup:
.byte 0xc0, 0xf9, 0xa4, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x18

.end


