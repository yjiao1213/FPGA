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


int main()
{
    init_platform();

    XIOModule gpo;
    XIOModule gpi;

    XIOModule_Initialize(&gpo, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpo);

    XIOModule_Initialize(&gpi, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpi);

    u32 keyboard_buf, key_value, key_value_pre, block_para, block_para_after;
    u16 block_lef, block_len;
    u8 move_flag, space_flag, start_flag;

    xil_printf("12/01/2018, Yixuan Jiao");

    start_flag = 1;

    while(1)
    {
    	keyboard_buf = XIOModule_DiscreteRead(&gpi, 1);
    	block_para = XIOModule_DiscreteRead(&gpi, 2);

    	key_value = keyboard_buf & 0x000000ff;

    	block_len = block_para & 0x000FFF;
    	block_lef = (block_para>>12) & 0x000FFF;

    	if (key_value == key_value_pre)
    	{
    		move_flag = 0;
    	}
    	else
    		move_flag = 1;

    	if (move_flag == 1)
    	{
    		if(key_value == 0x1A) //z
    		{
    			if(block_lef - 100 < 10)
    				block_lef = 100;
    			else
    				block_lef -= 10;
    		}
    		else if(key_value == 0x22) //x
    		{
    			if(block_lef + 2*block_len > 540 - 10)
    				block_lef = 540 - 2*block_len;
    			else
    				block_lef += 10;
    		}
    		move_flag = 0;
    		key_value_pre = key_value;
    	}
    	if(key_value == 0x29) //space
    	{
    		space_flag = 1;
    		XIOModule_DiscreteWrite(&gpo, 2, space_flag);
    	}
    	else
    		space_flag = 0;

    	block_para_after = (block_lef << 12) + block_len;
		XIOModule_DiscreteWrite(&gpo, 1, block_para_after);
    }

    cleanup_platform();
    return 0;
}
