module CPLD_3DO(
    
	 input b0_240,
	 input b1_240,
	 input b2_240,
	 input b3_240,
	 input b4_240,
	 input b0_480,
	 input b1_480,
	 input b2_480,
	 input b3_480,
	 input b4_480,
	 input       clk12,
    input       hsync,
    input       vsync,
    input       interlace_in,
    //encoder choice, BT9101=0 others=1
    input       encoder,
	 //encoder choice, BT9101PAL=0 others=1
	 input		 encoder_bt9103,
    output reg  interlace_out,
    output wire hsync_o,
	 output wire led,
    output wire vsync_o,
    output wire csync_o,
	 output wire hsync_o_VGA,
    output wire vsync_o_VGA
);
    reg vsync2 = 0;
    reg hsync2 = 0;  
	 reg hsync3 = 0;
    reg prev_vsync = 0;
    reg prev_hsync = 0;
    reg [9:0] h_count = 0;
    reg [9:0] new_h_count = 0;
    reg [9:0] h_total = 0;
    reg [7:0] h_low_count = 0;
    reg hsync_mod = 1'b1;
    reg [4:0] shift_value = 0;
    reg [11:0] CounterX = 0;
    reg [8:0] CounterY = 0;
	 reg [8:0] counterled = 0;
	 reg LED_status = 0;
	 reg var_b0_240;
	 reg var_b1_240;
	 reg var_b2_240;
	 reg var_b3_240;
	 reg var_b4_240;
	 reg var_b0_480;
	 reg var_b1_480;
	 reg var_b2_480;
	 reg var_b3_480;
	 reg var_b4_480;
	 reg interlace_startup=0;
	 reg startup_buf=0;
	 reg vsync_start=0;
	 
    localparam GENERATED_240P_WIDTH = 796;
    localparam GENERATED_240P_HEIGHT = 262;
    localparam GENERATED_240P_HEIGHT_PAL = 288;
    localparam HSYNC_SHIFT_240P_MOD = 5'b00000;
    localparam HSYNC_SHIFT_480I_MOD = 5'b11000;
	 localparam VSYNC_SHIFT_LENGTH = 10'b1001110001;
 	 localparam VSYNC_SHIFT_LENGTHBT = 12'b100101100000;

	 always @(negedge clk12) begin
		  
	 var_b0_240 <= !b0_240;
	 var_b1_240 <= !b1_240;
	 var_b2_240 <= !b2_240;
	 var_b3_240 <= !b3_240;
	 var_b4_240 <= !b4_240;
	 var_b0_480 <= !b0_480;
	 var_b1_480 <= !b1_480;
	 var_b2_480 <= !b2_480;
	 var_b3_480 <= !b3_480;
	 var_b4_480 <= !b4_480;
    prev_vsync <= vsync2;
    prev_hsync <= hsync2;

	 
	 
 	if(!startup_buf) begin
		interlace_startup<=interlace_in;
		startup_buf<=1;
	end 
	 
        // skip first frame before activating interlace_out
        if (prev_vsync != vsync2 && prev_hsync != hsync2 && !vsync2) begin
				interlace_out <= interlace_in;
         
				
				
				if(!encoder || !encoder_bt9103) begin
					shift_value <= interlace_in ? {var_b0_240, var_b1_240 , var_b2_240 , var_b3_240 , var_b4_240} : {var_b0_480 , var_b1_480 , var_b2_480 , var_b3_480 , var_b4_480};				
				end else begin
					shift_value <= interlace_startup ? {var_b0_240, var_b1_240 , var_b2_240 , var_b3_240 , var_b4_240} : {var_b0_480 , var_b1_480 , var_b2_480 , var_b3_480 , var_b4_480};			
				end
			
				
				counterled <= counterled + 1'b1;
				if (counterled > 119) begin
					LED_status <= !LED_status;
					counterled <= 7'b0;
				end
		  end

        // hysnc buffers and counters 
        if ((prev_hsync != hsync2) && !hsync2) begin
            h_count <= 0;
            new_h_count <= 0;
            h_total <= h_count - shift_value;  // make hsync trigger earlier
        end else begin
            h_count <= h_count + 1'b1;
            new_h_count <= new_h_count + 1'b1; 
        end

        // generate hsync for csync output
        if (new_h_count == h_total) begin
            hsync_mod <= 0;
            h_low_count <= 0;
        end else begin
            if (h_low_count == 6'b111100) begin  // make hsync low pulse longer
					 hsync_mod <= 1'b1;
            end else begin
                h_low_count <= h_low_count+1;  
            end
        end

        
		  // BT9101 Encoder 240p - generate timings
       

        if ((!encoder || !encoder_bt9103) && interlace_in) begin
						
				
				  	// BT9101 MODE - Output 240P signal, ignore syncs from DAC
						if (CounterX < GENERATED_240P_WIDTH - 1) begin
								CounterX <= CounterX + 1;
						end else begin
								CounterX <= 0;
								if (CounterY < (encoder_bt9103 ?	GENERATED_240P_HEIGHT : GENERATED_240P_HEIGHT_PAL) - 1) begin
									CounterY <= CounterY + 1;
								end else begin
									CounterY <= 0;
								end
						end
						
					
						
						vsync2 <= ~(CounterY <= 3);
						hsync2 <= ~(CounterX[9:6] == 0);
						hsync3 <= hsync_mod;
				
						  
		  end else begin
					
					if(!vsync && !vsync_start) begin
					 CounterX <= 0;
					 vsync2 <= 0;
					 vsync_start<=1;
					end else if(CounterX < VSYNC_SHIFT_LENGTHBT)begin
						CounterX <= CounterX + 1;
					end else begin
						vsync_start <= 0;
						vsync2 <= 1;
					end
				
			
			
					hsync2 <= hsync;
					//pass shifted_hsync for VGA output
					hsync3 <= hsync_mod;	
		  end
    end
	 
	 
	 assign led=LED_status;
	 assign hsync_o_VGA = hsync3;
    assign vsync_o_VGA = vsync2;    
	 assign hsync_o = hsync3;
    assign vsync_o = vsync2;    
    assign csync_o = (hsync_mod ^ vsync2) ^ 1;
 endmodule