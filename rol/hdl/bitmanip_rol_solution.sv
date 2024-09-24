`timescale 1ns / 1ps

module bitmanip_rol_solution #(
    parameter SIZE = 16,
    parameter SHAMT_SIZE = $clog2(SIZE)
)(
    input  [SIZE-1:0]       data_i                ,
    input  [SHAMT_SIZE-1:0] shamt_i               ,
    output [SIZE-1:0]       result_by_shift_o     ,
    output [SIZE-1:0]       result_by_borders_o
);
    logic [2*SIZE-1:0] result_by_borders_o_comb;
    
    // approach 1
    assign result_by_shift_o = (data_i << shamt_i) | (data_i >> (SIZE - shamt_i) );
    
    // approach 2
    assign result_by_borders_o_comb   = {data_i, data_i} << shamt_i;
    assign result_by_borders_o        = result_by_borders_o_comb[2*SIZE-1:SIZE];

endmodule

