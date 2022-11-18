.global .check_cmd
.global .counter_leds
.global .set_rtc
.type .check_cmd, %function
.type .counter_leds, %function
.type .set_rtc, %function
.global .set_ledon

.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190

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
stmfd sp!,{r0-r12,lr}

    ldr r0,=CRLF
    bl .print_string

    ldr r1, =buffer_uart
    ldr r0, =set_timer
    mov r2,#8
	bl .memcmp
    cmp r0,#0
    beq .set_rtc

    ldr r0, =setledon
    mov r2,#6
	bl .memcmp
    cmp r0,#0
    beq .set_ledon

    ldr r0, =sequencia
    mov r2,#9
	bl .memcmp
    cmp r0,#0
    beq .sequencia

    ldr r0, =setledoff
    mov r2,#7
	bl .memcmp
    cmp r0,#0
    beq .set_ledoff
    
    ldr r0, =printhello
	bl .memcmp_chksum
    cmp r0,#0
    bleq .helloworld

    ldr r0, =contador
    mov r2,#11
	bl .memcmp
    cmp r0,#0
    beq .counter_leds

    ldr r0, =time
    mov r2,#4
	bl .memcmp
    cmp r0,#0
    bleq .print_time

    volta:

    ldr r1,=end_buffer
    mov r2,#0
    str r2,[r1]

    ldr r0, =cmdpointer
    bl .print_string

 ldmfd sp!,{r0-r12,pc}
/********************************************************/

/********************************************************
contador 0-15 nos leds da placa e imprime na tela
/********************************************************/
.counter_leds:
//stmfd sp!,{r0-r3,lr}
    mov r3,#0
    .contador:
        ldr r2, =GPIO1_SETDATAOUT
        mov r0, r3
        bl .int_to_ascii

        mov r1,r3,LSL #21
        str r1, [r2]
		add r3,r3,#1
		bl .delay_1s
        bl .poweroff_led
        voltaloop:
        cmp r3,#16
    bne .contador   
    b volta

.poweroff_led:
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(0xf<<21)
    str r1, [r0]
    b voltaloop



 //ldmfd sp!,{r0-r3,pc}
/********************************************************/

/********************************************************
Setar horario RTC
/********************************************************/
.set_rtc:
stmfd sp!,{r0-r3}

    ldr r2,=buffer_uart
    add r2,r2,#9

    ldrb r1,[r2]
    mov r0,r1
    bl .ascii_to_dec_digit
    mov r1,r0
    ldrb r0,[r2,#1]
    bl .ascii_to_dec_digit
    bl .set_hours_rtc

    ldrb r1,[r2,#3]
    mov r0,r1
    bl .ascii_to_dec_digit
    mov r1,r0
    ldrb r0,[r2,#4]
    bl .ascii_to_dec_digit
    bl .set_minutes_rtc

    ldrb r1,[r2,#6]
     mov r0,r1
    bl .ascii_to_dec_digit
    mov r1,r0
    ldrb r0,[r2,#7]
    bl .ascii_to_dec_digit
    bl .set_seconds_rtc

ldmfd sp!,{r0-r3}
b volta
/********************************************************/

/********************************************************
Setar hora rtc 
R0->primeiro digito da hora
R1->segundo digito da hora
/********************************************************/
    .set_hours_rtc:
    mov r0, r0, LSL #4
    and r1,r1,#~(0xf<<4)
    orr r0,r1,r0
    ldr r1,=RTC_BASE
    str r0, [r1, #8] //hours
    bx lr

/********************************************************
Setar minutos rtc 
R0->primeiro digito dos minutos
R1->segundo digito dos minutos
/********************************************************/
    .set_minutes_rtc:
    mov r0, r0, LSL #4
    bic r1,#~(0xf<<4)
    orr r0,r1,r0
    ldr r1,=RTC_BASE
    strb r0, [r1, #4] //minutes
    bx lr

/********************************************************
Setar segundos rtc 
R0->primeiro digito dos segundos
R1->segundo digito dos segundos
/********************************************************/
    .set_seconds_rtc:
    mov r0, r0, LSL #4
    and r1,r1,#~(0xf<<4)
    orr r0,r1,r0
    ldr r1,=RTC_BASE
    str r0, [r1] //seconds
    bx lr

/********************************************************
print hello World
/********************************************************/
.helloworld:
    ldr r0, =hello
    bl .print_string
    b volta
/********************************************************/

/********************************************************
setar led off
/********************************************************/
.set_ledoff:
//stmfd sp!,{r0-r3,lr}
    ldr r0, =GPIO1_CLEARDATAOUT
    mov r1, #(0xf<<21)
    str r1, [r0]
    ldr r0,=ledoffmsg
    bl .print_string
    b volta

 //ldmfd sp!,{r0-r3,pc}
/********************************************************/

/********************************************************
set_ledon
/********************************************************/
.set_ledon:
    ldr r2, =GPIO1_SETDATAOUT
    mov r1, #(0xf<<21)
    str r1, [r2]
    //ldr r0,=ledonmsg
    //bl .print_string
    b volta
/********************************************************/

/********************************************************
set_ledon
/********************************************************/
.sequencia:
    //stmfd sp!,{r0-r3}
    mov r0,#'>'
    bl .uart_putc
    _loop:  
        bl .uart_getc
        bl .uart_putc
        cmp r0,#'\r'
        ldreq r0,=CRLF
        bleq .print_string
        beq .sequencia
        cmp r0,#'a'
        ldreq r0,=CRLF
        bleq .print_string
        beq volta
        b _loop
    
    //ldmfd sp!,{r0-r3}
/********************************************************/ 

/* Read-Only Data Section */
.section .rodata
.align 4
hello:                   .asciz "hellrld\n\r"
ledoffmsg:               .asciz "led off usr0-usr3\n\r"
ledonmsg:                .asciz "led on usr0-usr3\n\r"
cmdpointer:              .asciz "->"
cmdpo:              .asciz ">"
ascii:                   .asciz "0123456789ABCDEF"
dash:                    .asciz "-------------------------\n\r"
hex_prefix:              .asciz "0x"
CRLF:                    .asciz "\n\r"
dump_separator:          .asciz "  :  "

/*comandos*/
contador:                .asciz "contador015"
sequencia:               .asciz "sequencia"
printhello:              .asciz "helloworld"
set_timer:               .asciz "set time"
setledoff:               .asciz "led off"
setledon:                .asciz "led on"
time:                    .asciz "time"
cacheinfo:               .asciz "cache"/*falta*/
goto:                    .asciz "goto" /*falta*/
reset:                   .asciz "reset"/*falta*/
blinkled:                .asciz "blink"/*falta*/
dec_digit_led:           .asciz "led"/*falta*/

.section .bss
.align 4
