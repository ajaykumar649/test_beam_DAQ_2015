
`timescale 1 ns / 1 ps

	module data_generator_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		input clkSys,
        output SIG_OUT_1_N, SIG_OUT_1_P,
        output SIG_OUT_2_N, SIG_OUT_2_P,
        output SIG_OUT_3_N, SIG_OUT_3_P,
        output SIG_OUT_4_N, SIG_OUT_4_P,
        output CLK_OUT_N, CLK_OUT_P,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
    reg[7:0] data_1, data_2, data_3, data_4;
    reg k_1,k_2,k_3,k_4,idle_1,idle_2,idle_3,idle_4;
    wire CLK_OUT_1,CLK_OUT_2,CLK_OUT_3;
    reg[15:0] count_1, count_2;
    reg [2:0] state;
    reg [2:0] idle = 3'b000;
    reg [2:0] start = 3'b001;
    reg [2:0] active_1 = 3'b010;
    reg [2:0] rest = 3'b011;
    reg [2:0] active_2 = 3'b100;
    reg [2:0] done = 3'b101;
    reg [3:0] rest_count;
    
    OBUFDS #(.IOSTANDARD("LVDS_25")) buf_clk_out (.O(CLK_OUT_P),.OB(CLK_OUT_N),.I(CLK_OUT));
    
    OBUFDS #(.IOSTANDARD("LVDS_25")) buf_sig_out_1 (.O(SIG_OUT_P_1),.OB(SIG_OUT_N_1),.I(SIG_OUT_1));
    OBUFDS #(.IOSTANDARD("LVDS_25")) buf_sig_out_2 (.O(SIG_OUT_P_2),.OB(SIG_OUT_N_2),.I(SIG_OUT_2));
    OBUFDS #(.IOSTANDARD("LVDS_25")) buf_sig_out_3 (.O(SIG_OUT_P_3),.OB(SIG_OUT_N_3),.I(SIG_OUT_3));
    OBUFDS #(.IOSTANDARD("LVDS_25")) buf_sig_out_4 (.O(SIG_OUT_P_4),.OB(SIG_OUT_N_4),.I(SIG_OUT_4));
    
    always @(posedge byte_clk) begin
        if ((state==idle)&&slv_reg1[0]==1) state<=start;
        else if(state==start) state<=active_1;
        else if((state==active_1)&&(count_1==4000)) state<=rest;
        else if((state==rest)&&(rest_count==4'b1111)) state<=active_2;
        else if((state==active_2)&&(count_1==6000)) state<=done;
        else if((state==done)&&slv_reg1[0]==0) state<=idle;
        else state<=state;
        end
            
    always @(posedge byte_clk) begin
        if((state==idle)||(state==rest)) begin
            idle_1<=1;
            idle_2<=1;
            idle_3<=1;
            idle_4<=1;
            end
        else if(state==start) begin
            idle_1<=0;
            idle_2<=1;
            idle_3<=1;
            idle_4<=1;
            end
        else if(count_1==5000) begin
            idle_1<=1;
            idle_2<=0;
            idle_3<=0;
            idle_4<=0;
            end
        else begin
            idle_1<=0;
            idle_2<=0;
            idle_3<=0;
            idle_4<=0;
            end
        end
    
    always @(posedge byte_clk) begin
        if ((state==idle)||(state==done)||(state==start)) begin
            count_1<=0;
            count_2<=0;
            end
        else if (state==rest) begin
            count_1<=count_1;
            count_2<=count_2;
            end
        else begin
            count_1<=count_1+1;
            count_2<=count_2+1;
            end
        end
        
    always @(posedge byte_clk) begin
        if (state==rest) rest_count<=rest_count+1;
        else rest_count<=0;
        end
    
    always @(posedge byte_clk) begin
        if ((state==active_1)||(state==start)) begin
            data_1 <= count_1[7:0]+1;
            data_2 <= count_1[15:8];
            data_3 <= count_2[7:0];
            data_4 <= count_2[15:8];
            end
        else begin
            data_1 <= count_1[7:0];
            data_2 <= count_1[15:8];
            data_3 <= count_2[7:0];
            data_4 <= count_2[15:8];
            end
        end
    
    encode_function encoder_1(.byteIn(data_1),.isK(k_1),.bitclk(bit_clk), .idle(idle_1),
                               .sigOut(SIG_OUT_1),.clkOut(CLK_OUT),.byte_clk(byte_clk));
    encode_function encoder_2(.byteIn(data_2),.isK(k_2),.bitclk(bit_clk), .idle(idle_2),
                               .sigOut(SIG_OUT_2),.clkOut(CLK_OUT_1),.byte_clk(byte_clk));
    encode_function encoder_3(.byteIn(data_3),.isK(k_3),.bitclk(bit_clk), .idle(idle_3),
                               .sigOut(SIG_OUT_3),.clkOut(CLK_OUT_2),.byte_clk(byte_clk));
    encode_function encoder_4(.byteIn(data_4),.isK(k_4),.bitclk(bit_clk), .idle(idle_4),
                               .sigOut(SIG_OUT_4),.clkOut(CLK_OUT_3),.byte_clk(byte_clk));                               

wire pll_clk, bit_clk_lcl, byte_clk_lcl;

       PLLE2_BASE #(
          .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
          .CLKFBOUT_MULT(25),        // Multiply value for all CLKOUT, (2-64)
          .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
          .CLKIN1_PERIOD(0.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
          // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
          .CLKOUT0_DIVIDE(10),
          .CLKOUT1_DIVIDE(100),
          .CLKOUT2_DIVIDE(1),
          .CLKOUT3_DIVIDE(1),
          .CLKOUT4_DIVIDE(1),
          .CLKOUT5_DIVIDE(1),
          // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
          .CLKOUT0_DUTY_CYCLE(0.5),
          .CLKOUT1_DUTY_CYCLE(0.5),
          .CLKOUT2_DUTY_CYCLE(0.5),
          .CLKOUT3_DUTY_CYCLE(0.5),
          .CLKOUT4_DUTY_CYCLE(0.5),
          .CLKOUT5_DUTY_CYCLE(0.5),
          // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
          .CLKOUT0_PHASE(0.0),
          .CLKOUT1_PHASE(0.0),
          .CLKOUT2_PHASE(0.0),
          .CLKOUT3_PHASE(0.0),
          .CLKOUT4_PHASE(0.0),
          .CLKOUT5_PHASE(0.0),
          .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
          .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
          .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
       )
       PLLE2_BASE_inst (
          // Clock Outputs: 1-bit (each) output: User configurable clock outputs
          .CLKOUT0(bit_clk_lcl),   // 1-bit output: CLKOUT0
          .CLKOUT1(byte_clk_lcl),   // 1-bit output: CLKOUT1
    //      .CLKOUT2(CLKOUT2),   // 1-bit output: CLKOUT2
    //      .CLKOUT3(CLKOUT3),   // 1-bit output: CLKOUT3
    //      .CLKOUT4(CLKOUT4),   // 1-bit output: CLKOUT4
    //      .CLKOUT4(CLKOUT4),   // 1-bit output: CLKOUT4
    //      .CLKOUT5(CLKOUT5),   // 1-bit output: CLKOUT5
          // Feedback Clocks: 1-bit (each) output: Clock feedback ports
          .CLKFBOUT(pll_clk), // 1-bit output: Feedback clock
    //      .LOCKED(LOCKED),     // 1-bit output: LOCK
          .CLKIN1(clkSys),     // 1-bit input: Input clock
          // Control Ports: 1-bit (each) input: PLL control ports
          .PWRDWN(1'h0),     // 1-bit input: Power-down
          .RST(1'h0),           // 1-bit input: Reset
          // Feedback Clocks: 1-bit (each) input: Clock feedback ports
          .CLKFBIN(pll_clk)    // 1-bit input: Feedback clock
       );

    BUFG bufr_inst_byte(.O(byte_clk), .I(byte_clk_lcl));
    BUFG bufr_inst_bit(.O(bit_clk), .I(bit_clk_lcl));

	// User logic ends

	endmodule