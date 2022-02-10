module lox.chunk;

/**
An operation code that defines the instruction set. Each instruction represents
an operation our VM will understand and execute.
*/
enum OpCode : ubyte
{
	/// return from the current function
	return_,
}


struct Chunk
{
	import lox.dynamicarray;

	/// bytecode is a series of instructions
	DynamicArray!ubyte code;
}
