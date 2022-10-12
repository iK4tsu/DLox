module chunk;

enum OpCode : ubyte
{
	opReturn,
}

alias Chunk = ubyte[];

void initChunk(ref scope Chunk chunk)
{
	chunk = [];
}

alias freeChunk = initChunk;

void writeChunk(ref scope Chunk chunk, ubyte instruction)
{
	chunk ~= instruction;
}

