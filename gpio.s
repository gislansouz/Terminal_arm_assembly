/* Global Symbols */
.global .gpio_setup
.type .gpio_setup, %function


/* Registers */

/* GPIO */
.equ GPIO1_OE, 0x4804C134
.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190

/* GPIO Clock Setup */
.equ CM_PER_GPIO1_CLKCTRL, 0x44e000AC

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4

/********************************************************
GPIO SETUP
********************************************************/
.gpio_setup:
    /* set clock for GPIO1, TRM 8.1.12.1.31 */
    ldr r0, =CM_PER_GPIO1_CLKCTRL
    ldr r1, =0x40002
    str r1, [r0]

    /* set pin 21 for output, led USR0, TRM 25.3.4.3 */
    ldr r0, =GPIO1_OE
    ldr r1, [r0]
    bic r1, r1, #(0xf<<21)
    str r1, [r0]
    bx lr
/********************************************************/




/********************************************************
Blink LED BBB
********************************************************/

.global .led_ON
.type .led_ON, %function
.led_ON:
    ldr r0, =GPIO1_SETDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bx lr

.global .led_OFF
.type .led_OFF, %function
.led_OFF:
    
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(1<<21)
    str r1, [r0]
    bx lr
