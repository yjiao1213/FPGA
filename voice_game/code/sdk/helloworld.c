/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xiomodule.h" // add this file
#include "xparameters.h" // add
#include "xil_printf.h" // add
#include <math.h>

int main()
{
    init_platform();

    XIOModule gpo;
    XIOModule gpi;

    XIOModule_Initialize(&gpo, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpo);

    XIOModule_Initialize(&gpi, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpi);
    u16 mic_data;
    u8 data;
//    int mic_data_buf,i,k,max;
//    int j,m,
//    int count,lock;
//    int db,a,b,c,d,e;
//    int pcm[6];
//    u8 pcm;
//    pcm=0x00;
//    int pcm_buf[6];
//    u64 final;
//    final = 0x00000000;
//    int pcm_final
    int count,pulse,one,jump;

	xil_printf("the date is 06 11 2018, name is Jiankun Yin\n\r");
//	count =0;
//	one=0;
//	mic_data_buf=0;
    while (1)
    {
    	while (count < 50000){
    		count= count+1;
    		    	mic_data = XIOModule_DiscreteRead(&gpi, 1);
    		    	data=mic_data & 0x0001;
    		    	if (data == 1){
    		    		one=one+1;
    		    	}
    		    	else {
    		    		one=0;
    		    	}
    		    	if (one ==4){
    		    		pulse = pulse +1;
    		    		one=0;
    		    	}
	    	}
	        xil_printf("Value: %d\n\r",pulse);
	        if (pulse > 2000){
	        	jump =1;
	        }
	        else {
	        	jump = 0;
	        }
	    	XIOModule_DiscreteWrite(&gpo, 1, jump);
	        pulse=0;
	        count = 0;
		}
    cleanup_platform();
    return 0;
}
