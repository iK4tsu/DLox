module chunk;

import std.conv : to;

import value;

enum OpCode : ubyte
{
	opConstant,
	opReturn,
}

struct Chunk
{
	alias instructions this;

	ubyte[] instructions;
	ValueArray constants;
}

void initChunk(ref scope Chunk chunk)
{
	chunk.instructions = [];
	initValueArray(chunk.constants);
}

alias freeChunk = initChunk;

void writeChunk(ref scope Chunk chunk, ubyte instruction)
{
	chunk ~= instruction;
}

void writeChunk(ref scope Chunk chunk, size_t offset)
{
	writeChunk(chunk, offset.to!ubyte);
}

size_t addConstant(ref scope Chunk chunk, Value value)
{
	scope(exit) writeValueArray(chunk.constants, value);
	return chunk.constants.length;
}
