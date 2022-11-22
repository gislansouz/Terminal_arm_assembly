
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

.global .uart0_init
.uart0_init:
    ldr r0, =UART0_BASE
    mov r1, 0x2                // SOFTRESET, spruh73l 19.5.1.43
    str r1, [r0, UART_SYSC]

1:  ldr r1, [r0, UART_SYSS]
    tst r1, 0x1                // wait for RESETDONE spruh73l tab 19-73
    beq 1b

    mov r1, #0x8               // disable IDLEMODE, spruh73l 19.5.1.43 & tab 19-72
    str r1, [r0, UART_SYSC]

    mov r1, 0x83          // DIV_EN (mode A), 8 data bits, spruh73l 19.5.1.13 19.4.1.1.2
    str r1, [r0, UART_LCR]
    mov r1, 0x1A          // CLOCK_LSB=0x1A, spruh73l 19.5.1.3
    str r1, [r0, UART_DLL]

// the following code prepares FIFOs for IRQ
    mov r1, 0x10          // ENHANCEDEN=1 (enab R/W access to UART_FCR), spruh73l 19.5.1.8
    str r1, [r0, UART_EFR]
    mov r1, 0x57          // FIFO triggers, clr & enab, spruh73l 19.5.1.11
    str r1, [r0, UART_FCR]
    mov r1, 0x0           // ENHANCEDEN=0 (disab R/W access to UART_FCR), spruh73l 19.5.1.8
    str r1, [r0, UART_EFR]
// end of FIFO-IRQ code

    mov r1, 0x0           // MODESELECT-UART 16x mode, spruh73l 19.5.1.26 
    str r1, [r0, UART_MDR1]
    ldr r1, [r0, UART_LCR]
    bic r1, r1, 0x80      // clear DIV_EN, switch to operational mode, spruh73l 19.5.1.13
    str r1, [r0, UART_LCR]

// the following extra code prepares FIFOs for IRQ
    mov r1, 0xC8       // Rx & Tx FIFO granularity=1, TXEMPTYCTLIT=1 , spruh73l 19.5.1.39
    str r1, [r0, UART_SCR]
// end of extra FIFO-IRQ code
    
    mov r1, 0x1                // enab interrupt RHR_IT, spruh73l 19.5.1.6, 19.3.6.2
    str r1, [r0, UART_IER]

    mov r0, 0
    bx lr





.uart_setup:
    stmfd sp!,{r0-r2,lr}
	/* Enable Interrupt RHR(receiver uart0)*/
    	ldr r1, =UART0_BASE
    	ldr r2, [r1, #0x4]
    	and r2,r2,#0x1
    	str r2, [r1, #0x4]

        ldr r0, =INTC_ILR
        ldr r1, =#0    
        strb r1, [r0, #72]
    
    	/* Interrupt mask */
    	ldr r0, =INTC_BASE
    	ldr r1, =#(1<<8)    
    	str r1, [r0, #0xc8] //(72 --> Bit 8 do 3º registrador (MIR CLEAR2))
    ldmfd sp!,{r0-r2,pc}



    .global uart0_isr
uart0_isr:
    ldr r0, =UART0_BASE
    ldr r1, [r0, #UART_IIR]      // read interrupt ID register spruh73l 19.5.1.9
    mov r2, 0x0                 // disab UART interrupts (clobber them all)
    str r2, [r0, #UART_IER]
    and r1, r1, #0x3E           // strip out IT_TYPE  tab 19-38
    cmp r1, #0x4                // RHR interrupt bit
    bne 1f
    ldr r2, [r0, #UART_RHR]      // read byte
    ldr r1, =buffer_uart      // store byte in C variable
    str r2, [r1]
    b uart0_isr_exit
1:
    cmp r1, #0x2                // THR interrupt bit
    bne uart0_isr_exit
    ldr r1, =uart0_tbuf         // get tx byte
    ldr r2, [r1]
    str r2, [r0, UART_THR]      // write out byte

uart0_isr_exit:
    ldr r2, =end_buffer   // increment counter, C variable
    ldr r1, [r2]
    add r1, r1, #0x1
    str r1, [r2]


    mov r2, 0x1                 // re-enab RHR interrupts only
    str r2, [r0, #UART_IER]
    bx lr





    .array_sum:
        stmfd sp!,{r0-r7,lr}
        mov r4,#0
    .array_sum_loop:
        cmp r4,r0
        bge .fim_array_sum

        ldr r5,[r1],#4
        ldr r6,[r2],#4
        add r7,r5,r6
        str r7,[r3],#4
        add r4,r4,#1

        b .array_sum_loop
    .fim_array_sum:
        ldmfd sp!,{r0-r7,pc}

    array_sum_thumb:
        ldr r5,[r1],#4
        ldr r6,[r2],#4
        add r5,r6
        mov r7,r5
        str r7,[r3],#4
        add r4,r4,#1
