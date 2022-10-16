module app;

import chunk;
import chunkdebug;

void main(string[] args)
{
	Chunk chunk;
	initChunk(chunk);

	size_t offset = addConstant(chunk, 1.2);
	writeChunk(chunk, OpCode.opConstant);
	writeChunk(chunk, offset);

	writeChunk(chunk, OpCode.opReturn);

	disassembleChunk(chunk, "test chunk");
	freeChunk(chunk);
}
