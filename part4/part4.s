.text
.global _start
_start:
        ldr     sp, =stack
        mov     r5, #0              // seconds (0-59)
        mov     r6, #0              // hundredths (0-99)
        mov     r7, #0              // timer running flag

        ldr     r1, =0xFF20005C
        mov     r0, #0xF
        str     r0, [r1]            // clear edgecapture

        ldr     r1, =0xFFFEC600
        ldr     r0, =2000000        // 0.01s at 200MHz
        str     r0, [r1]            // load register
        mov     r0, #0b010
        str     r0, [r1, #0x8]      // control: stopped
        mov     r0, #1
        str     r0, [r1, #0xC]      

        b       display

loop:
        cmp     r7, #1
        beq     check_timer

polling:
        ldr     r1, =0xFF200050
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        beq     polling             // no button pressed, keep waiting

wait_press:
        ldr     r1, =0xFF200050
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        bne     wait_press          // still held, wait for release

        eor     r7, r7, #1
        ldr     r1, =0xFF20005C
        mov     r0, #0xF
        str     r0, [r1]            // clear edgecapture

        ldr     r1, =0xFFFEC600
        cmp     r7, #1
        moveq   r0, #0b011          // start 
        movne   r0, #0b010          // stop
        str     r0, [r1, #0x8]
        b       display

check_timer:
        ldr     r1, =0xFF20005C
        ldr     r0, [r1]
        and     r0, r0, #0xF
        cmp     r0, #0
        beq     check_f

        mov     r0, #0xF
        str     r0, [r1]            // clear edgecapture
        eor     r7, r7, #1          // toggle to 0
        ldr     r1, =0xFFFEC600
        mov     r0, #0b010          // stop timer
        str     r0, [r1, #0x8]
        b       display

check_f:
        ldr     r1, =0xFFFEC60C
        ldr     r0, [r1]
        and     r0, r0, #0x1
        cmp     r0, #0
        beq     loop                // F=0, not expired

        mov     r0, #1
        str     r0, [r1]            // clear F bit

        add     r6, r6, #1          // increment hundredths
        cmp     r6, #100
        blt     display

        mov     r6, #0              // reset hundredths
        add     r5, r5, #1          // increment seconds
        cmp     r5, #60
        movge   r5, #0              // reset seconds

        b       display

display:
        str     lr, [sp, #-4]!

        // -- hundredths (r6) --
        mov     r0, r6
        bl      div10               // r0=tens, r1=ones
        mov     r9, r0              // save hund_tens digit
        mov     r10, r1             // save hund_ones digit

        mov     r0, r9
        bl      seg7_code
        mov     r9, r0              // hund_tens pattern

        mov     r0, r10
        bl      seg7_code
        mov     r10, r0             // hund_ones pattern

        // -- seconds (r5) --
        mov     r0, r5
        bl      div10               // r0=tens, r1=ones
        mov     r11, r0             // save sec_tens digit
        mov     r12, r1             // save sec_ones digit

        mov     r0, r11
        bl      seg7_code
        mov     r11, r0             // sec_tens pattern

        mov     r0, r12
        bl      seg7_code
        mov     r12, r0             // sec_ones pattern

        //HEX0=hund_ones, HEX1=hund_tens, HEX2=sec_ones, HEX3=sec_tens
        orr     r0, r10, r9, LSL #8
        orr     r0, r0, r12, LSL #16
        orr     r0, r0, r11, LSL #24

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