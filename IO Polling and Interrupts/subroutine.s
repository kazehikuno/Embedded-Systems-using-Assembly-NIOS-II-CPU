
	.global subroutine
	
subroutine:
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