.text
.global _start

_start:
        ldr     sp, =stack
        mov     r5, #0
        mov     r6, #0

        ldr     r1, =0xFF20005C     //clear edge-capture
        mov     r0, #0xF
        str     r0, [r1]

        ldr     r1, =0xFFFEC600		//
        ldr     r0, =50000000       //0.25s at 200MHz
        str     r0, [r1]			//load register
        mov     r0, #0b010          
        str     r0, [r1, #0x8]      //timer?
        mov     r0, #1              
        str     r0, [r1, #0xC]      //interrupt status register

        b       display

loop:
        cmp     r6, #1
        beq     check_timer

polling:
        ldr     r1, =0xFF200050
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        beq     polling             //button pressed, wait for release

wait_press:
        ldr     r1, =0xFF200050
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        bne     wait_press          //not pressed, keep waiting

        //pressed and released - toggle
        eor     r6, r6, #1
        ldr     r1, =0xFF20005C
        mov     r0, #0xF
        str     r0, [r1]            //clear edge-capture

        ldr     r1, =0xFFFEC600
        cmp     r6, #1
        moveq   r0, #0b011          //start timer
        movne   r0, #0b010          //stop timer
        str     r0, [r1, #0x8]

        b       display

check_timer:
        ldr     r1, =0xFF20005C     //check edge-capture for button press
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        beq     check_f

        mov     r0, #0xF
        str     r0, [r1]            //clear edge-capture
        eor     r6, r6, #1          //toggle (1->0)
        ldr     r1, =0xFFFEC600
        mov     r0, #0b010          //stop timer
        str     r0, [r1, #0x8]
        b       display

check_f:
        ldr     r1, =0xFFFEC60C     //interrupt status register
        ldr     r0, [r1]
        and     r0, r0, #0x1
        cmp     r0, #0
        beq     loop                //F=0, not expired yet

        mov     r0, #1              //clear F bit (write 1 to clear)
        str     r0, [r1]

        add     r5, r5, #1
        cmp     r5, #100
        movge   r5, #0
        b       display

display:
        str     lr, [sp, #-4]!

        mov     r0, r5
        bl      div10
        mov     r4, r1

        bl      seg7_code
        mov     r3, r0

        mov     r0, r4
        bl      seg7_code

        lsl     r3, r3, #8
        orr     r0, r0, r3
        ldr     r8, =0xFF200020
        str     r0, [r8]

        ldr     lr, [sp], #4
        b       loop

div10:
        mov     r1, #0
div_loop:
        cmp     r0, #10
        blt     div_done
        sub     r0, r0, #10
        add     r1, r1, #1
        b       div_loop
div_done:
        mov     r2, r0
        mov     r0, r1
        mov     r1, r2
        bx      lr

seg7_code:
        ldr     r1, =bit_codes
        ldrb    r0, [r1, r0]
        bx      lr

bit_codes:
        .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
        .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
        .skip   2

        .space  128
stack:
.end