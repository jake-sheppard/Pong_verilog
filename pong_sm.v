///////////////////////////////////////////////////////////////////////
///////		Author: 		Jake Sheppard								///////////
///////		Date: 			04/16/2017								///////////
///////		Description:	PONG State Machine					///////////
///////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module pong_sm (clk, reset, start, ack, x, y,text_offset, player_1_score, player_2_score, p_1, p_2, q_INITIAL, q_SERVE, q_MOVE, q_CHECK, q_SCORE, q_GAMEOVER);

	//Inputs
	input clk, reset, start, ack;
	input [9:0] p_1;
	input [9:0] p_2;
	
	//Outputs
	
	output reg [9:0] x;
	output reg [9:0] y;
	output reg [3:0] player_1_score; 
	output reg [3:0] player_2_score; 
	output reg [9:0] text_offset;
	
	
	output q_INITIAL, q_SERVE, q_MOVE, q_CHECK, q_SCORE, q_GAMEOVER;
	reg [5:0] state;
	assign {q_GAMEOVER, q_SCORE, q_CHECK, q_MOVE, q_SERVE, q_INITIAL} = state;
	

	reg dx, dy;
	wire b1, b2, b3, b4, b5;
	wire s1, s2, s3, s4;
	
	reg [9:0] X_step;
	reg [9:0] Y_step;
	
	localparam
	//paddle size
	PWIDTH = 10'd15,
	PHEIGHT = 10'd40,
	
	//state assignment
	INITIAL = 6'b000001,
	SERVE = 6'b000010,
	MOVE	= 6'b000100,
	CHECK	= 6'b001000,
	SCORE		= 6'b010000,
	GAMEOVER	= 6'b100000;

	
	// bounce back conditions
	assign b1 = ( (x + X_step) >= (10'd640 - PWIDTH) ) &&  ( (y + Y_step) <= (p_2 + PHEIGHT) )  && ( ( (y + Y_step) >= (p_2 - PHEIGHT) ) ) ; // Ball traveling right
	assign b2 = ( (x - X_step) <= PWIDTH ) &&  ( (y + Y_step) <= (p_1 + PHEIGHT) )  && ( ( (y + Y_step) >= (p_1 - PHEIGHT) ) ) ; // Ball traveling left
	assign b3 = ( ( (y - Y_step) <= 0 ) || ( (y + Y_step) >= 10'd480 ) ) ; // Top and bottom walls
	
	// scoring conditions
	assign s1 = ( (x + X_step) >= (10'd640) ) && ~( ( (y + Y_step) <= (p_2 + PHEIGHT) )  && ( ( (y + Y_step) >= (p_2 - PHEIGHT) ) ) ) ; // player 1 scores
	assign s2 = ( (x - X_step) <= 0 ) &&  ~( ( (y + Y_step) <= (p_1 + PHEIGHT) )  && ( ( (y + Y_step) >= (p_1 - PHEIGHT) ) ) ); // player 2 scores
	
	
	//NSL AND SM
	always @ (posedge clk, posedge reset)
	begin: pong_SM
		if (reset)
		begin
			state <= INITIAL;
			player_1_score <= 1'bx;
			player_2_score <= 1'bx;
			x <= 10'dx; 
			y <= 10'dx; 
			dx <= 1'bx; 
			dy <= 1'bx; 
			X_step <= 10'dx;
			Y_step <= 10'dx;
			text_offset <= 10'dx;
		end
		else
			case (state)
				INITIAL:
				begin
					//NSL
					state <= SERVE;
					//RTL
					player_1_score <= 1'b0;
					player_2_score <= 1'b0;
					x <= 10'd320; //ball in the center
					y <= 10'd240; 
					dx <= 1; // ball goes right
					dy <= 0; // ball goes down
					X_step <= 10'd12;
					Y_step <= 10'd6;
					text_offset <= 10'd0;
				end
				SERVE:
				begin
					//NSL
					if ( ( player_1_score == 0 ) && (player_2_score == 0) )
						begin
							if (start)
								state <= MOVE;
						end
					else 
						state <= MOVE;
					//RTL
					x <= 10'd320; //ball in the center
					y <= 10'd240; 
				end
				MOVE:
				begin
					//NSL
					state <= CHECK;
					//RTL
					if (dx)
						x <= x + X_step;
					else
						x <= x - X_step;
					
					if (dy)
						y <= y - Y_step;
					else
						y <= y + Y_step;
				end
				CHECK:
				begin
					// NSL
					if ( s1 | s2  )
						state <= SCORE;
					else
						state <= MOVE;
						
					//RTL
					if ( (b1 & dx) ) // ball traveling right towards paddle 2
						begin
							dx <= ~dx;
							if ( (y + Y_step) < (p_2 - 10'd25) ) // top region of paddle
								begin
									Y_step <= 12;
									dy <= 1'b1;
								end
							else if ( ( (y + Y_step) < (p_2 - 10'd5) ) && ( (y + Y_step) >= (p_2 - 10'd25) ) ) // 2nd region
								begin
									Y_step <= 3;
									dy <= 1'b1;
								end
							else if ( ( (y + Y_step) >= (p_2 - 10'd5) ) && ( (y + Y_step) < (p_2 + 10'd5) ) ) // middle region
								Y_step <= 0;
							else if ( ( (y + Y_step) >= (p_2 + 10'd5) ) && ( (y + Y_step) < (p_2 + 10'd25) ) ) // 4th region
								begin
									Y_step <= 3;
									dy <= 1'b0;
								end
							else if ( (y + Y_step) >= (p_2 + 10'd25 ) ) // bottom region
								begin
									Y_step <= 12;
									dy <= 1'b0;
								end
						end
					else if ( (b2 & ~dx) ) // ball traveling left towards paddle 1
						begin
							dx <= ~dx;
							if ( (y + Y_step) < (p_1 - 10'd25) ) // top region of paddle
								begin
									Y_step <= 12;
									dy <= 1'b1;
								end
							else if ( ( (y + Y_step) < (p_1 - 10'd5) ) && ( (y + Y_step) >= (p_1 - 10'd25) ) ) // 2nd region
								begin
									Y_step <= 3;
									dy <= 1'b1;
								end
							else if ( ( (y + Y_step) >= (p_1 - 10'd5) ) && ( (y + Y_step) < (p_1 + 10'd5) ) ) // middle region
								Y_step <= 0;
							else if ( ( (y + Y_step) >= (p_1 + 10'd5) ) && ( (y + Y_step) < (p_1 + 10'd25) ) ) // 4th region
								begin
									Y_step <= 3;
									dy <= 1'b0;
								end
							else if ( (y + Y_step) >= (p_1 + 10'd25 ) ) // bottom region
								begin
									Y_step <= 12;
									dy <= 1'b0;
								end
						end
					else if ( b3 ) // top or bottom wall
						dy <= ~dy;
				end
				SCORE:
				begin
					//NSL
					if ( ( (player_1_score == 2'b10)& dx ) || ( (player_2_score == 2'b10)& ~dx ) )
						begin
						state <= GAMEOVER;
						if ((player_2_score == 2'b10) & ~dx)
							text_offset <= 10'd530;
						end
					else
						state <= SERVE;
					//RTL
					if ( dx )
						begin
							player_1_score <= player_1_score + 2'b01;
							dx <= ~dx;
						end
					else
						begin
							player_2_score <= player_2_score + 2'b01;
							dx <= ~dx;
						end
				end
				GAMEOVER:
				begin
					//NSL
					if (ack)
						state <= INITIAL;
						x <= 650; // make ball go out of screen
						y <= 500;
				end
			endcase
	end
endmodule