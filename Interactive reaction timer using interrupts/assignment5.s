/* Christopher Hays */
/* ECE 178 Assignment 5 */
/* Spring 2015 */
/* Interactive eye tracking hand coordination embedded system */



/******** RESET VECTOR ********/
/******************************/

.section .reset, "ax"	/* label the reset vector */
RESET:
	movia sp, 0xff0 	/* the end of the stack */
	br _start			/* branch to start */


/******** EXCEPTION VECTOR ********/
/**********************************/
	
.section .exceptions, "ax"	/* label the exception vector */
EXCEPTION_HANDLER:
	addi sp, sp, -0x4	/* allocate stack */
	stw ra, 0(sp)		/* store ra */
	
	rdctl et, ipending		/* read the ipending register into exception temporary reg */
	andi et, et, 0b111101	/* make sure it's one of the interrupts we are looking for */
	beq et, r0, EXCEPTIONS_DONE		/* if no interrupts are pending we are done here */

CHECK_HARDWARE_INTERRUPTS:	/* check for interrupts in the desired order of priority */
	subi ea, ea, 4			/* decrement the ea because this is a hardware interrupt */
	
CHECK0:
	andi r13, et, 0b00001	/* check for irq0, the timer */
	beq r13, r0, CHECK2
	
	stw r0, 0(r14)		/* clear the TO bit of the timer status register */
	call isr0			/* call the ISR */
	
CHECK2:
	andi r13, et, 0b00100	/* check for irq2, key3 "CLEAR" */
	beq r13, r0, CHECK3
	
	stw r0, 8(r23)		/* disable the pio interrupt before calling the ISR */
	stw r0, 0xc(r23)	/* clear the edge capture register of the pio */
	call isr2			/* call the ISR */
	stw r2, 8(r23)		/* enable the interrupt now that we are done */
	
CHECK3:
	andi r13, et, 0b01000	/* check for irq3, key2 "START" */
	beq r13, r0, CHECK4
	
	stw r0, 8(r22)		/* disable the pio interrupt before calling the ISR */
	stw r0, 0xc(r22)	/* clear the edge capture register of the pio */
	call isr3			/* call the ISR */
	stw r2, 8(r22)		/* enable the interrupt now that we are done */
	
CHECK4:
	andi r13, et, 0b10000	/* check for irq4, key1 "STOP" */
	beq r13, r0, CHECK5
	
	stw r0, 8(r21)		/* disable the pio interrupt before calling the ISR */
	stw r0, 0xc(r21)	/* clear the edge capture register of the pio */
	call isr4			/* call the ISR */
	stw r2, 8(r21)		/* enable the interrupt now that we are done */
	
CHECK5:
	andi r13, et, 0b100000			/* check for irq5 */
	beq	r13, r0, EXCEPTIONS_DONE
	
	call jtag_isr		/* call the jtag isr */

EXCEPTIONS_DONE:
	ldw ra, 0(sp)		/* restore the return address */
	addi sp, sp, 0x4	/* de-allocate stack */
	eret				/* return from the exception handler */

	
/******** CONSTANTS ********/
/***************************/

.equ redleds, 0x00002010
.equ greenleds, 0x00001000
.equ hex0, 0x00001040
.equ hex1, 0x00001030
.equ hex2, 0x000010e0
.equ hex3, 0x000010d0
.equ hex4, 0x000010c0
.equ hex5, 0x000010b0
.equ hex6, 0x000010a0
.equ hex7, 0x00001010
.equ key1, 0x000010f0
.equ key2, 0x00001100
.equ key3, 0x00001050
.equ timerbase, 0x00001080
.equ jtag, 0x00001020
.equ lfsr, 0x00001110
.equ binary_out, 0x00001130
.equ bcd_in, 0x00001120

.equ ms, 50000


/******** START ********/
/***********************/

.global _start														

_start:
	movia r2, 0x1		/* a register to hold a 1 constant */

	movia sp, 0xff0		/* create a stack pointer address */
	
	movia r23, key3		/* set base address of the key interrupts */
	movia r22, key2
	movia r21, key1		
	movia r20, hex4		/* set base address of the hex displays */
	movia r19, hex3
	movia r18, hex2
	movia r17, hex1
	movia r16, hex0
	movia r15, greenleds	/* set base address of green leds */
	movia r14, timerbase	/* set base address of the system timer */
	movia r10, lfsr			/* base of the lfsr PIO */ 
	movia r6, jtag			/* base of jtag */
	movia r7, binary_out 	/* base of binary output PIO */
	movia r8, bcd_in		/* base of bcd input PIO */
	
	stwio r2, 8(r23)		/* enable the key3 interrupt */
	stwio r2, 8(r22)		/* enable the key2 interrupt */
	stwio r2, 8(r21)		/* enable the key1 interrupt */

	wrctl status, r2	/* this enables global interrupts */
	movia r13, 0b111101	/* this enables specific interrupts jtag, irq4, irq3, irq2, timer */
	wrctl ienable, r13	/* bits correspond to the interrupt request priority */
	
	stwio r2, 4(r6)		/* enable the read interrupt for the jtag */
	
	movia r4, 0x0		/* the main millisecond counter */
	movia r5, 0x0		/* counter for random timer  */
	movia r11, 0x0		/* counter for LED flash */
	
	movia r3, 0x1 		/* the state register, begin in the READY state */
	
	movia r13, 0b1000		/* set timer into idle mode */
	stwio r13, 4(r14)		/* this sets the stop bit */
	
	
/******** MAIN ********/
/**********************/	
	
LOOP:
	/* r13 is the generic reg for operations */
	/* use r3 for the program state */
	
READY:
	subi r13, r3, 0x1			/* branch if we are NOT in state 1 */
	bne r13, r0, LED_OFF
	call ready_ini				/* initialize the ready state */
READY_LOOP:						/* loop in the ready state */
	subi r13, r3, 0x1
	beq r13, r0, READY_LOOP
	
LED_OFF:
	subi r13, r3, 0x2			/* branch if we are NOT in state 2 */
	bne r13, r0, LED_ON	
	call led_off_ini			/* initialize the led_off state */
LED_OFF_LOOP:					/* loop in led_off state */
	subi r13, r3, 0x2
	beq r13, r0, LED_OFF_LOOP
	
LED_ON:
	subi r13, r3, 0x3		/* branch if we are NOT in state 3 */
	bne r13, r0, STOPPED
	call led_on_ini			/* initialize the led_on state */
LED_ON_LOOP:				/* loop in led_on state */
	call flash				/* flash the leds */
	call display 			/* display the millisecond counter on 7-segments */
	subi r13, r3, 0x3		
	beq r13, r0, LED_ON_LOOP
	
STOPPED:
	subi r13, r3, 0x4		/* branch if we are NOT in state 4 */
	bne r13, r0, OUT_STATE
	call stopped_ini		/* initialize the stopped state */
STOPPED_LOOP:				/* loop in the stopped state */
	subi r13, r3, 0x4
	beq r13, r0, STOPPED_LOOP
	
OUT_STATE:
	subi r13, r3, 0x5			/* branch if NOT in state 5 */
	bne r13, r0, OOPS
	call out_state_ini			/* initialize the out state */
OUT_STATE_LOOP:					/* loop in out state */
	subi r13, r3, 0x5
	beq r13, r0, OUT_STATE_LOOP
	
OOPS:
	subi r13, r3, 0x6			/* branch if NOT in state 6 */
	bne r13, r0, END_MAIN
	call oops_ini				/* initialize the oops state */
OOPS_LOOP:						/* loop in oops state */
	subi r13, r3, 0x6
	beq r13, r0, OOPS_LOOP
	
END_MAIN:						/* end main */
	br LOOP				

	
/******** ISR SUBROUTINES ********/
/*********************************/
	
	.global isr0			/* define isr0, the timer interrupt */
isr0:
	subi r13, r3, 0x2		/* branch if we are NOT in state 2 */
	bne r13, r0, ISR0_NOTCASE2
	addi r5, r5, 0x1		/* increment the random timer counter */
	sub r13, r5, r9			/* check against random counter timeout value (set by lfsr) */
	beq r13, r0, SET_LED_ON /* branch if the random counter matches timeout value */
	ret
SET_LED_ON:
	movia r3, 0x3			/* set state as LED_ON */
	ret
ISR0_NOTCASE2:
	subi r13, r3, 0x3			/* branch if we are NOT in state 3 */
	bne r13, r0, SKIP_ISR0
	addi r4, r4, 0x1			/* increment the main millisecond counter */
	addi r11, r11, 0x1			/* increment the LED timeout counter */
	subi r13, r4, 1000			/* branch if a second has passed by with no input */
	beq r13, r0, SET_OUT
	ret
SET_OUT:
	movia r3, 0x5		/* set state as OUT_STATE */
SKIP_ISR0:				/* this ensures that isr0 does nothing when in the other states */
	ret					/* return */
	
	
	.global isr2		/* define isr2, the key3 interrupt "CLEAR" */
isr2:
	movia r3, 0x1		/* put the system into the READY state */
	movia r4, 0x0		/* set the main millisecond counter back to 0 */
	movia r5, 0x0		/* set the random timer counter to 0 */
	movia r11, 0x0		/* set the led timeout counter to 0 */
	ret	
	
	
	.global isr3		/* define isr3, the key2 interrupt "START" */
isr3:
	subi r13, r3, 0x1		/* branch if we are NOT in state 1 */
	bne r13, r0, SKIP_ISR3
	movia r3, 0x2		/* put the system into LED_OFF state */
SKIP_ISR3:				/* this ensures that isr3 does nothing when in the other states */
	ret					/* return */
	
	
	.global isr4		/* define isr4, the key1 interrupt "STOP" */
isr4:
	subi r13, r3, 0x2			/* branch if NOT in state 2 */
	bne r13, r0, ISR4_NOTCASE2
	movia r3, 0x6				/* set system to OOPS state */
	ret
ISR4_NOTCASE2:
	subi r13, r3, 0x3			/* branch if NOT in state 3 */
	bne r13, r0, SKIP_ISR4		
	movia r3, 0x4				/* set system to STOPPED state */
SKIP_ISR4:					/* this ensures that isr4 does nothing when in the other states */
	ret			

		.global jtag_isr
jtag_isr:

	ldwio r13, 0(r6)		/* read the jtag data reg */
	andi r13, r13, 0xff		/* mask the input */
	
	subi sp, sp, 4			/* allocate stack */
	stwio r12, 0(sp)		/* push r12 */

CHECK_C:
	subi r12, r13, 0x63		/* check for ascii 'c' */
	bne r12, r0, CHECK_S
	stwio r13, 0(r6)		/* output to the jtag data reg */
	movia r3, 0x1			/* put the system into the READY state */
	movia r4, 0x0			/* set the main millisecond counter back to 0 */
	movia r5, 0x0			/* set the random timer counter to 0 */
	movia r11, 0x0			/* set the led timeout counter to 0 */
CHECK_S:
	subi r12, r13, 0x73		/* check for ascii 's' */
	bne r12, r0, CHECK_P
	stwio r13, 0(r6)		/* output to the jtag data reg */
	subi r13, r3, 0x1		/* branch if we are NOT in state 1 */
	bne r13, r0, JTAG_END
	movia r3, 0x2			/* put the system into LED_OFF state */
CHECK_P:
	subi r12, r13, 0x70		/* check for ascii 'p' */
	bne r12, r0, JTAG_END
	stwio r13, 0(r6)			/* output to the jtag data reg */
	subi r13, r3, 0x2			/* branch if NOT in state 2 */
	bne r13, r0, JTAG_NOTCASE2
	movia r3, 0x6				/* set system to OOPS state */
	ret
JTAG_NOTCASE2:
	subi r13, r3, 0x3			/* branch if NOT in state 3 */
	bne r13, r0, JTAG_END		
	movia r3, 0x4				/* set system to STOPPED state */
JTAG_END:	
	
	ldwio r12, 0(sp)			/* pop r12 */
	addi sp, sp, 4				/* de-allocate stack */
	ret
	
/******** SYSTEM STATE SUBROUTINES ********/
/******************************************/

	.global ready_ini			/* state 1 */
ready_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)				/* push ra to the stack */
	stwio r0, 0(r15)			/* turn off the green leds */
	call seven_segments_off		/* turn off seven segment displays */
	call print_hello			/* print hello on seven-segments */
	ldwio ra, 0(sp)				/* pop ra from the stack */
	addi sp, sp, 4				/* de-allocate */
	ret
	
	.global led_off_ini			/* state 2 */
led_off_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)				/* push ra to the stack */		
	call seven_segments_off		/* clear the seven-segments */
	
								/* start random timer, r9 holds the timeout value */
	ldwio r13, 0(r10)  			/* read lfsr */
	andi r13, r13, 0b01110  	/* take the middle 3 bits */
	srli r13, r13, 1  			/* shift them right by 1 */
	addi r13, r13, 1  			/* add 1 for a range of 1 to 8 */
	bne r13, r2, IN_RANGE		/* branch if value is between 2 and 8 */
	addi r13, r13, 1			/* if random value is 1, add 1 to become 2 */
IN_RANGE:
	slli r9, r13, 10  			/* multiply by 1024, shift left logical */
								/* makes range of approx 2000 - 8000 ms */
								
	addi r13, r0, %lo(ms)		/* write the period value to timer ip core */
	stwio r13, 0x8(r14)			/* period is 1 ms */
	addi r13, r0, %hi(ms)		/* every timeout interrupt increases a counter */
	stwio r13, 0xc(r14)
	movia r13, 0b111			/* start the timer and enable the interrupt */
	stwio r13, 0x4(r14)			/* write to timer control reg */
	
	ldwio ra, 0(sp)				/* pop ra from the stack */
	addi sp, sp, 4				/* de-allocate */
	ret
	
	.global led_on_ini		/* state 3 */
led_on_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)			/* push ra to the stack */
	movia r13, 0b111		/* start timer, continuous, with interrupt */
	stwio r13, 0x4(r14)		/* write to timer control reg */
	ldwio ra, 0(sp)			/* pop ra from the stack */
	addi sp, sp, 4			/* de-allocate */
	ret
	
	.global stopped_ini		/* state 4 */
stopped_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)			/* push ra to the stack */
	movia r13, 0b1000		/* set timer into idle mode */
	call display			/* display the reaction time */
	stwio r13, 4(r14)		/* write to timer control reg */
	ldwio ra, 0(sp)			/* pop ra from the stack */
	addi sp, sp, 4			/* de-allocate */
	ret
	
	.global out_state_ini		/* state 5 */
out_state_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)				/* push ra to the stack */
	call seven_segments_off		/* clear the display */
	call print_out				/* print out to seven-segments */
	ldwio ra, 0(sp)				/* pop ra from the stack */
	addi sp, sp, 4				/* de-allocate */
	ret
	
	.global oops_ini		/* state 6 */
oops_ini:
	subi sp, sp, 4		
	stwio ra, 0(sp)				/* push ra to the stack */
	call seven_segments_off		/* clear the display */
	call print_oops				/* print oops to seven-segments */
	ldwio ra, 0(sp)				/* pop ra from the stack */
	addi sp, sp, 4				/* de-allocate */
	ret

	
/******** OTHER SUBROUTINES ********/
/***********************************/
	
	.global flash			/* flashes leds every 100 ms */ 
flash:
	subi sp, sp, 4		
	stwio ra, 0(sp)			/* push ra to the stack */
	subi r12, r11, 200		/* check the led time counter */
	bne r12, r0, NOT200		/* branch if the counter is not 200 */
	movia r13, 0b1000		/* if 200, flash led3 */
	stwio r13, 0(r15)
	subi r11, r11, 200		/* reset the led time counter */
NOT200:
	subi r12, r11, 100		/* check the led time counter */
	bne r12, r0, NOT100		/* branch if the counter is not 100 */
	movia r13, 0b0100		/* if 100, flash led2 */
	stwio r13, 0(r15)
NOT100:
	ldwio ra, 0(sp)			/* pop ra from the stack */
	addi sp, sp, 4			/* de-allocate */
	ret
	
	.global seven_segments_off
seven_segments_off:
	subi sp, sp, 4		
	stwio ra, 0(sp)		/* push ra to the stack */
	
	movia r13, 0xff		/* turn off the seven-segment */
	stwio r13, 0(r16)	/* they are active low */
	stwio r13, 0(r17)
	stwio r13, 0(r18)
	stwio r13, 0(r19)
	stwio r13, 0(r20)
	
	movia r12, hex5		/* unused seven-segments */
	stwio r13, 0(r12)
	movia r12, hex6
	stwio r13, 0(r12)
	movia r12, hex7
	stwio r13, 0(r12)
	
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 4		/* de-allocate */
	ret
	
	
	.global print_hello
print_hello:
	subi sp, sp, 4		
	stwio ra, 0(sp)		/* push ra to the stack */
						/* write to hex4, hex3, hex2, hex1, hex0 */
	movia r13, 0x09		/* H */
	stwio r13, 0(r20)
	movia r13, 0x06		/* E */
	stwio r13, 0(r19)
	movia r13, 0x47		/* L */
	stwio r13, 0(r18)
	movia r13, 0x47		/* L */
	stwio r13, 0(r17)
	movia r13, 0x40		/* O */
	stwio r13, 0(r16)
	
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 4		/* de-allocate */
	ret
	
	.global print_out
print_out:
	subi sp, sp, 4		
	stwio ra, 0(sp)		/* push ra to the stack */
						/* write to hex2, hex1, hex0 */
	movia r13, 0x40		/* O */
	stwio r13, 0(r18)
	movia r13, 0x41		/* U */
	stwio r13, 0(r17)
	movia r13, 0x07		/* T */
	stwio r13, 0(r16)
	
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 4		/* de-allocate */
	ret
	
	.global print_oops
print_oops:
	subi sp, sp, 4		
	stwio ra, 0(sp)		/* push ra to the stack */
						/* write to hex3, hex2, hex1, hex0 */
	movia r13, 0x40		/* O */
	stwio r13, 0(r19)
	movia r13, 0x40		/* O */
	stwio r13, 0(r18)
	movia r13, 0x0c		/* P */
	stwio r13, 0(r17)
	movia r13, 0x12		/* S */
	stwio r13, 0(r16)
	
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 4		/* de-allocate */
	ret
	
		
	.global display		/* displays the millisecond counter on the 7-segments */
display:
	subi sp, sp, 16		
	stwio ra, 0(sp)		/* push ra to the stack */
	stwio r13, 4(sp)	/* push r13 to the stack */
	
	stwio r4, 0(r7)			/* write ms count to the hardware decoder (binary_out) */
	nop
	ldwio r13, 0(r8)		/* read the bcd_in */
	stwio r13, 8(sp)		/* store full bcd reg on the stack */
	
	andi r13, r13, 0xf		/* mask lower 4 bits */
	call decode 			/* return the decoded value in r13 */
	stwio r13, 0(r16)		/* write to hex0 */
	
	ldwio r13, 8(sp)		/* load full bcd reg from stack */
	andi r13, r13, 0xf0		/* mask middle 4 bits */
	srli r13, r13, 4		/* shift right logical for the subroutine */
	call decode				/* return the decoded value in r13 */
	stwio r13, 0(r17)		/* write to hex1 */
	
	ldwio r13, 8(sp)		/* load the full bcd reg from the stack */
	andi r13, r13, 0xf00	/* mask the upper 4 bits */
	srli r13, r13, 8		/* shift right logical for the subroutine */
	call decode				/* return the decoded value in r13 */
	stwio r13, 0(r18)		/* write to hex2 */
	
	
	ldwio r13, 4(sp)	/* pop r13 from the stack */
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 16		/* de-allocate */
	ret
	
	.global decode
						/* converts bcd to 7-segment */
decode:					/* stores return value in r13 */
	subi sp, sp, 20		
	stwio ra, 0(sp)		/* push ra to the stack */
	stwio r7, 4(sp)		/* push r7 to the stack */
	stwio r8, 8(sp)		/* push r8 to the stack */
CASE0:
	subi r7, r13, 0x0		/* if r13 is zero */
	bne r7, r0, CASE1
	movia r8, 0x000000c0	/* output 7-segment zero */
CASE1:
	subi r7, r13, 0x1		/* etc */
	bne r7, r0, CASE2
	movia r8, 0x000000f9
CASE2:
	subi r7, r13, 0x2
	bne r7, r0, CASE3
	movia r8, 0x000000a4
CASE3:
	subi r7, r13, 0x3
	bne r7, r0, CASE4
	movia r8, 0x00000030
CASE4:
	subi r7, r13, 0x4
	bne r7, r0, CASE5
	movia r8, 0x00000019
CASE5:
	subi r7, r13, 0x5
	bne r7, r0, CASE6
	movia r8, 0x00000012
CASE6:
	subi r7, r13, 0x6
	bne r7, r0, CASE7
	movia r8, 0x00000002
CASE7:
	subi r7, r13, 0x7
	bne r7, r0, CASE8
	movia r8, 0x00000078
CASE8:
	subi r7, r13, 0x8
	bne r7, r0, CASE9
	movia r8, 0x00000000
CASE9:
	subi r7, r13, 0x9
	bne r7, r0, DONE
	movia r8, 0x00000018
DONE:
	mov r13, r8			/* move the answer into r13 */
	
	
	ldwio r8, 8(sp)		/* pop r8 from the stack */
	ldwio r7, 4(sp)		/* pop r7 from the stack */
	ldwio ra, 0(sp)		/* pop ra from the stack */
	addi sp, sp, 20		/* de-allocate */
	ret
	
.end


