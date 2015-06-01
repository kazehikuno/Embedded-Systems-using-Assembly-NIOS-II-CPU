/* Christopher Hays */
/* ECE 178 Assignment 4 Part 1 */
/* Spring 2015 */
/* Accumulating Input with a custom NIOS II system */


.include "subroutine.s"

.equ switches, 0x00002000
.equ redleds, 0x00002010
.equ buttons, 0x00001010
.equ greenleds, 0x00001000
.equ hex0, 0x00001040
.equ hex1, 0x00001030

.global _start

_start:
	movia r2, switches		/* base addresses of the PIO modules */
	movia r3, redleds
	movia r4, buttons
	movia r5, greenleds
	movia r9, hex0
	movia r10, hex1
	movia r7, 0x0			/* start the accumulator at zero */
	
LOOP:
	ldbio r6, 0(r2) 	/* read switches */
	stbio r6, 0(r5)		/* output to green led */
	add r7, r7, r6		/* add switch value to r7 */
	stbio r7, 0(r3) 	/* output to red led */

	andi r12, r7, 0x0000000f	/* mask the last 4 bits */
	call subroutine				/* call the 7 segment decoder */
	mov r16, r8					/* move result into r16 */
	
	andi r12, r7, 0x000000f0	/* mask the second to last 4 bits */
	srli r12, r12, 4			/* shift from right to left by 4 */
	call subroutine
	mov r15, r8					/* move result into r15 */

	
	stbio r15, 0(r10) 	/* output hex1 */
	stbio r16, 0(r9)	/* output hex0 */
	
	
	/* delay = (2 + 2*12500000 + 1)*20ns clock = approx 0.5 seconds */
	movia r23, 12500000 
DELAY:
	subi r23, r23, 1
	bne	r23, r0, DELAY

	
	br LOOP
	
.end
/* debounce

movia r21, 0x0
count:
	ldwio r3, 0(r4) /* read gpio */
	andi r3, r3, 0x78
	xori r3, r3, 0x78
	bne r3, r0, count
	addi r21, r21, 0x1
	subi r3, r21, 0x4
	bne r3, r0, count
	
*/