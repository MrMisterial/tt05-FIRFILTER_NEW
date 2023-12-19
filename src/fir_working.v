`timescale 1ns / 1ps

module FIR(
    input clk,
    input reset,
    input signed [15:0] s_axis_fir_tdata, 
    input [3:0] s_axis_fir_tkeep,
    input s_axis_fir_tlast,
    input s_axis_fir_tvalid,
    input m_axis_fir_tready,
    output reg m_axis_fir_tvalid,
    output reg s_axis_fir_tready,
    output reg m_axis_fir_tlast,
    output reg [3:0] m_axis_fir_tkeep,
    output reg signed [31:0] m_axis_fir_tdata
    );


    always @ (posedge clk)
        begin
            m_axis_fir_tkeep <= 4'hf;
        end
        
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
    
    // 15-tap FIR 
    reg enable_fir, enable_buff;
    reg [3:0] buff_cnt;
    reg signed [15:0] in_sample; 
    reg signed [15:0] buff0, buff1, buff2, buff3; 
    wire signed [15:0] tap0, tap1, tap2, tap3; 
    reg signed [31:0] acc0, acc1, acc2, acc3; 

    
    /* Taps for LPF running @ 1MSps with a cutoff freq of 400kHz*/
    assign tap0 = 16'hFC9C;  // twos(-0.0265 * 32768) = 0xFC9C
    assign tap1 = 16'h0000;  // 0
    assign tap2 = 16'h05A5;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
    assign tap3 = 16'h0000;  // 0
    
    /* This loop sets the tvalid flag on the output of the FIR high once 
     * the circular buffer has been filled with input samples for the 
     * first time after a reset condition. */
    always @ (posedge clk or negedge reset)
        begin
            if (reset == 1'b0) //if (reset == 1'b0 || tvalid_in == 1'b0)
                begin
                    buff_cnt <= 4'd0;
                    enable_fir <= 1'b0;
                    in_sample <= 8'd0;
                end
            else if (m_axis_fir_tready == 1'b0 || s_axis_fir_tvalid == 1'b0)
                begin
                    enable_fir <= 1'b0;
                    buff_cnt <= 4'd15;
                    in_sample <= in_sample;
                end
            else if (buff_cnt == 4'd15)
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
            if(reset == 1'b0 || m_axis_fir_tready == 1'b0 || s_axis_fir_tvalid == 1'b0)
                begin
                    s_axis_fir_tready <= 1'b0;
                    m_axis_fir_tvalid <= 1'b0;
                    enable_buff <= 1'b0;
                end
            else
                begin
                    s_axis_fir_tready <= 1'b1;
                    m_axis_fir_tvalid <= 1'b1;
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
                   
                end
            else
                begin
                    buff0 <= buff0;
                    buff1 <= buff1;        
                    buff2 <= buff2;         
                    buff3 <= buff3;      
                    
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
                end
        end    
        
     /* Accumulate stage of FIR */   
    always @ (posedge clk) 
        begin
            if (enable_fir == 1'b1)
                begin
                    m_axis_fir_tdata <= acc0 + acc1 + acc2 + acc3;
                end
        end     

    
    
endmodule

