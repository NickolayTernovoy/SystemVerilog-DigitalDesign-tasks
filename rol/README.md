### **Task Overview**

The ROL (Rotate Left) instruction shifts the bits of a register to the left, with the bits that overflow from the most significant position re-entering at the least significant position. This operation is often used in bit-level manipulation tasks, such as cryptography, hashing algorithms, or cyclic redundancy checks, where rotating bits can improve performance and reduce code complexity. This instruction is also part of the [RISC-V Bitmanip](https://five-embeddev.com/riscv-bitmanip/1.0.0/bitmanip.html#insns-rol) extension.

**Constraints**: To simplify the design and verification, we will only consider the case of a 16-bit input operand.

Here is an example of the ROL operation on a 4-bit operand. Please note that the task requires implementing the ROL operation for a 16-bit operand.

```
0010 →
0100 →
1000 →
0001 →
0010 →
0100 →
1000 ...
```

In this sequence, each number is obtained by performing a left rotate (ROL) operation on the previous number. In binary, this means rotating the bits of the 4-bit number to the left by one position. After the leftmost bit is rotated out, it re-enters at the rightmost bit.

### **Task Details**

The rotation operation can be solved in two ways:

- **Approach 1**: Use smaller shifters for both left and right shifts, then combine the results using a logical operation.
- **Approach 2**: Use a wider shifter, which directly performs the rotate.

Your task is to implement **both approaches**.

### **Tips:**

If implementing the second approach is difficult, but you want to verify the correctness of your solution, you can connect the output of the already completed approach to a free output port. This will allow you to check its functionality. However, remember that the challenge of this task is to find and implement two distinct algorithms to solve the problem.

Good luck!

### **Output Interface Definition**

- **`result_by_shift_o`**: A 16-bit result obtained for the first approach.
- **`result_by_borders_o`**: A 16-bit result obtained for the second approach.

### **Interface Requirements**

- In this task, we treat the module as a combinational circuit, where the computation results appear in the same clock cycle as the input data. There are no registers (neither flip-flops nor latches) used in this task.
- To simplify the design, we will not use any validity signals, reset signals, or flush signals.
