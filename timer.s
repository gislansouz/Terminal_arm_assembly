.equ TIMER7_BASE,0x4804A000
.equ CKM_PER_TIMER7_CLKCTRL,0x44E0007C
.equ delay_timer_1s,0x00FFFFF0 

.section .text,"ax"
         .code 32
         .align 4
.global .timer_init
.timer_init:
    stmfd sp!,{r0-r5,lr}
    ldr r0,=CKM_PER_TIMER7_CLKCTRL
    ldr r1,[r0]
    orr r1,r1,#0x2
    str r1,[r0]

    ldr r0, =INTC_BASE
    ldr r1,[r0,#0xc8]
    orr r1,r1,#(1<<31)   
    str r1, [r0, #0xc8] 
    ldmfd sp!,{r0-r5,pc}

.timer_enable:
    stmfd sp!,{r0-r1,lr}
    ldr r0,=TIMER7_BASE
    ldr r1,[r0,#0x38]
    orr r1,r1,#0x1
    str r1,[r0,#0x38]
    ldmfd sp!,{r0-r1,pc}

.timer_disable:
stmfd sp!,{r0-r1,lr}
    ldr r0,=TIMER7_BASE
    ldr r1,[r0,#0x38]
    and r1,r1,#~(0x1)
    str r1,[r0,#0x38]
stmfd sp!,{r0-r1,lr}

.global .delay_dtimer
.delay_dtimer:
    stmfd sp!,{r0-r5,lr}
    ldr r1,=TIMER7_BASE
    ldr r2,=delay_timer_1s
    ldr r0,[r2]
    str r0,[r1,#0x40]

    ldr r2,=flag_timer
    mov r0,#0
    str r0,[r2]

    ldr r0,=TIMER7_BASE
    mov r1,#0x2
    str r1,[r0,#0x2c]

    ldr r0, =hello
    bl .print_string

    bl .timer_enable
    
    loop_enable:
        ldr r0,[r1,#0x3C]
        bl .hex_to_ascii
        bl .pularlinha
        ldr r0,[r2]
        cmp r0,#0
    beq loop_enable

    ldr r1,=TIMER7_BASE
    mov r0,#0x2
    str r0,[r1,#0x30]

    ldmfd sp!,{r0-r5,pc}

.global .timer_irq_halder
.timer_irq_halder:
    stmfd sp!,{r0-r5,lr}
    ldr r1,=TIMER7_BASE
    mov r0,#0x2
    str r0,[r1,#0x28]

    ldr r2,=flag_timer
    mov r0,#1
    str r0,[r2]

    ldr r0, =irqtimer
    bl .print_string

    bl .timer_disable
    ldmfd sp!,{r0-r5,pc}

.global .watchdog
.watchdog:
    stmfd sp!,{r0-r5,lr}
    ldr r5,=UART0_BASE
    mov r2, #0x0            
    str r2, [r5,#0x4]

    bl .delay_dtimer
    ldmfd sp!,{r0-r5,pc}

.section .data
.balign 4

flag_timer: .word 0x00000000