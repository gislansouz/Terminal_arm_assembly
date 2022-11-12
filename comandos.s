.global .check_cmd

.type .check_cmd, %function

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
/* Read-Only Data Section */
.section .rodata
.align 4
hello:              .asciz "helloworld\n\r"

/* BSS Section */
.section .bss
.align 4
