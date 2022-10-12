module app;

import chunk;
import chunkdebug;

void main(string[] args)
{
	Chunk chunk;
	initChunk(chunk);
	writeChunk(chunk, OpCode.opReturn);

	disassembleChunk(chunk, "test chunk");
	freeChunk(chunk);
}
