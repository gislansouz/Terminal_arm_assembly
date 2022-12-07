/* Global Symbols */
.global .uart_putc
.global .uart_getc
.type .uart_getc, %function
.type .uart_putc, %function
.global .uart_isr
.global .uart_setup

/* Registradores */
.global UART0_BASE
.equ UART0_BASE, 0x44E09000
.equ GPIO1_SETDATAOUT, 0x4804C194
UART_DLL           = 0x0
UART_RHR           = 0x0
UART_THR           = 0x0
UART_DLH           = 0x4

UART_IER           = 0x4
UART_FCR           = 0x8
UART_EFR           = 0x8
UART_IIR           = 0x8
UART_LCR           = 0xC
UART_MCR           = 0x10
UART_LSR           = 0x14
UART_MDR1          = 0x20
UART_SCR           = 0x40
UART_SYSC          = 0x54
UART_SYSS          = 0x58

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4
/********************************************************
UART0 SETUP (Default configuration)  
********************************************************/
.global .uart0_init
.uart0_init:
    ldr r0, =UART0_BASE
    mov r1, #0x2                // SOFTRESET, spruh73l 19.5.1.43
    str r1, [r0,#UART_SYSC]

1:  ldr r1, [r0, #UART_SYSS]
    tst r1, #0x1                // wait for RESETDONE spruh73l tab 19-73
    beq 1b

    mov r1, #0x8               // disable IDLEMODE, spruh73l 19.5.1.43 & tab 19-72
    str r1, [r0, #UART_SYSC]

    mov r1, #0x83          // DIV_EN (mode A), 8 data bits, spruh73l 19.5.1.13 19.4.1.1.2
    str r1, [r0, #UART_LCR]
    mov r1, #0x1A          // CLOCK_LSB=0x1A, spruh73l 19.5.1.3
    str r1, [r0, #UART_DLL]

// the following code prepares FIFOs for IRQ
    mov r1, #0x10          // ENHANCEDEN=1 (enab R/W access to UART_FCR), spruh73l 19.5.1.8
    str r1, [r0, #UART_EFR]
    mov r1, #0x57          // FIFO triggers, clr & enab, spruh73l 19.5.1.11
    str r1, [r0, #UART_FCR]
    mov r1, #0x0           // ENHANCEDEN=0 (disab R/W access to UART_FCR), spruh73l 19.5.1.8
    str r1, [r0, #UART_EFR]
// end of FIFO-IRQ code

    mov r1, #0x0           // MODESELECT-UART 16x mode, spruh73l 19.5.1.26 
    str r1, [r0, #UART_MDR1]
    ldr r1, [r0, #UART_LCR]
    bic r1, r1, #0x80      // clear DIV_EN, switch to operational mode, spruh73l 19.5.1.13
    str r1, [r0, #UART_LCR]

// the following extra code prepares FIFOs for IRQ
    mov r1, #0xC8       // Rx & Tx FIFO granularity=1, TXEMPTYCTLIT=1 , spruh73l 19.5.1.39
    str r1, [r0, #UART_SCR]
// end of extra FIFO-IRQ code
    
    mov r1, #0x1                // enab interrupt RHR_IT, spruh73l 19.5.1.6, 19.3.6.2
    str r1, [r0, #UART_IER]

    ldr r0, =INTC_ILR
        ldr r1, =#0    
        strb r1, [r0, #72]
    
    	/* Interrupt mask */
    	ldr r0, =INTC_BASE
    	ldr r1, =#(1<<8)    
    	str r1, [r0, #0xc8] //(72 --> Bit 8 do 3º registrador (MIR CLEAR2))

    mov r0, #0
    bx lr

/********************************************************
UART0 PUTC (Default configuration)  
********************************************************/
.uart_putc:
    stmfd sp!,{r1-r2,lr}
    ldr     r1, =UART0_BASE

.wait_tx_fifo_empty:
    ldr r2, [r1, #0x14] 
    and r2, r2, #(1<<5)
    cmp r2, #0
    beq .wait_tx_fifo_empty

    strb    r0, [r1]
    ldmfd sp!,{r1-r2,pc} 

/********************************************************/


/********************************************************
UART0 GETC (Default configuration)  
********************************************************/
.uart_getc:
    stmfd sp!,{r1-r6,lr}

    ldr     r1, =UART0_BASE
    //mov r6,#0 

.wait_rx_fifo:
    //bl .checkinative
    ldr r2, [r1, #0x14] 
    and r2, r2, #(1<<0)
    cmp r2, #0
    beq .wait_rx_fifo

    //mov r6,#0 

    ldrb    r0, [r1]
    ldmfd sp!,{r1-r6,pc}
/********************************************************/
/*
.checkinative:
    bl .delay_1s
    add r6,r6,#1
    cmp r6,#(0x700)
    bleq .reset_board
    bx lr
*/
/********************************************************
UART0 ISR 
********************************************************/

.global uart0_isr
.uart_isr:
    stmfd sp!,{r0-r12,lr}
    ldr r5, =UART0_BASE
    ldr r1, [r5, #UART_IIR]      // read interrupt ID register spruh73l 19.5.1.9
    mov r2, #0x0                 // disab UART interrupts (clobber them all)
    str r2, [r5, #UART_IER]
    and r1, r1, #0x3E           // strip out IT_TYPE  tab 19-38
    cmp r1, #0x4                // RHR interrupt bit
    bne 1f
    ldrb r0, [r5, #UART_RHR]  // read byte
    bl .uart_putc
    cmp r0,#'\r'
    bleq .check_cmd
    beq uart0_isr_exit

    ldr r1,=end_buffer
    ldr r4,[r1]
    ldr r3,=buffer_uart
    strb r0,[r3,r4]

    add r4,r4,#1
    str r4,[r1]
    
    b uart0_isr_exit

 /* .fimstring:
    mov r2,#'\0'
    ldr r4,[r1]
    strb r2,[r3,r4]
    b retu */

1:
    /*cmp r1, #0x2                // THR interrupt bit
    bne uart0_isr_exit          // get tx byte
    
    ldr r3,=end_buffer
    ldr r4,[r3]    
    ldr r1, =buffer_uart 
    ldr r2, [r1,r4]
    str r2, [r5, #UART_THR]    */ // write out byte

uart0_isr_exit:
    mov r2, #0x1                 // re-enab RHR interrupts only
    str r2, [r5, #UART_IER]

ldmfd sp!,{r0-r12,pc}

/********************************************************/

.section .rodata
.align 4
    hello:                   .asciz "helloworld\n\r"
    

/* Data Section */
.section .data
.balign 4

.global buffer_uart
buffer_uart: .skip 128

.global end_buffer
end_buffer: .word 0

.section .bss
.align 4

