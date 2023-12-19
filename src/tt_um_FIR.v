`default_nettype none

module tt_um_FIR #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
 
    wire reset = rst_n; // needed for FIR Filter
    
    
    
    wire [6:0] led_out;
    assign uo_out[6:0] = led_out;
    assign uo_out[7] = 1'b0;

    // use bidirectionals as outputs
    assign uio_oe = 8'b11111111;

    // put bottom 8 bits of second counter out on the bidirectional gpio
    assign uio_out = second_counter[7:0];

    // external clock is 10MHz, so need 24 bit counter
    reg [23:0] second_counter;
    reg [3:0] digit;

    // if external inputs are set then use that as compare count
    // otherwise use the hard coded MAX_COUNT
    wire [23:0] compare = ui_in == 0 ? MAX_COUNT: {6'b0, ui_in[7:0], 10'b0};

    always @(posedge clk) begin
        // if reset, set counter to 0
        if (reset) begin
            second_counter <= 0;
            digit <= 0;
        end else begin
            // if up to 16e6
            if (second_counter == compare) begin
                // reset
                second_counter <= 0;

                // increment digit
                digit <= digit + 1'b1;

                // only count from 0 to 9
                if (digit == 9)
                    digit <= 0;

            end else
                // increment counter
                second_counter <= second_counter + 1'b1;
        end
    end


    // instantiate segment display
    // seg7 seg7(.counter(digit), .segments(led_out));
    
    
    wire [7:0] m_axis_fir_tdata; //FIR OUTPUT DATA
    assign uio_out = m_axis_fir_tdata;
   
    
    wire [5:0] s_axis_fir_tdata; //FIR INPUT DATA 
    assign s_axis_fir_tdata = ui_in[5:0]; //First 6 Bit are used
    
    wire s_axis_fir_tvalid;
    assign s_axis_fir_tvalid = ui_in[6];
    
    wire s_axis_fir_tready;
    assign s_axis_fir_tready = ui_in[7];
    
    
    
    /* Instantiate FIR module to test. */
    
    FIR FIR_i(
        .clk(clk),
        .reset(reset),
        .s_axis_fir_tdata(s_axis_fir_tdata),       
        .s_axis_fir_tvalid(s_axis_fir_tvalid), 
        .s_axis_fir_tready(s_axis_fir_tready),    
        .m_axis_fir_tdata(m_axis_fir_tdata));  
        

endmodule
