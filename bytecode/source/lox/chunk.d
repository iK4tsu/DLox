module lox.chunk;

/**
An operation code that defines the instruction set. Each instruction represents
an operation our VM will understand and execute.
*/
enum OpCode : ubyte
{
	/// defines a value
	constant,

	/// return from the current function
	return_,
}


struct Chunk
{
	import lox.dynamicarray;
	import lox.util;
	import lox.value;
	import std.sumtype;

	/**
	Convert machine instructions into human readable text.

	Params:
		name = chunk title.

	Returns: a dynamic array with the disassembled information.
	*/
	@safe pure nothrow @nogc
	scope DynamicArray!char disassembleChunk(string name = "Chunk")
	{
		import core.stdc.stdio : sprintf;

		DynamicArray!char arr = "=== ";
		arr.capacity = 256;
		arr ~= name;
		arr ~= " ===\n";

		for (size_t i; i < code.length; i += instructionOffset(code[i]))
		{
			char[8] str;
			() @trusted { assumePure(&sprintf)(str.ptr, "%04lu  | ", i); } ();
			arr ~= str[];

			disassembleInstruction(code[i]).match!(
				(string s) {
					arr ~= s;
					if (code[i] == OpCode.constant) () @trusted {
						import core.stdc.stdio : sprintf;

						arr ~= " [index: ";

						auto l = assumePure(&sprintf)(str.ptr, "%lu", i);
						arr ~= str[0 .. l];
						arr ~= "]: ";

						l = assumePure(&sprintf)(str.ptr, "%g", constants[code[i + 1]].value);
						arr ~= str[0 .. l];
					} ();
				},
				(_) @trusted {
					char[26] msg;
					assumePure(&sprintf)(msg.ptr, "unkown instruction '%d'", i);
					arr ~= msg[];
				}
			);

			arr ~= '\n';
		}

		return arr;
	}

	/**
	Instruction length. Each instruction must have a length with a minimum of 1 byte.
	The length represents the offset to the next instruction. In between each
	offset the index with the value correspondent to the instruction is stored.

	Params:
		op = OpCode to inspect.

	Returns: the length of the instruction, an invalid instruction has length 1.
	*/
	@safe pure nothrow @nogc
	size_t instructionOffset(in ubyte op) scope
	{
		switch (op) with (OpCode)
		{
			case constant: return 2;
			case return_:
			default: return 1;
		}
	}

	/**
	Converts an instruction to it's human readable text representation.

	Params:
		op = OpCode to inspect.

	Returns: an optional value containing the reprensation of a valid instruction
	or nothing otherwise.
	*/
	@safe pure nothrow @nogc
	Optional!string disassembleInstruction(in ubyte op) scope
	{
		import core.stdc.stdio : sprintf;

		switch (op) with (OpCode)
		{
			case constant: return some("constant");
			case return_:  return some("return");
			default:       return none!string;
		}
	}

	/*
	Outputs the disassembled information of the chunk.
	*/
	@safe nothrow @nogc
	void pprint() scope
	{
		auto str = disassembleChunk();
		import core.stdc.stdio : printf;
		() @trusted { printf("%.*s", cast(int) str.length, str[].ptr); } ();
	}


	/// bytecode is a series of instructions
	DynamicArray!ubyte code;

	/// all of the values in our program
	DynamicArray!Value constants;
}
