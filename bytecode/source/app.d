module app;

import chunk;
import chunkdebug;
import vm;

void main(string[] args)
{
	initVM();

	Chunk chunk;
	initChunk(chunk);

	size_t offset = addConstant(chunk, 1.2);
	writeChunk(chunk, OpCode.opConstant, 123);
	writeChunk(chunk, offset, 123);

	writeChunk(chunk, OpCode.opReturn, 123);

	disassembleChunk(chunk, "test chunk");
	interpret(chunk);
	freeVM();
	freeChunk(chunk);
}
