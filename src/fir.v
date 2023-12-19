`timescale 1ns / 1ps

module FIR(
    input clk,
    input reset,
    input signed [5:0] s_axis_fir_tdata, 
    input s_axis_fir_tvalid,
    output reg s_axis_fir_tready,
    output reg signed [7:0] m_axis_fir_tdata
    );

/*
    always @ (posedge clk)
        begin
            m_axis_fir_tkeep <= 4'hf;
        end
*/
/*
    always @ (posedge clk)
        begin
            if (s_axis_fir_tlast == 1'b1)
                begin
                    m_axis_fir_tlast <= 1'b1;
                end
            else
                begin
                    m_axis_fir_tlast <= 1'b0;
                end
        end
  */  
    // 15-tap FIR 
    reg enable_fir, enable_buff;
    reg [3:0] buff_cnt;
    reg signed [5:0] in_sample; 
    reg signed [5:0] buff0, buff1, buff2, buff3, buff4, buff5, buff6, buff7; 
    wire signed [1:0] tap0, tap1, tap2, tap3, tap4, tap5, tap6, tap7; 
    reg signed [7:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7; 

    
    /* Taps for LPF running @ 1MSps with a cutoff freq of 400kHz*/
    assign tap0 = 2'b01;//16'hFC9C;  // twos(-0.0265 * 32768) = 0xFC9C
    assign tap1 = 2'b00;//16'h0000;  // 0
    assign tap2 = 2'b01;//16'h05A5;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
    assign tap3 = 2'b00;//16'h0000;  // 0
    assign tap4 = 2'b01;//16'h0000;  // 0
    assign tap5 = 2'b00;//16'h0000;  // 0
    assign tap6 = 2'b01;//16'h0000;  // 0
    assign tap7 = 2'b00;//16'h0000;  // 0

    
    /* This loop sets the tvalid flag on the output of the FIR high once 
     * the circular buffer has been filled with input samples for the 
     * first time after a reset condition. */
    always @ (posedge clk or negedge reset)
        begin
            if (reset == 1'b0) //if (reset == 1'b0 || tvalid_in == 1'b0)
                begin
                    buff_cnt <= 4'd0;
                    enable_fir <= 1'b0;
                    in_sample <= 6'd0;
                end
            else if (s_axis_fir_tvalid == 1'b0)
                begin
                    enable_fir <= 1'b0;
                    buff_cnt <= 4'd15;
                    in_sample <= in_sample;
                end
            else if (buff_cnt == 4'd4) //changed to 4
                begin
                    buff_cnt <= 4'd0;
                    enable_fir <= 1'b1;
                    in_sample <= s_axis_fir_tdata;
                end
            else
                begin
                    buff_cnt <= buff_cnt + 1;
                    in_sample <= s_axis_fir_tdata;
                end
        end   

    always @ (posedge clk)
        begin
            if(reset == 1'b0 || s_axis_fir_tvalid == 1'b0)
                begin
                    s_axis_fir_tready <= 1'b0;
                    enable_buff <= 1'b0;
                end
            else
                begin
                    s_axis_fir_tready <= 1'b1;
                    enable_buff <= 1'b1;
                end
        end
    
    /* Circular buffer bring in a serial input sample stream that 
     * creates an array of 15 input samples for the 15 taps of the filter. */
    always @ (posedge clk)
        begin
            if(enable_buff == 1'b1)
                begin
                    buff0 <= in_sample;
                    buff1 <= buff0;        
                    buff2 <= buff1;         
                    buff3 <= buff2;   
                    buff4 <= buff3; 
                    buff5 <= buff4; 
                    buff6 <= buff5; 
                    buff7 <= buff6;    
                   
                end
            else
                begin
                    buff0 <= buff0;
                    buff1 <= buff1;        
                    buff2 <= buff2;         
                    buff3 <= buff3; 
                    buff4 <= buff4;
                    buff5 <= buff5;
                    buff6 <= buff6;
                    buff7 <= buff7;     
                    
                end
        end
        
    /* Multiply stage of FIR */
    always @ (posedge clk)
        begin
            if (enable_fir == 1'b1)
                begin
                    acc0 <= tap0 * buff0;
                    acc1 <= tap1 * buff1;
                    acc2 <= tap2 * buff2;
                    acc3 <= tap3 * buff3;
                    acc4 <= tap4 * buff4;
                    acc5 <= tap5 * buff5;
                    acc6 <= tap6 * buff6;
                    acc7 <= tap7 * buff7;
                end
        end    
        
     /* Accumulate stage of FIR */   
    always @ (posedge clk) 
        begin
            if (enable_fir == 1'b1)
                begin
                    m_axis_fir_tdata <= acc0 + acc1 + acc2 + acc3 + acc4 + acc5 + acc6 + acc7;
                end
        end     

    
    
endmodule

