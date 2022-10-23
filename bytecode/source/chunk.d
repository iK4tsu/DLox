module chunk;

import std.conv : to;

import value;

enum OpCode : ubyte
{
	opConstant,
	opAdd,
	opSubtract,
	opMultiply,
	opDivide,
	opNegate,
	opReturn,
}

struct Chunk
{
	alias instructions this;

	ubyte[] instructions;
	ValueArray constants;
	size_t[] lines;
}

void initChunk(ref scope Chunk chunk)
{
	chunk.instructions = [];
	chunk.lines = [];
	initValueArray(chunk.constants);
}

alias freeChunk = initChunk;

void writeChunk(ref scope Chunk chunk, ubyte instruction, size_t line)
{
	chunk ~= instruction;
	chunk.lines ~= line;
}

void writeChunk(ref scope Chunk chunk, size_t offset, size_t line)
{
	writeChunk(chunk, offset.to!ubyte, line);
}

size_t addConstant(ref scope Chunk chunk, Value value)
{
	scope(exit) writeValueArray(chunk.constants, value);
	return chunk.constants.length;
}
