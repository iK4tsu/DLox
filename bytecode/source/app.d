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

	offset = addConstant(chunk, 3.4);
	writeChunk(chunk, OpCode.opConstant, 123);
	writeChunk(chunk, offset, 123);

	writeChunk(chunk, OpCode.opAdd, 123);

	offset = addConstant(chunk, 5.6);
	writeChunk(chunk, OpCode.opConstant, 123);
	writeChunk(chunk, offset, 123);

	writeChunk(chunk, OpCode.opDivide, 123);
	writeChunk(chunk, OpCode.opNegate, 123);

	writeChunk(chunk, OpCode.opReturn, 123);

	disassembleChunk(chunk, "test chunk");
	interpret(chunk);
	freeVM();
	freeChunk(chunk);
}
