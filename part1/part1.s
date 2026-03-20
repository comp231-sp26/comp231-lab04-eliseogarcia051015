.text
.global _start

_start:                             
          	mov		r5, #0
          	b		display

loop:
          // loop code here
          	ldr		r1, =0xFF200050 // K E Y GPIO port,
          	ldr 		r0, [r1]            // read data
    	  	and       r0, r0, #0xF        //lowest 4 bits (KEY0-KEY3)
    
    	  	cmp   	  r0, #1              // check if KEY0 is pressed
    	  	beq       press_key0

    	  	cmp       r0, #2              // check if KEY1 is pressed
    	  	beq       press_key1

    	  	cmp       r0, #4              // check if KEY2 is pressed
    	  	beq       press_key2

    	  	cmp       r0, #8              // check if KEY3 is pressed
    	  	beq       press_key3

    	  	b         loop                // repeat the loop

press_key0:
    	  	mov       r5, #0              // reset the counter to 0
    	  	b         display

press_key1:
    	  	add       r5, r5, #1          // increment
    	  	b         display

press_key2:
    	  	sub       r5, r5, #1          // decrement 
    	  	b         display

press_key3:
    	  	mov      r5, #255            // set the counter to 255 to blank the display
    	  	b         display


bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr
            
/* display r5 on hex1-0, r6 on hex3-2 and r7 on hex5-4 */
display:    ldr     r8, =0xff200020 // base address of hex3-hex0
			mov		r0, r5			
            bl      seg7_code    	// returns r0 converted to a bit code in r0   
            str		r0, [r8]
            b		loop   
          
.end
