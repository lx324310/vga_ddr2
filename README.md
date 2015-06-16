# vga_ddr2
A simple Hardware system for VGA display test on xilinx ml501 board
Here is the archtecture of this system

![image](https://github.com/lx324310/vga_ddr2/blob/master/doc/vga_ddr2.png)

In this system,wb_master is used to fill image to ddr2. I2C control is use to config CH7301 chip, DDR2 control have 4 KB cache line,the system clock is 50 MHZ, VGA_control data width is 32bit. So ignoring DDR2 cache miss 
the bandwidth is 1.6Gbps can hope to display 800x600size of image in 60hz  refresh frequncy . Actually in my test on xilinx ml501 board, It can only display
display 640x480size of image in 60hz refresh frequncy stably.
Here is two ways to increase the resolution of vga

1、Increase the system frequncy(be limited by FPGA )

2、enlarge the data width of VGA and DDR2 control(choose the way)

SO I design the system again by enlarge the data width of VGA and DDR2 control and test succesfully in xilinx ml501 board.
This design can display 800x600 size of 60hz refresh frequncy stably
