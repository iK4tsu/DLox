module chunkdebug;

import std.algorithm : each, until;
import std.range : back, recurrence;
import std.stdio : write, writef, writefln, writeln;
import std.format : format;

import chunk;

void disassembleChunk(ref scope Chunk chunk, in string name)
{
	name.writefln!"== %s ==";
	disassembleInstruction(chunk, 0)
		.recurrence!((state, n) => disassembleInstruction(chunk, state[n - 1]))
		.until!(i => i == chunk.length)
		.each;
}

size_t disassembleInstruction(ref scope Chunk chunk, size_t offset)
{
	offset.writef!"%04d ";

	if (offset && chunk.lines[offset] == chunk.lines[offset - 1])
	{
		write("   | ");
	}
	else
	{
		writef!"%4d "(chunk.lines[offset]);
	}

	ubyte instruction = chunk[offset];
	switch (instruction) with (OpCode)
	{
		case opReturn:
			return simpleInstruction("OP_RETURN", offset);

		case opConstant:
			return constantInstruction("OP_CONSTANT", chunk, offset);

		default:
			instruction.writefln!"Unkown opcode %s";
			return offset + 1;
	}
}

private size_t constantInstruction(in string name, in Chunk chunk, size_t offset)
{
	// after a constant instruction there's always an index to the value in the
	// constant array
	ubyte constantIndex = chunk[offset + 1];
	writefln!"%-16s %4d '%s'"(name, constantIndex, chunk.constants[constantIndex]);
	return offset + 2;
}

private size_t simpleInstruction(in string name, size_t offset)
{
	name.writeln;
	return offset + 1;
}
