`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/02 20:30:33
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_ball(clk_in,reset, hsync, vsync, RGB_out, sw, led, button, micdata, mic_clk, mic_rl, rx,tx );
    input clk_in, reset, rx;
    input [1:0] sw;
    input button;
    output [1:0] led;
    output tx;
    // micphone interface
    input micdata;
    output mic_clk;
    output mic_rl;
    // vga interface
    output hsync, vsync;
    output reg [11:0] RGB_out;
    
    reg [3:0] R,G,B;
    wire clk_25M, blank;
    wire [10:0] hct, vct;
    reg [19:0] count_60 = 833334, count_3M = 17;
    reg clk_60, clk_3M;
    reg [11:0] goat_btm, goat_lef, land_len;
    reg [11:0] land_lef1, land_lef2,land_lef3,land_lef4;
    reg [11:0] fall_len1,fall_len2,fall_len3,fall_len4; 
    reg [1:0] current_state,next_state;
    reg [7:0] dy,goat_blck,press;
    reg jump_flag,die;
    wire [10:0] addr_goat;
    reg [10:0] addr_goat_buf;
    wire [23:0] dat_goat;
    wire [3:0] jump;
    
    initial begin
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                goat_lef <=180;
        land_lef1 <= 12'd0;
        land_lef2 <= 12'd150;
        land_lef3 <= 12'd320;
        land_lef4 <= 12'd520;
        land_len <= 12'd80;
        fall_len1 <= 12'd70;
        fall_len2 <= 12'd90;
        fall_len3 <= 12'd120;
        dy <= 0;
        die <=0;
        jump_flag <= 0;
    end
    parameter   IDLE = 2'b00;
    parameter   PLAY = 2'b01;
    parameter   OVER = 2'b10;
    // call MMCM model
    clk_wiz_0 inst_MMCM(
        // Clock out ports
        .clk_25(clk_25M),     // output clk_25M
        // Clock in ports
        .clk_in1(clk_in));      // input clk_in1
      
    //call VGA model
    vga_controller_640_60 inst_vga(
           .rst(reset),
           .pixel_clk(clk_25M),
           .HS(hsync),
           .VS(vsync),
           .hcount(hct),
           .vcount(vct),
           .blank(blank));
           
           // rom load goat picture 20*30
           blk_mem_gen_0 inst_rom (
             .clka(clk_25M),    // input wire clka
             .addra(addr_goat),  // input wire [9 : 0] addra
             .douta(dat_goat)  // output wire [23 : 0] douta
           );
           
     // micblaze
     microblaze_mcs_0 your_instance_name (
       .Clk(clk_in),                  // input wire Clk
       .Reset(reset),              // input wire Reset
       .UART_rxd(rx),        // input wire UART_rxd
       .UART_txd(tx),        // output wire UART_txd
       .GPIO1_tri_i(micdata),  // input wire [15 : 0] GPIO1_tri_i
       .GPIO1_tri_o(jump)  // output wire [3 : 0] GPIO1_tri_o
     );
     assign mic_lr = 0;
    //generate 60Hz
    always @ (posedge clk_in) begin
        if(count_60 >= 20'd833334) begin
            count_60 = 0;
            clk_60 <= ~clk_60;
        end
        else begin
            count_60 = count_60 + 1;
        end
    end 
    
    // generate 2MHz
        always @ (posedge clk_in) begin
        if(count_3M >= 20'd17) begin
            count_3M = 0;
            clk_3M <= ~clk_3M;
        end
        else begin
            count_3M = count_3M + 1;
        end
    end 
    
    assign mic_clk = clk_3M;
    assign led = current_state;
    
    // state machine
    always @ (clk_60)begin
        if (reset == 1'b1)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end
    
    always @ (*) begin
        case(current_state)
        IDLE:
            if (sw == 2'b01)begin
                next_state <= PLAY;
            end
            else 
                next_state <= IDLE;
        PLAY:
            if (sw == 2'b10 || die == 1)begin
                next_state <= OVER;
            end
            else begin
                next_state <= PLAY;
            end
        OVER:
            if(sw == 2'b11) begin
                next_state <= IDLE; 
                end
            else
                next_state <= OVER;
    endcase  
    end
// in this part, system would judge whether the goat falls into trap. And how does the goat jump
    always @(posedge clk_60) begin
        if (current_state == IDLE) begin
            die <= 0;
         end
        else if (current_state == PLAY)begin
            if(land_lef1 > 0)
                land_lef1 <= land_lef1 -1;
            else 
                land_lef1 <= 640;
            if(land_lef2 > 0)
                land_lef2 <= land_lef2 -1;
            else
                land_lef2 <= 640;
            if(land_lef3 > 0)
                land_lef3 <= land_lef3 -1;
            else
                land_lef3 <= 640;
            if(land_lef4 > 0)
                land_lef4 <= land_lef4 -1;
            else
                land_lef4 <= 640;
            
            if(jump == 1) begin
                jump_flag <= 1;
                dy <= 5;
                goat_blck <= 0;
                press <= 1;
            end
            else begin
                    jump_flag <= 1;
                    dy <= 5;
                    goat_blck <= 0;
                    press <=0;
            end
            if(jump_flag == 1) begin
                if(goat_blck ==0 && press==1 ) begin
                    goat_btm <= goat_btm -dy;
                end
                if (press == 0)begin
                    goat_blck <=1;
                end
                if ( goat_blck == 1|| (goat_btm-20) < 0 ) begin
                    goat_btm <= goat_btm +dy;
                end
                if (goat_btm > 400)begin
                    if ((goat_lef > land_lef1 && goat_lef < (land_lef1+ land_len))||(goat_lef > land_lef2 && goat_lef < (land_lef2+ land_len)) || (goat_lef > land_lef3 && goat_lef < (land_lef3+ land_len)) ||goat_lef > land_lef4 && goat_lef < (land_lef4+ land_len) ) begin
                        jump_flag <= 0;
                        goat_blck <= 0;
                        goat_btm <= 400; 
                    end
                    else begin
                            if( ((goat_lef +35)==land_lef1) || ((goat_lef +35)==land_lef2)|| ((goat_lef +35)==land_lef2)|| ((goat_lef +35)==land_lef2)|| goat_btm == 480)begin
                                die <= 1;
                                jump_flag = 1;
                            end
                      
                                goat_btm <= goat_btm +dy;
                                jump_flag =0;
                                goat_blck <=1;
                       
                     end
                end
                end         
                else begin
                goat_btm <= 400;
               end
           end
    end
    
 assign addr_goat = addr_goat_buf;
    
    
 // draw land and goat
    always @ (posedge clk_25M) begin
        if ( vct < goat_btm && vct > (goat_btm - 25) && hct < (goat_lef+ 35) && hct > goat_lef) begin
           addr_goat_buf <= (vct -(goat_btm-20)-1)*30 + hct -goat_lef-1+3;
            R <= dat_goat[23:20];
            G <= dat_goat[15:12];
            B <= dat_goat[7:4];
        end
        else if ( vct > 400 && vct<480 && hct < (land_lef1+land_len) && hct > land_lef1) begin
            R <= 4'h0;
            G <= 4'hf;
            B <= 4'hf;
        end
        else if (vct > 400 && vct<480 && hct < (land_lef2+land_len) && hct > land_lef2) begin
            R <= 4'h0;
            G <= 4'hf;
            B <= 4'hf;       
        end
        else if (vct > 400 && vct<480 && hct < (land_lef3+land_len) && hct > land_lef3) begin
             R <= 4'h0;
             G <= 4'hf;
             B <= 4'hf;       
        end
        else if (vct > 400 && vct<480 && hct < (land_lef4+land_len) && hct > land_lef4) begin
             R <= 4'h0;
             G <= 4'hf;
             B <= 4'hf;      
        end
        else if(vct > 0 && vct<480 && hct < 150 && hct > 0) begin
             R <= 4'h0;
             G <= 4'hf;
             B <= 4'hf;  
        end
        else begin
            R <= 4'h0;
            G <= 4'h0;
            B <= 4'h0;
        end
        RGB_out = {R, G, B};
    end
           
endmodule

