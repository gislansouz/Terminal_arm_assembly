/* Global Symbols */
.global .uart_putc
.global .uart_getc
.type .uart_getc, %function
.type .uart_putc, %function
.global .uart_isr

/* Registradores */
.equ UART0_BASE, 0x44E09000

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4
/********************************************************
UART0 SETUP (Default configuration)  
********************************************************/
	/* Enable Interrupt RHR(receiver uart0)*/
    	ldr r1, =UART0_BASE
    	ldr r2, [r1, #0x4]
    	orr r2,r2,#0x1
    	str r2, [r1, #0x4]
    
    	/* Interrupt mask */
    	ldr r0, =INTC_BASE
    	ldr r1, =#(1<<8)    
    	str r1, [r0, #0xc8] //(72 --> Bit 8 do 3º registrador (MIR CLEAR2))

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
    stmfd sp!,{r1-r2,lr}
    ldr     r1, =UART0_BASE

.wait_rx_fifo:
    ldr r2, [r1, #0x14] 
    and r2, r2, #(1<<0)
    cmp r2, #0
    beq .wait_rx_fifo

    ldrb    r0, [r1]
    ldmfd sp!,{r1-r2,pc}
/********************************************************/


/********************************************************
UART0 ISR 
********************************************************/
.uart_isr:
    stmfd sp!, {r0-r3, lr}
    bl .uart_getc
    
    ldr r1,=end_buffer
    ldr r2,[r1]
    ldr r3,=buffer_uart
    strb r0,[r3,r2]

    add r2,r2,#1
    strb r2,[r1]
    
    cmp r0,#'\r'
    bleq .check_cmd

    ldmfd sp!, {r0-r3, pc}
/********************************************************/


/* Data Section */
.section .data
.align 4

.global end_buffer
end_buffer: .word 0

/* BSS Section */
.section .bss
.align 4

.equ SIZE, 64
.global buffer_uart
buffer_uart: .fill SIZE
