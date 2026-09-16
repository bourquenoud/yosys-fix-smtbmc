module arbiter_2 (
	input logic clk_i,
	input logic rst_ni,
	input logic [1:0] req_i,
	output logic [1:0] grant_o
);
	logic last_grant_q, last_grant_d;

	assign grant_o[1] = ~last_grant_q && req_i[1];
	assign grant_o[0] = (last_grant_q && req_i[0]) || (~last_grant_q && req_i[0] && ~req_i[1]);

	assign last_grant_d = grant_o == 2'b10 ? 1'b1 :
	                      grant_o == 2'b01 ? 1'b0 :
	                      last_grant_q;

	always_ff @(posedge clk_i, negedge rst_ni)
		if (!rst_ni)
			last_grant_q <= 1'b0;
		else
			last_grant_q <= last_grant_d;

	initial assume (!rst_ni);

	always_ff @(posedge clk_i)
		if (rst_ni && $stable(rst_ni)) begin
			a_latency: assert (|$past(req_i) ? $past(req_i) & ($past(grant_o) | grant_o) : 1);
			a_onehot: assert (|req_i ? $onehot(grant_o) : ~|grant_o);
		end
endmodule
