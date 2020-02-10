`define CYCLE      30
`define SDFFILE    "./IPF.sdf"	  
`define End_CYCLE  10000000

`define PAT        "./mul_data_i.dat" 
`define WPA		   "./mul_data_w.dat"   
//`define EXP0       "./data_res.dat"


`define N_PAT      256**2
`define I_Width    8
`define O_Width    9
`define A_Width    16
`define ANS_NUM    128

module IPF_tb;
    
    reg clk;
	reg rst;
	reg [1:0]ctrl;			//0: end , 1:start , 2:hold   
	
	reg  [63:0] i_data; 		
	reg  [63:0] w_data;
	reg i_valid,w_valid;
	reg  [1:0] Wsize;
	
	reg  [1:0]RLPadding;
	reg  stride;
	reg  [3:0]wgroup;
	reg  [2:0]wround;
	
	wire [9215:0] result;
	wire res_valid;
	
	wire [71:0] tmp_result0;
	wire [71:0] tmp_result1;
	wire [71:0] tmp_result2;
	wire [71:0] tmp_result3;
	wire [71:0] tmp_result4;
	wire [71:0] tmp_result5;
	wire [71:0] tmp_result6;
	wire [71:0] tmp_result7;
	wire [71:0] tmp_result8;
	wire [71:0] tmp_result9;
	wire [71:0] tmp_result10;
	wire [71:0] tmp_result11;
	wire [71:0] tmp_result12;
	wire [71:0] tmp_result13;
	wire [71:0] tmp_result14;
	wire [71:0] tmp_result15;


	wire finish;
	
	reg [63:0] i_mem [0:7];
	reg [63:0] w_mem  [0:42];		//3 *3 18 , 5*5 25
	//reg [1151:0] exp_mem  [0:`ANS_NUM];	//`ANS_NUM res

	//reg [1151:0] ipf_dbg, exp_dbg;
    reg over;
    integer err, exp_num, i,cnt,i_data_id,w_data_id;
	
	
/* 接線 */
`ifdef SDF
    IPF IPF(
`else
    IPF #(.In_Width(`I_Width), .Out_Width(`O_Width), .Addr_Width(`A_Width)) IPF(
`endif
    	.clk(clk),
		.rst(rst),  
        .ctrl(ctrl),
		.i_valid(i_valid),
        .i_data(i_data),
		.w_valid(w_valid),
		.w_data(w_data), 
		.Wsize(Wsize),
		.res_valid(res_valid), 
		.result(result), 
		.finish(finish),
		
		.RLPadding(RLPadding),
		.stride(stride),
		.wgroup(wgroup),
		.wround(wround),
	
		.tmp_result0(tmp_result0),
		.tmp_result1(tmp_result1),
		.tmp_result2(tmp_result2),
		.tmp_result3(tmp_result3),
		.tmp_result4(tmp_result4),
		.tmp_result5(tmp_result5),
		.tmp_result6(tmp_result6),
		.tmp_result7(tmp_result7),
		.tmp_result8(tmp_result8),
		.tmp_result9(tmp_result9),
		.tmp_result10(tmp_result10),
		.tmp_result11(tmp_result11),
		.tmp_result12(tmp_result12),
		.tmp_result13(tmp_result13),
		.tmp_result14(tmp_result14),
		.tmp_result15(tmp_result15)
		
	);
	/*		
    ipf_mem u_ipf_mem(
   	    .clk(clk),
   	    .res_valid(res_valid),
   	    .res(re)
   	);*/
	
	/* read file data */
	initial begin
		$readmemb(`PAT, i_mem);
		$readmemb(`WPA , w_mem);
		//$readmemb(`EXP0 , exp_mem);		
		
	end
	
	/* set clk */
	always begin #(`CYCLE/2) clk = ~clk;end
	
	/* create nWave & time violation detect */
	initial begin
		`ifdef SDF //syn
			$sdf_annotate(`SDFFILE,IPF); //time violation
			$fsdbDumpfile("IPF_syn.fsdb"); //nWave
			$fsdbDumpvars("+mda");
		`else
			$fsdbDumpfile("IPF.fsdb");
			$fsdbDumpvars("+mda");
		`endif
	end

	/* init val & give data */ 
	initial begin 
	
		clk=0;
		rst=1;
		i_valid=0;
		w_valid=0;
		ctrl='hz;
		Wsize=0;
		wgroup=0;
		wround=0;
		stride=0;
		RLPadding=0;
		
		@(posedge clk)rst=0; 	//wait , when pos clk => active(rst=0)
		#(`CYCLE*2)rst=1; 		//wait 2 cyc
		@(negedge clk);
		
		i_data_id= 0;
		w_data_id= 0;
		
//------------------------------------
		
		w_valid=1;
		repeat(18)begin //3 * 3
			w_data =w_mem[w_data_id];
			w_data_id = w_data_id+1;
			@(negedge clk);
		end
		w_valid=0;
		$display("END in W\n");	
		
		i_valid=1;
		repeat(2)begin
			i_data =i_mem[i_data_id];
			i_data_id = i_data_id + 1;
			@(negedge clk);
		end
		ctrl=1; // start
		repeat(6)begin
			i_data =i_mem[i_data_id];
			i_data_id = i_data_id + 1;
			@(negedge clk);
		end
		$display("END compute first group \n");	
		
//----------------------------------------------
	
		wgroup=1;
		i_data_id = 0;
		ctrl=2;// hold
		repeat(2)begin
			i_data =i_mem[i_data_id];
			i_data_id = i_data_id + 1;
			@(negedge clk);
		end
		ctrl=1; // start
		repeat(6)begin
			i_data =i_mem[i_data_id];
			i_data_id = i_data_id + 1;
			@(negedge clk);
		end
		i_valid=0;
		
		ctrl=0; // end 
		
		$display("END RUN\n");	
		/*
		while(finish==0)begin
			
			if(cnt==0|cnt==2|cnt==4|cnt==6|cnt==8)begin
				if(cnt!=8)begin
					if(cnt==0|cnt==4)begin
						i_valid=1;
						repeat(8)begin
							i_data =i_mem[i_data_id];
							i_data_id = i_data_id + 1;
							@(negedge clk);
						end
					end
					i_valid=0;
					w_valid=1;
					if(cnt==2|cnt==6)begin
						repeat(4)begin // 8 8 8 8
							if(w_data_id==9)w_data_id=0;	// w0 - w7
							w_data =w_mem[w_data_id];
							w_data_id = w_data_id+1;
							@(negedge clk);
						end
					end
					else begin
					repeat(5)begin //8(4) 8 8 8 8
							if(w_data_id==9)w_data_id=0;	// w0 - w7
							w_data =w_mem[w_data_id];
							w_data_id = w_data_id+1;
							@(negedge clk);
						end
					end
					ctrl=1;
				end
				else ctrl=0;
			end
			else begin
				repeat(32)@(negedge clk);
				ctrl=2;
				@(negedge clk);
			end
		
			cnt = cnt +1;
			i_valid=0;
			w_valid=0;
		end	*/
		
		i_data = 'hz;i_valid=0;
		w_data = 'hz;w_valid=0;
		
	end
	
	/* check ans */
	initial begin
		err=0;
		exp_num=0;
		over=0;
		
		$display("GOGO!!\n");
		#(`CYCLE*3);
		
		wait(finish); // wait until (true)
		
		@(posedge clk);
		@(posedge clk);
		$display("finish\n");
		/*
		for(i=0;i<`ANS_NUM;i=i+1)begin
			exp_dbg=exp_mem[i]; ipf_dbg= u_ipf_mem.ipf_M[i];
			if(exp_dbg == ipf_dbg)begin
				err = err;
			end
			else begin
				err=err+1;
				if (err<=10)$display("output pixel %d is wrong!\n",i);
				else $display("err_num > 11\n");
			end
			exp_num = exp_num+1;
		end*/
		over=1;
	end
	
	/* stop program brutally*/
	initial  begin
	    #`End_CYCLE ;
	    $display("-------------------------FAIL------------------------\n");
	 	$display("     Error!!! Somethings' wrong with your code !  \n");
	 	$display("-----------------------------------------------------\n");
	 	$finish;
	end
	
	/* end test */
	initial begin
		@(posedge over)
		/*
		if((over) && (exp_num!='d0)) begin
            if (err == 0)  begin
                $display("-------------------------PASS------------------------------\n");
                $display("Congratulations!!\n");
            end else begin
                $display("-------------------------ERROR-----------------------------\n");
                $display("There are %d errors!\n", err);
            end
            $display("-----------------------------------------------------------\n");
        end*/
	    #(`CYCLE/2); $finish;
	end
		
endmodule
/*
module ipf_mem(res_valid, res, clk); 

	input	res_valid;
	input	[1151:0] res;
	input	clk;

	reg [1151:0] ipf_M [0:`ANS_NUM];
	integer i,id;
	
	initial begin
		for(i=0;i<`ANS_NUM;i=i+1)begin
			ipf_M[i]=0;
		end
		id=0;
	end
	
	always@(negedge clk)begin
		if(res_valid)begin
			ipf_M[id]<=res;
			id=id+1;
		end
	end
	
endmodule
*/