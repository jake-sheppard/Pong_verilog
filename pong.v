`timescale 1ns / 1ps
module pong(MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS, // Disable the three memory chips
	ClkPort, 		// 100 MHz
	vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b,  // VGA signals
	btnU, btnD, btnL, btnC, btnR,
	An0, An1, An2, An3, 
	Ca, Cb, Cc, Cd, Ce, Cf, Cg, 
	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7,
	JA0, JA1, JA2, JA3);
	
	
	output 	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS;
	input ClkPort, btnU, btnD, btnL, btnR, btnC;
	input JA0, JA1, JA2, JA3;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg;
	output Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	reg vga_r, vga_g, vga_b;
	
	 
	// Disable the three memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS} = 5'b11111;
	
	
	/*  LOCAL SIGNALS */
	wire	reset, ClkPort, board_clk, clk, ack;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, btnC);
	BUF BUF3 (ack, btnR);
	BUF BUF4	(start, btnL);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	clk = DIV_CLK[1];
	assign	sm_clk = DIV_CLK[20]; 
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;
	
	//////////////////
	
	wire [9:0] x;
	wire [9:0] y;
	wire [9:0] text_offset;
	reg [9:0] p_1;
	reg [9:0] p_2;
	wire [3:0] player_1_score;
	wire [3:0] player_2_score;
	
	//////////////////

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	pong_sm psm(.clk(sm_clk), .reset(reset), .start(start), .ack(ack), .x(x), .y(y),.text_offset(text_offset), .player_1_score(player_1_score), .player_2_score(player_2_score), .p_1(p_1), .p_2(p_2), .q_INITIAL(q_INITIAL), .q_SERVE(q_SERVE), .q_MOVE(q_MOVE), .q_CHECK(q_CHECK), .q_SCORE(q_SCORE), .q_GAMEOVER(q_GAMEOVER));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;
	
	
	always @(posedge DIV_CLK[19])
		begin
			if(reset || ack)
			begin
				p_1 <= 240;
				p_2 <= 240;
			end
			else if( (JA3 | JA1) && ~(JA2 && JA0) && (p_1 > 40) )
				begin
					p_1 <= p_1 - 5;
				end
			else if( (JA2 | JA0) && ~(JA3 && JA1) && (p_1 < 440))
				begin
					p_1 <= p_1 + 5;
				end
			else if(btnU && ~btnD && (p_2 > 40))
				begin
					p_2 <= p_2 - 5;
				end
			else if(btnD && ~btnU && (p_2 < 440))
				begin
					p_2 <= p_2 + 5;
				end
		end

	wire ball = ( (CounterX>=x-3) && (CounterX<=x+3) && (CounterY>=y-1) && (CounterY<=y+1) ) || ( (CounterX>=x-2) && (CounterX<=x+2) && ( (CounterY==y-2) || (CounterY==y+2) ))  || ( (CounterX>=x-1) && (CounterX<=x+1) && ((CounterY==y-3) || (CounterY==y+3)));
	
	wire left_paddle = ( ( CounterX>=0 ) && ( CounterX<=15 ) && ( CounterY<=(p_1+40) ) && ( CounterY>=(p_1-40) ) ) ;
	
	wire right_paddle = ( ( CounterX>625 ) && ( CounterX<=640 ) && ( CounterY<=(p_2+40) ) && ( CounterY>=(p_2-40) ) ) ;
	
	wire w = ( ( (CounterX >= (40+text_offset)) && (CounterX < (50+text_offset)) ) && ( (CounterY >= 40) && (CounterY < 80) ) || ( (CounterX >= (50+text_offset)) && (CounterX < (60+text_offset)) ) && ( (CounterY >= 80) && (CounterY < 90) )
				|| ( ((CounterX >= (60+text_offset)) && (CounterX < (70+text_offset))) && ( (CounterY >= 63) && (CounterY < 80) )  || ( (CounterX >= (70+text_offset)) && (CounterX < (80+text_offset) ) && ( (CounterY >= 80) && (CounterY < 90) )
				|| ( (CounterX >= (80+text_offset)) && (CounterX < (90+text_offset)) ) && ( (CounterY >= 40) && (CounterY < 80) ) )));
	wire l = ( (( (CounterX >= (570-text_offset)) && (CounterX < (580-text_offset)) )) && ( (CounterY >= 40) && (CounterY < 90)) ) || (( (CounterX >= (580-text_offset)) && (CounterX < (600-text_offset)) ) && ( (CounterY >= 80) && (CounterY < 90)));
	
	always @(posedge clk)
	begin
		vga_r <= ( ball | left_paddle | (l & q_GAMEOVER)) & inDisplayArea;
		vga_g <= (ball | (CounterX >= 319 && CounterX <= 321 && (CounterY % 10)) | (w & q_GAMEOVER))  & inDisplayArea;
		vga_b <= ( right_paddle | (CounterX >= 319 && CounterX <= 321 && (CounterY % 10)) ) & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	

	assign {Ld7, Ld6, Ld5, Ld4} = {0, 0, q_GAMEOVER, q_SCORE}; 
	assign {Ld3, Ld2, Ld1, Ld0} = {q_CHECK, q_MOVE, q_SERVE, q_INITIAL}; 
	
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = player_1_score[3:0];
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = player_2_score[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	
	
	reg [6:0]  SSD_CATHODES;
	wire [6:0] 		SSD_CATHODES_blinking;	

	assign SSD_CATHODES_blinking = SSD_CATHODES | ( {7{ q_GAMEOVER & DIV_CLK[25]}} );
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = SSD_CATHODES_blinking;

	// and finally convert SSD_num to ssd
	//reg [6:0]  SSD_CATHODES;
	//assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
