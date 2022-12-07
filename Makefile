CROSS_COMPILE ?= arm-linux-gnueabihf-

#FILES = uart.s utils.s wdt.s cp15.s gpio.s comandos.s

OBJS = startup.o uart.o utils.o wdt.o cp15.o gpio.o rtc.o comandos.o timer.o sequencia.o

%.o: %.s
	$(CROSS_COMPILE)as $< -o $@


all:  $(OBJS)
	$(CROSS_COMPILE)ld -o startup -T memmap $(OBJS)
	$(CROSS_COMPILE)objcopy startup startup.bin -O binary
	$(CROSS_COMPILE)objdump -DSx -b binary -marm startup.bin > startup.lst
	cp *.bin /tftpboot/

clean:
	rm *.o *.bin *.lst
	


