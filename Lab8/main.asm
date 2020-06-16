;
; Lab8.asm
; 
;
.macro outi
	ldi _swap, @1
	.if @0 < 0x40
		out @0, _swap
	.else
		sts @0, _swap
	.endif
.endm
.macro outr
	mov _swap, @1
	.if @0 < 0x40
		out @0, _swap
	.else
		sts @0, _swap
	.endif
.endm

; Names for registers
.def	_low		=r16
.def	_high		=r17
.def	_swap		=r18

.def	_logic		=r0	;	1bit=1 - button1 pressed	#	2bit=1 - button2 pressed
.def	_counter1	=r19
.def	_counter2	=r20

.def	_r1ForDelay	=r21
.def	_r2ForDelay	=r22
.def	_r3ForDelay	=r23

.def	_temp		=r24
.def	_start1		=r25
.def	_end1		=r26
.def	_start2		=r27
.def	_end2		=r29

; RAM
		.DSEG	

; FLASH
		.CSEG 
		; vector of interrupts
		.org	0x000
		jmp	reset

		.org	0x005E	; Timer5 Compare Match A
		jmp TIMER5_COMPA

		.org 0x070 
		reti	; USART3 Tx Complete

TIMER5_COMPA:	; Timer5 Compare Match A	
		sbrs	_logic, 1
		rjmp	end_algorithm1
		cp		_end1, _start1
		brmi	reset_algorithm1
start_algorithm1:
		inc		_counter1
		sbrc	_counter1, 0
		rjmp	a1end
a1start:
		outr	PORTK, _start1
		lsl		_start1
		lsr		_end1
		rjmp	end_algorithm1
a1end:
		outr	PORTK, _end1
		rjmp	end_algorithm1
reset_algorithm1:
		outi	PORTK, 0x00
		clt
		bld		_logic, 1
end_algorithm1:

		sbrs	_logic, 2
		rjmp	end_algorithm2
		cp		_end2, _start2
		brmi	reset_algorithm2
start_algorithm2:
		mov		_temp, _start2
		or		_temp, _end2
		outr	PORTF, _temp
		lsl		_start2
		lsr		_end2
		rjmp	end_algorithm2
reset_algorithm2:
		outi	PORTF, 0x00
		clt
		bld		_logic, 2
end_algorithm2:

end_timer5:
		reti
		
reset:		
		; stack initialization
		ldi		_temp, Low(RAMEND)
		out		SPL, _temp
		ldi		_temp, High(RAMEND)
		out		SPH, _temp ;stack

		; disable comparator
		ldi		r16, 0b10000000
		out		ACSR, r16

		; I/O ports initialization
		ldi		_low, 0x00
		ldi		_high, 0xFF

		; PORTK - OUTPUT, LOW
		outr		DDRK, _high
		outr		PORTK, _low

		; PORTF - OUTPUT, LOW
		outr		DDRF, _high
		outr		PORTF, _low

		; PORTC - OUTPUT, LOW
		outr		DDRC, _high
		outr		PORTC, _low

		; PORTA - INPUT, PULLUP
		outr		DDRA, _low
		outr		PORTA, _high

		outi	TCCR5A, 0x00
		outi	TCCR5B, (1 << WGM52) | (1 << CS52) | (1 << CS50)	; CTC mode & Prescaler @ 1024
		outi	TIMSK5, (1 << OCIE5A)	; permition for compare interrupt
		outi	OCR5AH, 0x2A	; 0.7 sec
		outi	OCR5AL, 0xB9
		
		sei	; enable interrupts

main:		
		sbic	PINA, 1	; if button1 is pressed (bit1 == LOW)
		rjmp	endButton1
		clr		_counter1
		ldi		_start1, 0b00000001
		ldi		_end1, 0b10000000

		set
		bld		_logic, 1

		;buzzer signal
		sbi		PORTC, 0
		rcall	delay200ms	
		cbi		PORTC, 0
endButton1:
		
		sbic	PINA, 3	; if button2 is pressed (bit3 == LOW)
		rjmp	endButton2
		clr		_counter2
		ldi		_start2, 0b00000001
		ldi		_end2, 0b10000000

		set
		bld		_logic, 2

		; buzzer signal
		sbi		PORTC, 0
		rcall	delay200ms	
		cbi		PORTC, 0
endButton2:

		rjmp main

; Subroutines налаштування базера
delay200ms:
		ldi		_r1ForDelay, 0x00
		ldi		_r2ForDelay, 0xC4
		ldi		_r3ForDelay, 0x09
delay:	subi	_r1ForDelay, 1
		sbci	_r2ForDelay, 0
		sbci	_r3ForDelay, 0
		brne	delay
		ret ;закінчуэ підпрограму

; EEPROM
		.ESEG
