.global .sequencia

.section .text,"ax"
         .code 32
         .align 4

/********************************************************
sequencia de array
/********************************************************/
.sequencia:
    stmfd sp!,{r0-r3,lr}
    bl .seqpointer

    _loop:  
        bl .uart_getc
        bl .uart_putc

        cmp r0,#'\r'
        beq negative

        cmp r0,#'-'
        beq negative

        cmp r0,#(0x30)
        blt fimsequencia
        cmp r0,#(0x39)
        bgt fimsequencia

        negative:

        cmp r0,#'\r'
        bleq .dividir_numeros
        cmp r0,#'\n'
        cmp r0,#(0x0D)
        blne .guardar_buffer

        b _loop

        fimsequencia:
            ldr r1,=end_buff_seq
            ldr r2,[r1]
            sub r2,r2,#1
            str r2,[r1]
            mov r0,#0
            bl .guardar_buffer
            bl .print_buffer
            mov r2,#0
            str r2,[r1]
    ldmfd sp!,{r0-r3,pc}
/********************************************************/ 
.guardar_buffer:
    stmfd sp!,{r1-r4,lr}
        ldr r2,=sequence_buff
        ldr r1,=end_buff_seq
        ldr r4,[r1]
        strb r0,[r2,r4]

        add r4,r4,#1
        str r4,[r1]

    ldmfd sp!,{r1-r4,pc}
/********************************************************/ 
.dividir_numeros:
    stmfd sp!,{r0-r4,lr}
        mov r0,#','
        bl .guardar_buffer

        ldr r1,=size_vetor
        ldr r4,[r1]
        add r4,r4,#1
        str r4,[r1]

        ldr r0,=CRLF
        bl .print_string
        bl .seqpointer
    ldmfd sp!,{r0-r4,pc}
/********************************************************/ 
.seqpointer:
        stmfd sp!,{r0,lr}
            mov r0,#'>'
            bl .uart_putc
        ldmfd sp!,{r0,pc}
/********************************************************/ 
.global .stringequal
.stringequal:
    stmfd sp!,{r0-r3,lr}
    bl .seqpointer

    _loopstr:  
        bl .uart_getc
        bl .uart_putc

        cmp r0,#'\r'
        beq fimstring
        cmp r0,#(0x0D)
        blne .guardar_buffer

        b _loopstr

        fimstring:
            ldr r1,=end_buff_seq
            mov r0,#0
            bl .guardar_buffer
            ldr r0,=CRLF
            bl .print_string
            mov r2,#0
            str r2,[r1]

        bl .seqpointer

        _loopstr2:  
        bl .uart_getc
        bl .uart_putc

        cmp r0,#'\r'
        beq fimstring2
        cmp r0,#(0x0D)
        blne .guardar_string2

        b _loopstr2

        fimstring2:
            mov r0,#0
            bl .guardar_string2
            ldr r0,=CRLF
            bl .print_string

        ldr r0,=string_buff
        ldr r1,=sequence_buff
        bl .memcmp_chksum
        cmp r0,#0
        bne diferentes

        ldr r1,=end_buff_seq
        ldr r2,[r1]
        ldr r0,=string_buff
        ldr r1,=sequence_buff
        bl .memcmp
        cmp r0,#0
        beq iguais
    
        diferentes:
        ldr r0,=diferentesst
        bl .print_string
        b fimequal


        iguais:
        ldr r0,=iguaisst
        bl .print_string

        fimequal:
            ldr r1,=end_buff_seq
            mov r2,#0
            str r2,[r1]

    ldmfd sp!,{r0-r3,pc}
/********************************************************/ 
.guardar_string2:
    stmfd sp!,{r1-r4,lr}
        ldr r2,=string_buff
        ldr r1,=end_buff_seq
        ldr r4,[r1]
        strb r0,[r2,r4]

        add r4,r4,#1
        str r4,[r1]

    ldmfd sp!,{r1-r4,pc}

/* .coverte_value:
    stmfd sp!,{r0-r7,lr}

    ldr r0,=sequence_buff_input
    mov r1,#12
    mov r7,#0
    bl .memory_dump

    mov r3,#1
    mov r5,#0
    ldr r4,=end_buffer_seq
    ldr r1,[r4]
        mov r0,r1
        bl .int_to_ascii
    sub r1,r1,#1

    looparray:
        ldr r2,=sequence_buff_input
        ldrb r0,[r2,r1]

        bl .ascii_to_dec_digit

        mul r0,r0,r3    
        bl .int_to_ascii

        mov r7,#10
        mul r3,r7,r3

        mov r0,r3
        bl .int_to_ascii

        add r5,r0,r5

        mov r0,r5
        bl .int_to_ascii

        sub r1,r1,#1

        cmp r1,#0
        bne looparray

        ldr r2,=end_buff
        ldr r1,[r2]
        ldr r4,=array_buff
        str r5,[r4,r1]

        add r1,r1,#4
        str r1,[r2]

        ldr r0,=array_buff
        mov r1,#12
        mov r7,#0
        bl .memory_dump

    ldmfd sp!,{r0-r7,pc}
 */
.print_buffer:
    stmfd sp!,{r0-r5,lr}
        ldr r0,=CRLF
        bl .print_string

        ldr r0,=iniciovetor
        bl .print_string

        ldr r1,=size_vetor
        ldr r0,[r1]
        bl .int_to_ascii
        
        ldr r0,=meiovetor
        bl .print_string

        ldr r0,=sequence_buff
        bl .print_string

        ldr r0,=fimvetor
        bl .print_string

        ldr r0,=CRLF
        bl .print_string

    /*loopprintarray:
        ldr r0,[r4,r3]
        bl .int_to_ascii
        add r3,r3,#4
        cmp r1,#0
        beq endloop
        subs r1,r1,#4
    bge loopprintarray
    endloop:*/

    ldmfd sp!,{r0-r5,pc}



.section .rodata
.align 4

digite_num:              .asciz "Digite os numeros:\n\r"
iniciovetor:             .asciz "X["
meiovetor:               .asciz "] = {"
fimvetor:                .asciz "}"   
iguaisst:                  .asciz "strings iguais\n\r"
diferentesst:              .asciz "strings diferentes\n\r"

.section .data
.balign 4

sequence_buff: .skip 128

string_buff: .skip 128

end_buff_seq: .word 0
size_vetor: .word 0

.section .bss
.align 4
