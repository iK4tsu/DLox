module chunkdebug;

import std.algorithm : each, until;
import std.range : back, recurrence;
import std.stdio : writef, writefln, writeln;

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

	ubyte instruction = chunk[offset];
	switch (instruction) with (OpCode)
	{
		case opReturn:
			return simpleInstruction("OP_RETURN", offset);

		default:
			instruction.writefln!"Unkown opcode %s";
			return offset + 1;
	}
}

private size_t simpleInstruction(in string name, size_t offset)
{
	name.writeln;
	return offset + 1;
}
