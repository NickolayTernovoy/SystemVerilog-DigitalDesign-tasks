**Implement a module to implement the logic of the [ROL](https://five-embeddev.com/riscv-bitmanip/1.0.0/bitmanip.html#insns-rol) instruction from the RISC-V Bitmanip extension:**

**Constraints**: We will consider only the case for a **16-bit input operand** to simplify the design and verification.

The `ROL` (Rotate Left) instruction in RISC-V shifts the bits of a register to the left, with the bits that overflow from the most significant position re-entering from the least significant position. 
It is useful for operations that require bit-level manipulation, such as cryptography, hashing algorithms, or cyclic redundancy checks, where rotating bits can improve performance and reduce code complexity.

Here is an example of the ROL operation on a 4-bit operand, but please note that the task requires implementing the ROL operation for a 16-bit operand.

```
0010 → 0100 → 1000 → 0001 → 0010 ...
```

Each number in the sequence is obtained by performing a left rotate operation (ROL) on the previous number. In binary, this means rotating the bits of the 4-bit number to the left by one position. After the leftmost bit is rotated out, it re-enters on the rightmost bit.


### **Interface Definition**

- **`result_by_shift_o `**: A 16-bit result obtained through left and right shift operations and a logical OR operation.  
- **`result_by_borders_o `**: A 16-bit result obtained by extending the width of the input operand and the shift operator.

### **Interface Requirements**

- In this task, we will treat the module as a combinational circuit, where the computation results appear in the same clock cycle as the input data.
- To simplify the design, we will not use any validity signals, reset signals, or flush signals.
