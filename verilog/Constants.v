`define OPCODE_MSB 7

`define OP_INC          (1 << 0)	// >
`define OP_DEC          (1 << 1)	// <
`define OP_INCREF       (1 << 2)	// +
`define OP_DECREF       (1 << 3)	// -
`define OP_OUT          (1 << 4)	// .
`define OP_IN           (1 << 5)	// ,
`define OP_LOOPBEGIN	(1 << 6)	// [
`define OP_LOOPEND	(1 << 7)	// ]
