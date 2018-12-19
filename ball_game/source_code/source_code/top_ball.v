`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/11/30 14:57:25
// Design Name: 
// Module Name: top_ball
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


module top_ball(clk_in, hsync, vsync, RGB_out, rx, tx, reset, seg_o, seg_num_o, sw_color, PS2_CLK, PS2_DATA, led);
    input clk_in, rx, reset, PS2_CLK, PS2_DATA;
    input [3:0] sw_color;
    output hsync, vsync, tx;
    output wire [1:0]led;
    output reg [11:0] RGB_out;
    output reg [6:0] seg_o;
    output reg [7:0] seg_num_o;
    
    
    reg [3:0] R,G,B;
    wire clk_25M, blank;
    reg clk_60;
    wire [10:0] hct, vct;
    wire [7:0] seg_num_buf;
    wire [6:0] seg_buf;
    reg [15:0] xy_value;
    wire [31:0] kbd_value;
    reg [31:0] kbd_value_buf1, kbd_value_buf2;
    reg [4:0] state = 5'b00000;
    reg [7:0] key_value, key_value_bef;
    wire [23:0] block_para;
    wire [23:0] new_block_para;
    reg [7:0] addr;
    wire [23:0] dat;  
    reg [23:0] dat_buf;
    reg [4:0] count_rdm = 0;
    wire space_flag;
    reg [11:0] block_lef= 300;
    reg [11:0] block_half_len = 30;
    reg signed [12:0] ball_lef;
    reg signed [12:0] ball_btm;    
    reg signed [12:0] ball_lef_buf;
    reg signed [12:0] ball_btm_buf = 470;
    reg [8:0] ball_len = 10;
    reg signed [10:0] dx,dy;
    reg signed [10:0] dx_buf,dy_buf,dx_buf1,dy_buf1;
    reg [19:0] count_60 = 833334;
    reg space_en = 0;
    reg [1:0] current_state,next_state;
    reg state_bounce_x, state_bounce_y, state_catch, bottom_flag, buf_give, run_over, block_lock, upper_change;
    reg [11:0] play_left, play_right, play_upper, play_bottom;
    parameter  WAIT = 2'b00;
    parameter  RUN = 2'b01;
    parameter  GAME_OVER = 2'b10;
    initial play_left = 100;
    initial play_right = 540; 
    initial play_upper = 0; 
    initial play_bottom = 10;
//    initial block_lef = 300;
    initial ball_lef_buf = 20;
    initial ball_btm = 469;
    initial bottom_flag = 0;
    initial buf_give = 0;
    initial state_bounce_x = 0;
    initial state_bounce_y = 0;
    initial state_catch = 1;
    initial ball_lef = 20;
    initial run_over = 0;
    initial block_lock = 0;
    initial upper_change = 0;
    //ROM part
    blk_mem_gen_0 inst_rom (
      .clka(clk_25M),    // input wire clka
      .addra(addr),  // input wire [7 : 0] addra
      .douta(dat)  // output wire [23 : 0] douta
    );
    
    //call seg model
    seven_seg inst_seg(
          .clk(clk_25M),
          .sw(xy_value),
          .seg(seg_buf),
          .num_seg(seg_num_buf));
    
    //call mircoblaze
    microblaze_mcs_0 inst_mb (
      .Clk(clk_in),                  // input wire Clk
      .Reset(reset),              // input wire Reset
      .UART_rxd(rx),        // input wire UART_rxd
      .UART_txd(tx),        // output wire UART_txd
      .GPIO1_tri_i(kbd_value_buf1),  // input wire [31 : 0] GPIO1_tri_i
      .GPIO1_tri_o(new_block_para),  // output wire [23 : 0] GPIO1_tri_o
      .GPIO2_tri_i(block_para),  // input wire [23 : 0] GPIO2_tri_i
      .GPIO2_tri_o(space_flag)  // output wire [0 : 0] GPIO2_tri_o
    );
    
    
    //call keyboard model
    PS2Receiver inst_key(
        .clk(clk_in), 
        .kclk(PS2_CLK), 
        .kdata(PS2_DATA),
        .keycodeout(kbd_value));
    
    // call MMCM model
    clk_wiz_0 inst_MMCM(
        // Clock out ports
        .clk_25M(clk_25M),     // output clk_25M
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
    
    // draw the block and ball
    always @ (posedge clk_25M) begin
        dat_buf <= dat;
        
        if (((hct<play_left && hct>0) || (hct>play_right && hct<640)) && vct>=0 && vct <= 480)
        begin
            R <= 4'h4;
            G <= 4'h0;
            B <= 4'h0;
        end
        else if (vct >= 0 && vct <= play_upper && hct>=play_left && hct <= play_right)
        begin
            R <= 4'h4;
            G <= 4'h0;
            B <= 4'h0;
        end
        else if (hct > block_lef  && hct < (2*block_half_len + block_lef) && hct > block_lef && vct < 480 && vct > 470) begin
            R <= 4'hf;
            G <= 4'hf;
            B <= 4'hf;
            end
        else if (vct < ball_btm && vct > (ball_btm-ball_len) && hct < (ball_lef+ball_len) && hct > ball_lef)
            begin
                addr <= (vct -(ball_btm-ball_len)-1)*15 + hct -ball_lef-1+3;
                R <= dat_buf[7:4];
                G <= dat_buf[15:12];
                B <= dat_buf[23:20];
            end
        else begin
            R <= 4'h0;
            G <= 4'h0;
            B <= 4'h0;
            end
        RGB_out = {R, G, B};
    end 
    assign block_para = {block_lef, block_half_len};

    
    //receive the key value
    always @ (posedge clk_25M) begin
        kbd_value_buf2 <= kbd_value;
        kbd_value_buf1 <= kbd_value_buf2;
        key_value = kbd_value_buf1[7:0];
        key_value_bef = key_value;
        xy_value = {24'h000000, key_value};
        seg_o = seg_buf;
        seg_num_o = seg_num_buf;
        if(block_lock == 0)
            block_lef <= new_block_para[23:12];
        else
            block_lef <= block_lef;
    end
    

    //state machine
    always @ (posedge clk_60) begin
    if(reset == 1) begin
        current_state <= WAIT;
    end
    else
        current_state <= next_state;
    end
    
    
    always @ (posedge clk_in) begin
        space_en <= space_flag;
    end
    

    assign led = current_state;
    always @ (*) begin
        case(current_state)
        WAIT:
            if(space_en == 1) begin
                dx_buf <= dx;
                dy_buf <= dy;
                next_state = RUN;
            end
            else
                begin
                next_state = WAIT; 
                end
        RUN:
            if(state_catch == 0)
                next_state = GAME_OVER;
            else
                next_state = RUN;
        GAME_OVER:
            next_state = GAME_OVER;
        endcase
    end
    
    reg first_give = 0;
    // bounce the ball
    always @ (posedge clk_60) begin
        if (current_state == WAIT) begin
            bottom_flag <= 0;
            buf_give <= 0;
            state_bounce_x <= 0;
            state_bounce_y <= 0;
            state_catch <= 1;
            block_lock <= 0;
            ball_lef <= block_lef + block_half_len;
//            if(first_give == 0) begin
//                block_lef <= 300;
//                first_give = 1;
//                end
//            else
//                first_give = 1;
        end
        
        else if(current_state == RUN) begin
            if (buf_give == 0) begin
                dy_buf1 <= dy_buf;
                dx_buf1 <= dx_buf;
                buf_give <= 1;
            end
            else begin
                dy_buf1 <= dy_buf1;
                dx_buf1 <= dx_buf1;
            end
            
            if(ball_lef <= play_left) begin //left edge
                state_bounce_x <= 1;
            end
            else if((ball_lef+ball_len)>=play_right) begin // right edge
                state_bounce_x <= 0;
            end
            else begin  // otherwise stay
                state_bounce_x <= state_bounce_x;
            end
            
            if ((ball_btm-ball_len) <= play_upper) begin //upper edge
                state_bounce_y <= 0;
            end
            else if(ball_btm > 470) begin //down edge
                state_bounce_y <= 1;
                bottom_flag <= 1;
            end
            else begin  //otherwise stay
                state_bounce_y <= state_bounce_y;
            end
                
            if(state_bounce_x == 1) begin //left edge
                ball_lef <= ball_lef + dx_buf1; 
            end
            else begin                     //right edge
                ball_lef <= ball_lef - dx_buf1;
            end

            
            if (state_bounce_y == 0) begin //up edge
                ball_btm <= ball_btm + dy_buf1;
            end
            else begin //down edge
                if(bottom_flag == 1) begin
                    bottom_flag <= 0;
                    if (ball_lef >= block_lef && (ball_lef+ball_len)<=(2*block_half_len + block_lef)) begin
                        state_catch <= 1;
                        upper_change <= 1;
                        ball_btm <= ball_btm - dy_buf1;
                        end
                    else begin
                        state_catch <= 0;
                    end
                    if(upper_change == 1)
                    begin
                        play_upper <= play_upper + 10;
                        upper_change = 0;
                    end
                    else
                        play_upper <= play_upper;
                end
                
                else begin
                    if(state_catch == 0) begin
                        ball_btm <= ball_btm;
                    end
                    else if(state_catch == 1)
                        ball_btm <= ball_btm - dy_buf1;
                end
            end

        end
        
        
        else if(current_state == GAME_OVER) begin
            block_lock <= 1;
        end
    end

    
    //random start
    always @ (posedge clk_60) begin
        if(count_rdm == 5)
            count_rdm <= 0;
        else
            count_rdm <= count_rdm + 1;
        
        if(count_rdm == 0) begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
            end
        else if(count_rdm == 1) begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
            end
        else if(count_rdm == 2) begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
            end
        else if(count_rdm == 3) begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
            end
        else if(count_rdm == 4) begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
            end
        else begin
            dx = 10'b0000000001;
            dy = 10'b0000000001;
        end
    end
endmodule
