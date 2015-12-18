;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Author: Dylan Brown
; Date: 12/10/15 
; Conway's Game of Life generated in the MSP430 memory
; Two "glider guns" formed, and a LCG used to create a random generation, with 
; each bit in the universe having a roughly 20% chance of being 1.
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

			;Clear the temp vectors

			call #clrv1
			call #clrv2
			call #clrv3




			;MAIN CLASS

			; Use this to create the basic Glider
			;call #createglider

			; Use this to create the Gospel Glider
			call #gospelglider

			; Use this to create a Random Universe
			;call #genRandomUniv

			push R5
			push R6
			push R4
			push R10
			mov.w #203, R4		; THIS IS THE NUMBER OF GENERATIONS, arbitrary value
nextGen		push R4
			push R13
			call #formnewgen ; 1 generational update
			pop R13
			pop R4
			dec R4
			jnz nextGen
			pop R10
			pop R4
			pop R6
			pop R5

endloop: 	jmp endloop


formnewgen	mov.b #16, R5 ; Num of rows generated divided by 2
			mov.w #0x0200, R6 ; first row to be used, outside of universe
			mov.w  R6, R4 ;This is the first row to be iterated (Row 1)
			mov.w #tempvect1, R13	;temporary vector one FIRST ROW
			push R7
			push R6
			push R8
			call #saverow0
			pop R8
			pop R6
			pop R7

			sub #8, R4 ; to get the first row
			push R4
			push R13
			call #iteraterow
			pop R13 ; place back from stack
			pop R4 ; place back from stack




			mov.w #tempvect2, R13	;temporary vector two
			add #8, R4	;iterate next row		(Row 2)
			push R4
			push R13
			call #iteraterow
			pop R13 ; place back from stack
			pop R4 ; place back from stack


			call #copynextgen


			sub	#8, R13	;temporary vector one
			add #8, R4	;iterate next row		(Row 3)
			push R4
			push R13
			call #iteraterow
			pop R13 ; place back from stack
			pop R4 ; place back from stack
			call #copynextgen2
			add #8, R6

new_genloop	push R5
			push R6
			call #new_generation
			pop R6
			pop R5
			add #16, R6 ;next 2 rows to be used
			dec R5
			jne new_genloop
			mov.w #0x02F8, R4 ;write final line
			call #copynextgen
			call #clrv3
			ret

new_generation 	push R4
			push R13
			push R6
			mov.w  R6, R4 ;add address for next 2 rows
			call #generate2rows
			pop R6
			pop R13
			pop R4
			ret

clrv1		push R5
			mov.w #tempvect1, R5
			jmp clr0
clrv2		push R5
			mov.w #tempvect2, R5
			jmp clr0
clrv3		push R5
			mov.w #tempvect3, R5
			jmp clr0

clr0		mov.w #0, 0(R5)
			mov.w #0, 1(R5)
			mov.w #0, 2(R5)
			mov.w #0, 3(R5)
			mov.w #0, 4(R5)
			mov.w #0, 5(R5)
			mov.w #0, 6(R5)
			mov.w #0, 7(R5)

			pop R5
			ret

generate2rows mov.w #tempvect2, R13	;temporary vector two
			add #8, R4	;iterate next row		(Row 4)
			cmp #0x02F8, R4 ; toroidal, check if out of bounds
			jeq lastrow
			push R4
			push R13
			call #iteraterow
			pop R13 ; place back from stack
			pop R4 ; place back from stack
			call #copynextgen
			sub	#8, R13	;temporary vector one
			add #8, R4	;iterate next row		(Row 5)
			cmp #0x02F8, R4 ; toroidal, check if out of bounds
			jeq lastrow
			push R4
			push R13
			call #iteraterow
			pop R13 ; place back from stack
			pop R4 ; place back from stack
			call #copynextgen2
lastrow		ret



iteraterow	mov.b #8, R10 ;8 bytes to be iterated through for each row.
bytelp		call #iteratebyte

nxtbyte		inc R4
			inc R13
			dec R10
			jnz bytelp
			ret		;EXIT ITERATE ROW

iteratebyte call #saverow

			push R5
			push R6
			push R7

			cmp #0x0200, R4 ;check if byte is in the first row, toroidal for looping
			jl firstrowcase
			mov.w #0x02EF, R5 ;check if byte is in the last row, toroidal for looping
			cmp R4, R5
			jl lastrowcase

			call #storerows
specialret	push R14
			mov.b #8, R14

it_loop		jmp	iterate0
post_itloop	dec R14
			jnz it_loop
			pop R14
			pop R7
			pop R6
			pop R5
			ret


saverow		mov.b 8(R4), 0(R13) ;Save value of 2nd row to R5, OLD
			ret

storerows	mov.b 0(R4), R5
			mov.b 8(R4), R6
			mov.b 16(R4), R7
			ret

firstrowcase push R8
			 mov.w R4, R8
			 add #256, R8
			 mov.b 0(R8), R5
			 mov.b 8(R4), R6
			 mov.b 16(R4), R7
			 pop R8
			 jmp specialret

lastrowcase mov.b 0(R4), R5
			mov.b 8(R4), R6
			mov.b 32(R4), R7 ;This is a specific byte on Temp Vect 3!!
			jmp specialret

;R5, R6, R7 are the registers where rows are stored
iterate0	push R9
			push R15
			push R8

			mov.b	#0, R9			; i,j sum
			mov.b	#3, R15			; loop 3 times

			cmp		#8, R14			; see if it's the first bit
			jeq		firstbitr1
			cmp		#1, R14
			jeq		lastbitr1

			mov.b	R5, R8			; R8 is the register used to temporarily iterate with.
row1		rlc.b	R8
			jc ijsum1
ret1		dec R15
			jnz row1


;			MIDDLE ROW, SPECIAL CASE: DONT SUM ij TERM
			cmp		#8, R14			; see if it's the first bit
			jeq		firstbitr2
			cmp		#1, R14
			jeq		lastbitr2


			mov.b	R6, R8
row2		rlc.b	R8
			jc ijsum2
ret2		rlc.b	R8
rett2		rlc.b	R8
			jc ijsum4

ret4		mov.b	#3, R15
			cmp		#8, R14			; see if it's the first bit
			jeq		firstbitr3
			cmp		#1, R14
			jeq		lastbitr3

			mov.b	R7, R8
row3		rlc.b	R8
			jc ijsum3
ret3		dec R15
			jnz row3

			call #newrow

			pop R8 ; restore from stack
			pop R15 ; restore from stack
			pop R9 ; restore from stack
			jmp post_itloop

;;SPECIAL CASES FOR THE MSB
firstbitr1	push R5
			mov.w R4, R5

			cmp #8, R10	;Special case for first byte
			jeq looprow1

			dec R5 ; address of previous byte
			mov.b 0(R5), R8

lp1ret		pop R5
			rrc.b R8
			jc ij1
rs1			mov.b R5, R8
			jmp ret1

ij1			inc R9
			jmp rs1

looprow1	mov.b 7(R5), R8
			jmp lp1ret

;----------------------------------------------

firstbitr2	push R5
			mov.w R4, R5

			cmp #8, R10	;Special case for first byte
			jeq looprow2

			dec R5
			mov.b 8(R5), R8


lp2ret		pop R5
			rrc.b R8
			jc ij2
rs2			mov.b R6, R8
			jmp ret2

ij2			inc R9
			jmp rs2

looprow2	mov.b 15(R5), R8
			jmp lp2ret

;----------------------------------------------

firstbitr3	push R5
			mov.w R4, R5

			cmp #8, R10	;Special case for first byte
			jeq looprow3

			dec R5
			mov.b 16(R5), R8

lp3ret		pop R5
			rrc.b R8
			jc ij3
rs3			mov.b R7, R8
			jmp ret3

ij3			inc R9
			jmp rs3

looprow3	mov.b 23(R5), R8
			jmp lp3ret

;;SPECIAL CASES FOR THE LSB
lastbitr1	push R5
			mov.w R4, R5

			cmp #1, R10	;Special case for last byte
			jeq lprow1

			inc R5
			mov.b 0(R5), R8
lp01ret		pop R5
			rlc.b	R8
			jc ij01
rs01		mov.b R5, R8
			jmp ret1

ij01		inc R9
			jmp rs01

lprow1		sub #7, R5
			mov.b 0(R5), R8
			jmp lp01ret

;----------------------------------------------

lastbitr2	push R5
			mov.w R4, R5

			cmp #1, R10	;Special case for last byte
			jeq lprow2


			inc R5
			mov.b 8(R5), R8
lp02ret		pop R5
			rlc.b	R8
			jc ij02
rs02		mov.b R6, R8
			jmp rett2

ij02		inc R9
			jmp rs02


lprow2		mov.b 1(R5), R8
			jmp lp02ret

;----------------------------------------------


lastbitr3	push R5
			mov.w R4, R5

			cmp #1, R10	;Special case for last byte
			jeq lprow3

			inc R5
			mov.b 16(R5), R8
lp03ret		pop R5
			rlc.b	R8
			jc ij03
rs03		mov.b R7, R8
			jmp ret3

ij03		inc R9
			jmp rs03

lprow3		mov.b 9(R5), R8
			jmp lp03ret

;;ij Summation
ijsum1		inc	R9
			jmp ret1

ijsum2		inc	R9
			jmp ret2

ijsum3		inc	R9
			jmp ret3

ijsum4		inc	R9
			jmp ret4

newrow		push R11
			push R12


			mov.b #2, R11
			mov.b #3, R12
			cmp R11, R9
			jl setzero
			cmp R11, R9  ;keep bit as is
			jeq fin_it
			cmp R12, R9
			jeq setone
			cmp R9, R12
			jl	setzero



setzero		cmp #8, R14
			jeq eighthcs1
			cmp #7, R14 ;check which bit is being iterated, starting with 6 (2nd one)
			jeq seventhcs1
			cmp #6, R14
			jeq sixthcs1
			cmp #5, R14
			jeq fifthcs1
			cmp #4, R14
			jeq fourthcs1
			cmp #3, R14
			jeq thirdcs1
			cmp #2, R14
			jeq secondcs1
			cmp #1, R14
			jeq onecs1

eighthcs1	bic.b	#0x80, 0(R13)
			jmp fin_it
seventhcs1	bic.b	#0x40, 0(R13)
			jmp fin_it
sixthcs1	bic.b	#0x20, 0(R13)
			jmp fin_it
fifthcs1	bic.b	#0x10, 0(R13)
			jmp fin_it
fourthcs1	bic.b	#0x08, 0(R13)
			jmp fin_it
thirdcs1	bic.b	#0x04, 0(R13)
			jmp fin_it
secondcs1	bic.b	#0x02, 0(R13)
			jmp fin_it
onecs1		bic.b	#0x01, 0(R13)
			jmp fin_it




setone		cmp #8, R14
			jeq eighthcs2
			cmp #7, R14
			jeq seventhcs2
			cmp #6, R14
			jeq sixthcs2
			cmp #5, R14
			jeq fifthcs2
			cmp #4, R14
			jeq fourthcs2
			cmp #3, R14
			jeq thirdcs2
			cmp #2, R14
			jeq secondcs2
			cmp #1, R14
			jeq onecs2


eighthcs2	bis.b	#0x80, 0(R13)
			jmp fin_it
seventhcs2	bis.b	#0x40, 0(R13)
			jmp fin_it
sixthcs2	bis.b	#0x20, 0(R13)
			jmp fin_it
fifthcs2	bis.b	#0x10, 0(R13)
			jmp fin_it
fourthcs2	bis.b	#0x08, 0(R13)
			jmp fin_it
thirdcs2	bis.b	#0x04, 0(R13)
			jmp fin_it
secondcs2	bis.b	#0x02, 0(R13)
			jmp fin_it
onecs2		bis.b	#0x01, 0(R13)
			jmp fin_it

fin_it		cmp		#8, R14
			jeq firstbitcase ;don't bit shift for the MSB
			rla.b R5	;next bit
			rla.b R6	;next bit
			rla.b R7	;next bit

firstbitcase pop	R12
			pop R11
			ret






;MISC SUBROUTINES


copynextgen	push R4 ; row currently being iterated
			push R13 ; next gen vector one row before
			push R6

			mov.w #tempvect1, R13
			mov.b #8, R6 ; loop 8 times
copy_vect	mov.b @R13+, 0(R4) ; copy byte by byte
			inc R4
			dec R6
			jnz copy_vect
			call #clrv1
			pop R6
			pop R13
			pop R4
			ret

copynextgen2 push R4 ; row currently being iterated
			push R13 ; next gen vector one row before
			push R6
			mov.w #tempvect2, R13
			mov.b #8, R6 ; loop 8 times
copy_vect2	mov.b @R13+, 0(R4) ; copy byte by byte
			inc R4
			dec R6
			jnz copy_vect2
			call #clrv2
			pop R6
			pop R13
			pop R4
			ret

; SAVE ROW 0
saverow0	mov.w #tempvect3, R7
			mov.b #8, R8
eloop		mov.b @R6+, 0(R7)
			inc R7
			dec R8
			jnz eloop
			ret

; DESIGNS/PATTERNS
createglider mov.b #0x04, &0x0218
			mov.b #0x14, &0x220
			mov.b #0x0C, &0x228
			ret

			;Row 2 x210
gospelglider mov.b #0x40, &0x213

			;Row 3 x218
			mov.b #0x01, &0x21A
			mov.b #0x40, &0x21B

			;Row 4 x220
			mov.b #0x06, &0x221
			mov.b #0x06, &0x222
			mov.b #24, &0x224

			;Row 5 x228
			mov.b #0x08, &0x229
			mov.b #134, &0x22A
			mov.b #24, &0x22C

			;Row 6 x230
			mov.b #0x60, &0x230
			mov.b #0x10, &0x231
			mov.b #70, &0x232

			;Row 7 x238
			mov.b #0x60, &0x238
			mov.b #0x11, &0x239
			mov.b #0x61, &0x23A
			mov.b #0x40, &0x23B

			;Row 8 x240
			mov.b #0x10, &0x241
			mov.b #64, &0x242
			mov.b #64, &0x243

			;Row 9 x248
			mov.b #0x08, &0x249
			mov.b #128, &0x24A

			;Row 10 x250
			mov.b #0x06, &0x251

			ret

genRandomUniv push R7
		      push R6
		      push R8
		      push R9
		      push R10
		      push R11
			  mov.w #256, R7
			  mov.w #0x0200, R11
			  mov.w #6553, R10 ; This is the 20% figure, must be under this


addrand		  mov.b #8, R9
		      clr R6
bitrt		  push #0
			  call #LCGRandom32
			  pop R8

			  cmp R10, R8 ; checks if it's in the 20% range.
			  jl setthebit
			  jmp clrthebit

			  ;set bit equal to 1
setthebit	  cmp #8, R9
			  jeq eighthbit
			  cmp #7, R9
		      jeq seventhbit
			  cmp #6, R9
			  jeq sixthbit
			  cmp #5, R9
			  jeq fifthbit
			  cmp #4, R9
			  jeq fourthbit
			  cmp #3, R9
			  jeq thirdbit
			  cmp #2, R9
			  jeq secondbit
			  cmp #1, R9
			  jeq firstbit

eighthbit	bis.b	#0x80, R6
			jmp finishmask
seventhbit	bis.b	#0x40, R6
			jmp finishmask
sixthbit	bis.b	#0x20, R6
			jmp finishmask
fifthbit	bis.b	#0x10, R6
			jmp finishmask
fourthbit	bis.b	#0x08, R6
			jmp finishmask
thirdbit	bis.b	#0x04, R6
			jmp finishmask
secondbit	bis.b	#0x02, R6
			jmp finishmask
firstbit	bis.b	#0x01, R6
			jmp finishmask



clrthebit	  cmp #8, R9
			  jeq eighthbitc
			  cmp #7, R9
		      jeq seventhbitc
			  cmp #6, R9
			  jeq sixthbitc
			  cmp #5, R9
			  jeq fifthbitc
			  cmp #4, R9
			  jeq fourthbitc
			  cmp #3, R9
			  jeq thirdbitc
			  cmp #2, R9
			  jeq secondbitc
			  cmp #1, R9
			  jeq firstbitc

eighthbitc	bic.b	#0x80, R6
			jmp finishmask
seventhbitc	bic.b	#0x40, R6
			jmp finishmask
sixthbitc	bic.b	#0x20, R6
			jmp finishmask
fifthbitc	bic.b	#0x10, R6
			jmp finishmask
fourthbitc	bic.b	#0x08, R6
			jmp finishmask
thirdbitc	bic.b	#0x04, R6
			jmp finishmask
secondbitc	bic.b	#0x02, R6
			jmp finishmask
firstbitc	bic.b	#0x01, R6
			jmp finishmask







finishmask	  dec R9
			  jnz bitrt ; inner loop for bits

			  mov.b R6, 0(R11) ; move randomly generated byte to R6
			  inc R11
			  dec R7
			  jnz addrand

		      pop R11
		      pop R10
		      pop R9
			  pop R8
			  pop R6
			  pop R7

			  ret

;;Clear Bits


;;Set Bits




;;LCG generator


LCGRandom32	push sr
		push r4
		push r5
		push &highLCG ; X(n-1)high word
		push &lowLCG ; X(n-1)low word
		push #0x41c6  ; Ahigh constant for LCG from ISO C standards
		push #0x4e6d  ; Alow constant
		call #mult32
		incd sp
		incd sp
		push #0
		push #12345   ;
		call #sra32
		incd sp
		incd sp
		pop r4
		pop r5
		mov r4, &highLCG  ; save X(n) as seed for next call to lcg32
		mov r5, &lowLCG
		and #0x7fff, r4    ; get bits 16-30 as random number output
		mov r4, 8(sp)      ;   and return on the stack
		pop r5
		pop r4
		pop sr
		ret


;  push (in this order) A1h, A1l, B1h, B1l
;  pop  (in this order) null, null, R1h, R1l
mult32	push sr
		push r4
		push r5
		push r6
		push r7
		push r8
		push r9
		push r10
		push r11
		mov 26(sp), r4	; high word A
		mov 24(sp), r5	; low word A
		mov 22(sp), r6	; high word B
		mov 20(sp), r7	; low word B
		clr r8		; high word Result
		clr r9		; low word Result

		mov #0x0001, R10 ; the mask
		mov #17, R11     ; loop counter, execute 16 times
mult32lp1 dec R11
		jeq mult32done1
		bit R10, R5
		jz mult32nxb1
		push r6	; add shifted B if corresponding bit of Alow was 1
		push r7
		push r8
		push r9
		call #sra32
		pop r8
		pop r8
		pop r8
		pop r9
mult32nxb1	rla r10
		rla r7
		rlc r6
		jmp mult32lp1

mult32done1	mov #0x001, R10	; high mask
		mov #17, R11 ; high counter
mult32lp2	dec R11
		jeq mult32done2
		bit R10, R4
		jz mult32nxb2
		push r6	; add shifted B if corresponding bit of Ahigh was 1
		push r7
		push r8
		push r9
		call #sra32
		pop r8
		pop r8
		pop r8
		pop r9
mult32nxb2	rla r10
		rla r7
		rla r6
		jmp mult32lp2
mult32done2
		mov r8, 26(sp)
		mov r9, 24(sp)
		pop r11
		pop r10
		pop r9
		pop r8
		pop r7
		pop r6
		pop r5
		pop r4
		pop sr
		ret


; push (in this order) A1h, A1l, B1h, B1l
; pop (in this order) null, null, ResultH, ResultL
sra32	push sr
		push r4
		push r5
		push r6
		push r7
		mov 18(sp), r4	; high word A
		mov 16(sp), r5	; low word A
		mov 14(sp), r6	; high word B
		mov 12(sp), r7	; low word B
		add R5, R7
		addc R4, R6
		mov R6, 16(sp)  ; high word of answer
		mov R7, 18(sp)	; low word of answer
		pop r7
		pop r6
		pop r5
		pop r4
		pop sr
		ret



			.data
universe	.space 256
tempvect1	.space 8 ; temp vector 1
tempvect2   .space 8 ; temp vector 2
tempvect3	.space 8 ; Row 0 gen K

;;LCG vars
highLCG		.word 0xa55a
lowLCG		.word 0xa55a

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
