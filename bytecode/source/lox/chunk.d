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
	Adds a value to the constant's list.

	Params:
		value = constant to add.

	Returns: the index in ubyte of the value added.
	*/
	ubyte addConstant(Value constant)
	{
		auto index = cast(ubyte) constants.length;

		constants ~= constant;

		return index;
	}

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
			arr ~= disassembleInstructionf(i);
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

	/**
	Converts an instruction to it's human readable text representation. Similiar
	to `disassembleInstruction` with extra information about the instruction.

	Params:
		offset = bytecode offset to inspect.

	Returns: a dynamic array containing the text reprensation of the bytecode at
	the given offset.
	*/
	@safe pure nothrow @nogc
	DynamicArray!char disassembleInstructionf(in size_t offset) scope
	{
		import core.stdc.stdio : sprintf;

		DynamicArray!char arr;

		char[64] buf;
		auto len = () @trusted { return assumePure(&sprintf)(buf.ptr, "%04lu ", offset); } ();
		arr ~= buf[0 .. len];

		if (offset && lines[offset] == lines[offset - 1])
		{
			arr ~= "   | ";
		}
		else
		{
			len = () @trusted { return assumePure(&sprintf)(buf.ptr, "%4d ", lines[offset]); } ();
			arr ~= buf[0 .. len];
		}

		disassembleInstruction(code[offset]).match!(
			(string s) {
				arr ~= s;
				if (code[offset] == OpCode.constant) () @trusted {
					arr ~= "\t";

					len = assumePure(&sprintf)(buf.ptr, "%lu", offset);
					arr ~= buf[0 .. len];
					arr ~= " '";

					len = assumePure(&sprintf)(buf.ptr, "%g", constants[code[offset + 1]].value);
					arr ~= buf[0 .. len];

					arr ~= "'";
				} ();
			},
			(_) @trusted {
				len = assumePure(&sprintf)(buf.ptr, "unkown instruction '%d'", offset);
				arr ~= buf[0 .. len];
			}
		);

		return arr ~ '\n';
	}

	/**
	Outputs the disassembled information of the chunk.
	*/
	@safe nothrow @nogc
	void pprint() scope
	{
		auto str = disassembleChunk();
		import core.stdc.stdio : printf;
		() @trusted { printf("%.*s", cast(int) str.length, str[].ptr); } ();
	}

	/**
	Add a single byte to the set of instructions. A byte might be an operation
	or additional information for that operation.

	Params:
	  byte_ = bytecode to add.
	  line = line in which byte is in.
	*/
	void write(ubyte byte_, int line)
	{
		code ~= byte_;
		lines ~= line;
	}


	/// bytecode is a series of instructions
	DynamicArray!ubyte code;

	/// all of the values in our program
	DynamicArray!Value constants;

	/// lines of each instruction in 'code'
	DynamicArray!int lines;
}
