.global .check_cmd
.global .counter_leds
.global .set_rtc
.type .check_cmd, %function
.type .counter_leds, %function
.type .set_rtc, %function
.global .set_ledon
.global ascii_hex

.equ GPIO1_SETDATAOUT, 0x4804C194
.equ GPIO1_CLEARDATAOUT, 0x4804C190
.equ PRM_RSTCTRL,0x44E00F00
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

    ldr r0, =print_mem
    mov r2,#8
	bl .memcmp
    cmp r0,#0
    bleq .printmem

    ldr r0, =sequencia
    mov r2,#9
	bl .memcmp
    cmp r0,#0
    bleq .sequencia

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
    bleq .counter_leds

    ldr r0, =stringequal
    mov r2,#11
	bl .memcmp
    cmp r0,#0
    bleq .stringequal

    ldr r0, =time
    mov r2,#4
	bl .memcmp
    cmp r0,#0
    bleq .print_time

    ldr r0, =memory
    mov r2,#6
	bl .memcmp
    cmp r0,#0
    bleq .memory

    ldr r0, =mem_register
    mov r2,#11
	bl .memcmp
    cmp r0,#0
    bleq .register_mem

    ldr r0, =sum_status
    mov r2,#9
	bl .memcmp
    cmp r0,#0
    bleq .status_cpsr

    ldr r0, =digit_led
    mov r2,#3
	bl .memcmp
    cmp r0,#0
    bleq .dec_digit_led

    ldr r0, =blinkled
    mov r2,#5
	bl .memcmp
    cmp r0,#0
    bleq .blink_led

    ldr r0, =resetcmd
    mov r2,#5
	bl .memcmp
    cmp r0,#0
    bleq .reset_board

    //ldr r0, =cacheinfo
    //mov r2,#5
	//bl .memcmp
    //cmp r0,#0
    //bleq .cacheinfo

    ldr r0, =goto
    mov r2,#4
	bl .memcmp
    cmp r0,#0
    bleq .goto

    //ldr r0, =watchdog
    //mov r2,#8
	//bl .memcmp
    //cmp r0,#0
    //bleq .watchdog

    volta:

    ldr r1,=end_buffer
    mov r2,#0
    str r2,[r1]

    ldr r0,=buffer_uart
    mov r1,#30
    bl .memory_clear

    ldr r0, =cmdpointer
    bl .print_string

 ldmfd sp!,{r0-r12,pc}
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
        bl .int_to_ascii

        mov r1,r3,LSL #21
        str r1, [r2]
		add r3,r3,#1
		bl .delay_1s
        bl .poweroff_led
        voltaloop:
        cmp r3,#16
    bne .contador   
    b fim

.poweroff_led:
    ldr r0, =GPIO1_CLEARDATAOUT
    ldr r1, =(0xf<<21)
    str r1, [r0]
    b voltaloop

    fim:
    bl .pularlinha

ldmfd sp!,{r0-r3,pc}
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
    mov r1, r1, LSL #4
    bic r0,r0,#(0xf<<4)
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
    mov r1, r1, LSL #4
    bic r0,r0,#(0xf<<4)
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
    mov r1, r1, LSL #4
    bic r0,r0,#(0xf<<4)
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
    ldr r0,=ledonmsg
    bl .print_string
    b volta
/********************************************************/

/********************************************************
Imprimi o conteudo da memoria dos registradores no intervalo 
escolhido pelo usuario
/********************************************************/
.register_mem:
    stmfd sp!,{r0-r11,lr}
    ldr r2,=buffer_uart
    add r2,r2,#12
    mov r3,#0

    //primeiro digito
    add r2,r2,#1
    ldrb r0,[r2]
    sub r2,r2,#1
    cmp r0,#0x20
    ldrneb r0,[r2]
    blne .ascii_to_dec_digit
    movne r6,#10
    mulne r5,r0,r6
    addne r3,r3,r5
    addne r2,r2,#1

    ldrb r0,[r2]
    bl .ascii_to_dec_digit
    add r3,r3,r0
    add r2,r2,#2

    //segundo digito
    mov r4,#0
    add r2,r2,#1
    ldrb r0,[r2]
    sub r2,r2,#1
    cmp r0,#0x0
    ldrneb r0,[r2]
    blne .ascii_to_dec_digit
    movne r6,#10
    mulne r5,r0,r6
    addne r4,r4,r5
    addne r2,r2,#1

    ldrb r0,[r2]
    bl .ascii_to_dec_digit
    add r4,r4,r0

    mov r0,r3
    mov r1,r4
    bl .min_max
    sub r2,r0,r1
    cmp r0,#16
    ldrge r0,=erroregister
    blge .print_string
    bge fimregister
    add r2,r2,#1

    stmfd sp!,{r0-r3}
    //ldr r0,=array_buff
    //ldm r0, {r1-r5} 
    ldr r0,=array_registers
    stmib r0, {r1-r15}
    str r0,[r0]
    ldmfd sp!,{r0-r3}


    ldr r3,=array_registers
    mov r0,#4
    mul r4,r1,r0
    add r3,r3,r4
    mov r4,r1

    loop_regiters:  
        mov r0,#'R'
        bl  .uart_putc

        mov r0,r4
        bl .int_to_ascii
        add r4,r4,#1

        ldr r0, =dump_separator
        mov r1, #5
        bl .print_nstring

        ldr r0,[r3]
        bl .hex_to_ascii
        add r3,r3,#4
        sub r2,r2,#1
        bl .pularlinha
        cmp r2,#0
        bne loop_regiters
        
        fimregister:
    ldmfd sp!,{r0-r11,pc}




/********************************************************/
/********************************************************
Imprimi o conteudo da memoria
buffer uart com endereços finais e iniciais
/********************************************************/
.memory:
    ldr r2,=buffer_uart
    add r2,r2,#9
    bl .ascii_to_adress_hex
    mov r5,r4

    ldr r2,=buffer_uart
    add r2,r2,#20
    bl .ascii_to_adress_hex

    inverso:
    mov r0,r5
    mov r1,r4
    bl .min_max

    cmp r0,r5
    moveq r7,#1
    movne r7,#0

    mov r0,r5
    mov r1,r4
    bl .min_max
    sub r0,r0,r1
    cmp r0,#4
    movlt r0,#4
    mov r3,r0

    mov r6,#0
    memdiv_loop:
    cmp r0,#4
    subgt r0,r0,#4
    addgt r6, r6, #4
    bgt memdiv_loop
    add r6,r6,#8

    mov r0,r5
    mov r1,r6
    bl .memory_dump

    //ldr r0,=buffer_uart
    //bl .hex_to_ascii
    b volta


/********************************************************
Imprimi o conteudo da memoria
buffer uart com endereços finais e iniciais
/********************************************************/
 .ascii_to_adress_hex: 
 stmfd sp!,{r0-r3,lr}
    mov r4,#0
    mov r3,#28

    .loop_adress:
    ldrb r0,[r2]
    bl .ascii_to_hex
    mov r1, r0, LSL r3
    add r4,r1,r4
    add r2,r2,#1
    subs r3,#4
    bge .loop_adress

    ldmfd sp!,{r0-r3,pc}
/********************************************************/

/********************************************************/


/********************************************************
funcao faz uma soma de dois valores hexadecimais e imprimi 
o estado de CPSR após a soma.
/********************************************************/
.status_cpsr:
    stmfd sp!,{r0-r5,lr}
    ldr r2,=buffer_uart
    add r2,r2,#12
    bl .ascii_to_adress_hex
    mov r1,r4

    add r2,r2,#11
    bl .ascii_to_adress_hex

    /********************************************************
    set mode arm operation
    /********************************************************/
    adds r4,r4,r1
    mrs r1,cpsr
    mov r6,r1

    ldr r3,=cpsrstatus
    add r3,r3,#10
    ldr r4,=modos
    mov r5,#0

    and r1,r1,#0x1F

    cmp r1,#0x17 //mode abt
    moveq r5,#0

    cmp r1,#0x11 //mode fiq
    moveq r5,#4

    cmp r1,#0x12 //mode irq
    moveq r5,#8

    cmp r1,#0x13 //mode svc
    moveq r5,#12

    cmp r1,#0x1F //mode sys
    moveq r5,#16

    cmp r1,#0x1B //mode und
    moveq r5,#20

    cmp r1,#0x10 //mode usr
    moveq r5,#24
    
    bl .mudarmodo

    mov r1,r6

    /********************************************************
    set FLAGS cpsr
    /********************************************************/
    ldr r3,=cpsrstatus

    /********************************************************/
    ands r2,r1,#(1<<31) //set bit flag negative
    movne r2,#'N'       
    moveq r2,#'n'
    strb r2,[r3]

    /********************************************************/
    ands r2,r1,#(1<<30) //set bit flag zero
    movne r2,#'Z'
    moveq r2,#'z'
    strb r2,[r3,#1]

    /********************************************************/
    ands r2,r1,#(1<<29) //set bit flag carry
    movne r2,#'C'
    moveq r2,#'c'
    strb r2,[r3,#2]

    /********************************************************/
    ands r2,r1,#(1<<28)  //set bit flag overflow
    movne r2,#'V'
    moveq r2,#'v'
    strb r2,[r3,#3]

    /********************************************************/
    ands r2,r1,#(1<<27) //set bit flag sticky overflow
    movne r2,#'Q'
    moveq r2,#'q'
    strb r2,[r3,#4]
    

    /********************************************************/
    ands r2,r1,#(1<<24) //set bit flag java state bit
    movne r2,#'J'
    moveq r2,#'j'
    strb r2,[r3,#5]

    /********************************************************/
    ands r2,r1,#(1<<7) //set bit flag IRQ
    movne r2,#'I'
    moveq r2,#'i'
    strb r2,[r3,#6]

    /********************************************************/
    ands r2,r1,#(1<<6) //set bit flag FIQ
    movne r2,#'F'
    moveq r2,#'f'
    strb r2,[r3,#7]

    /********************************************************/
    ands r2,r1,#(1<<5) //set bit flag mode THUMB
    movne r2,#'T'
    moveq r2,#'t'
    strb r2,[r3,#8]

    /********************************************************/

    ldr r0,=cpsrstatus
    bl .print_string

    ldmfd sp!,{r0-r5,pc}
/********************************************************/

/********************************************************
função seta o modo de operação na string cpsrstatus
r3->endereço do cpsrstatus
r4->endereço da sting com os modos de operaçao
r5->offset para o modo especifico
/********************************************************/
    .mudarmodo:
        stmfd sp!,{r0-r5,lr}
        add r4,r4,r5
        mov r2,#0
        l:
        ldrb r5,[r4,r2]
        strb r5,[r3,r2]
        add r2,r2,#1
        cmp r2,#3
        bne l
        ldmfd sp!,{r0-r5,pc}

/********************************************************/
/********************************************************
apresenta o numero passado por paramentro em binario em 
quatro leds numero entre 0 e 15
/********************************************************/
.dec_digit_led: 
    stmfd sp!,{r0-r5,lr}
    ldr r2,=buffer_uart
    ldrb r0,[r2,#4]
    bl .ascii_to_dec_digit
    mov r3,#10
    mul r1,r3,r0
    ldrb r0,[r2,#5]
    bl .ascii_to_dec_digit
    add r1,r1,r0

    ldr r2, =GPIO1_SETDATAOUT
    mov r1,r1,LSL #21
    str r1, [r2]
    ldmfd sp!,{r0-r5,pc}
/********************************************************/

/********************************************************
pisca o N vezes passada por paramentro
/********************************************************/
.blink_led:
stmfd sp!,{r0-r5,lr}
    ldr r2,=buffer_uart
    ldrb r0,[r2,#6]
    bl .ascii_to_dec_digit
    mov r3,#10
    mul r1,r3,r0
    ldrb r0,[r2,#7]
    bl .ascii_to_dec_digit
    add r1,r1,r0

    mov r0,#(0xf<<21)

    loopblk:
        ldr r2, =GPIO1_SETDATAOUT
        str r0, [r2]
		bl .delay

        ldr r2, =GPIO1_CLEARDATAOUT
        str r0, [r2]
        bl .delay

        subs r1,r1,#1
        cmp r1,#0
    bne loopblk  

ldmfd sp!,{r0-r5,pc}
/********************************************************/

/********************************************************
reseta a placa
/********************************************************/
.global .reset_board
.reset_board:
    ldr r2, =PRM_RSTCTRL
    mov r1,#1
    str r1, [r2]
/********************************************************/

/********************************************************
muda o pc para o endereço passado por parametro
/********************************************************/
.goto:
    ldr r2,=buffer_uart
    add r2,r2,#7
    bl .ascii_to_adress_hex
    mrs r0, cpsr
	bic r0, r0, #0x1f /* clear mode bits */
	orr r0, r0, #0xd3 /* disable IRQ and FIQ interrupts and set Supervisor mode */
	msr cpsr, r0

    ldr r1,=end_buffer
    mov r2,#0
    str r2,[r1]

    ldr r0,=buffer_uart
    mov r1,#30
    bl .memory_clear

    bx r4
  
/********************************************************/

/********************************************************
conta de 10 a 0 e reinicia a placa
/********************************************************/
.printmem:
stmfd sp!,{r0-r7,lr}
    ldr r0,=_vector_table
    mov r1,#(0x1698)
    mov r7,#0
    bl .memory_dump
ldmfd sp!,{r0-r7,pc}

/********************************************************/
/********************************************************
conta de 10 a 0 e reinic.cacheinfo:
ia a placa
/********************************************************
    .mudarmodo:
        stmfd sp!,{r0-r5,lr}
        add r4,r4,r5
        mov r2,#0
        l:
        ldrb r5,[r4,r2]
        strb r5,[r3,r2]
        add r2,r2,#1
        cmp r2,#3
        bne l
        ldmfd sp!,{r0-r5,pc}

/********************************************************/


/* Read-Only Data Section */
.section .rodata
.align 4
.global hello
hello:                   .asciz "hello world!\n\r"
.global irqtimer
irqtimer:                .asciz "irqtimer\n\r"
ledoffmsg:               .asciz "led off usr0-usr3\n\r"
ledonmsg:                .asciz "led on usr0-usr3\n\r"
cmdpointer:              .asciz "->"
cmdpo:                   .asciz ">"
ascii:                   .asciz "0123456789ABCDEF"
dash:                    .asciz "-------------------------\n\r"
hex_prefix:              .asciz "0x"
CRLF:                    .asciz "\n\r"
dump_separator:          .asciz "  :  "
cpsrstatus:              .asciz "nzcvqjIFt_MOD \n\r"
modos:                   .asciz "abt fiq irq svc sys und usr "
erroregister:            .asciz "numero fora do range de registradores\n\r"
/*comandos*/
contador:                .asciz "contador015"
sequencia:               .asciz "sequencia"
stringequal:             .asciz "stringequal"
printhello:              .asciz "helloworld"
print_mem:               .asciz "printmem"
set_timer:               .asciz "set time"
setledoff:               .asciz "led off"
setledon:                .asciz "led on"
time:                    .asciz "time"
cacheinfo:               .asciz "cache"/*falta*/
goto:                    .asciz "goto"
resetcmd:                .asciz "reset"
blinkled:                .asciz "blink"
digit_led:               .asciz "led"
memory:                  .asciz "memory"
mem_register:            .asciz "registermem"
sum_status:              .asciz "sumstatus"
watchdog:                .asciz "watchdog"

.section .data
.balign 4

array_registers: .skip 64


/*array_buff:
 .word 0x00000002     
 .word 0x00000004             
 .word 0x00000006            
 .word 0x00000008             
 .word 0x00000010 */

.section .bss
.align 4
