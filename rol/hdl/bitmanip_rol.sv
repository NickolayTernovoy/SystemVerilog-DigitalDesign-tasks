`timescale 1ns / 1ps

module bitmanip_rol #(
    parameter SIZE = 16,
    parameter SHAMT_SIZE = $clog2(SIZE)
)(
    input  [SIZE-1:0]       data_i                ,
    input  [SHAMT_SIZE-1:0] shamt_i               ,
    output [SIZE-1:0]       result_by_shift_o     ,
    output [SIZE-1:0]       result_by_borders_o
);
    // In this task, you will need additional signals. 
    // You can declare them here.
    // Write your code here:
    
    // approach 1
    // Write your code here :
    //assign result_by_shift_o = ...
    
    // approach 2
    // Write your code here :
    // assign result_by_borders_o = ... 

endmodule
