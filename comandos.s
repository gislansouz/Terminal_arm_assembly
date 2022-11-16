.global .check_cmd
.global .counter_leds
.type .check_cmd, %function
.type .counter_leds, %function

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4

/********************************************************
Limpa memória
R0-> Endereço
R1-> Tamanho
/********************************************************/
.check_cmd:
stmfd sp!,{r0-r3,lr}

    ldr r0, =hello
    bl .print_string

 ldmfd sp!,{r0-r3,pc}
/********************************************************/

/********************************************************
contador 0-15 nos leds da placa e imprime na tela
/********************************************************/
.counter_leds:
stmfd sp!,{r0-r3,lr}
    mov r3,#0
    .contador:
        ldr r2, =GPIO1_SETDATAOUT
        mov r0, r3
        bl .hex_to_ascii

        mov r1,r3,LSL #21
        str r1, [r2]
		add r3,r3,#1
		bl .delay_1s
        bl .poweroff_led
        cmp r3,#16
    bne .contador   

.poweroff_led:
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(0xf<<21)
    str r1, [r0]
    bx lr

 ldmfd sp!,{r0-r3,pc}
/********************************************************/

/********************************************************
Setar hora RTC
/********************************************************/
.set_rtc:
stmfd sp!,{r0-r3,lr}

    ldr r1,=RTC_BASE
    ldr r0, [r1, #8] //hours
    bl .rtc_to_ascii

    ldr r0,=':'
    bl .uart_putc

    ldr r0, [r1, #4] //minutes
    bl .rtc_to_ascii

    ldr r0,=':'
    bl .uart_putc

    ldr r0, [r1, #0] //seconds
    bl .rtc_to_ascii

    ldr r0,='\r'
    bl .uart_putc
    ldmfd sp!, {r0-r2, pc}

ldmfd sp!,{r0-r3,pc}
/********************************************************/

/* Read-Only Data Section */
.section .rodata
.align 4
hello:              .asciz "helloworld\n\r"

/* BSS Section */
.section .bss
.align 4
