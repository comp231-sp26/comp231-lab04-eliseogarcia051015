.text
.global _start

_start:                             
          ldr		sp, =stack
          mov		r5, #0	//counter
          mov 		r6, #0	//flag
          b			display
          
loop:
		  cmp		r6, #1	
          beq		do_delay
          
Polling:
		ldr			r1, =0XFF20005C	//Edgecapture register
        ldr 		r0, [r1]
        and			r0, r0, #0xF		//KEY0-KEY3
        cmp			r0, #0
        beq			Polling			//nothing pressed, keep looping
        
        mov			r0, #0
        str			r0, [r1]
        mov			r6, #1
        b			loop
        
do_delay:
		ldr			r1, =0XFF20005C	//Edgecapture register
        ldr 		r0, [r1]
        and			r0, r0, #0xF		//KEY0-KEY3
        cmp			r0, #0
        beq			run_delay
        
        mov			r0, #0
        str			r0, [r1]
        mov			r6, #0
        b			loop
        
run_delay:
		ldr			r7, =200000000 //figure out how timer thing works
        
delay_loop:
		subs		r7, r7, #1
        bne			delay_loop
        
        add			r5, r5, #1
        cmp			r5, #100
        movge		r5, #0
        b			display
        
display:
		str			lr, [sp, #-4]!
        
        mov			r0, r5
        bl			div10		//r0=tens, r1=ones
        mov			r4, r1		//ones digit saved
        
        bl			seg7_code	//r0
        mov			r3, r0		//tens digit saved
        
        mov 		r0, r4		//ones
        bl			seg7_code	//r0
        
        //HEX0, HEX1
        lsl			r3, r3, #7
        orr			r0, r0, r3
        ldr			r8, =0xFF200020
        str			r0, [r8]
		ldr			lr, [sp], #4
        b 			loop
        
div10:
		mov			r1, #0	//quotient

div_loop:
		cmp			r0, #10
        blt			div_done
        sub			r0, r0, #10
        add			r1, r1, #1
        b			div_loop
        
div_done:
		mov			r2, r0		//r2=remainder
        mov			r0, r1		//r0 = quotient
        mov			r1, r2		//r1 = remainder
        bx			lr

.data
bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr              
  
stack:         
.end
