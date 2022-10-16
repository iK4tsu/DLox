module vm;

import std.stdio : writeln;

import chunk;

// VM being globaly defined is for easiness of the book
VM vm;

struct VM
{
	Chunk* chunk;
	ubyte* ip;
}


void initVM() {}

void freeVM() {}



enum InterpretResult
{
	ok,
	compileError,
	runtimeError,
}

InterpretResult interpret(ref Chunk chunk)
{
	vm.chunk = &chunk;
	vm.ip = &vm.chunk.instructions[0];
	return run();
}

private InterpretResult run()
{
	auto readByte = () => *vm.ip++;
	auto readConstant = () => vm.chunk.constants[readByte()];

	while (true)
	{
		debug (debugTraceExecution)
		{
			import chunkdebug;
			disassembleInstruction(*vm.chunk, vm.ip - &vm.chunk.instructions[0]);
		}

		ubyte instruction = readByte();
		final switch (instruction)
		{
			case OpCode.opConstant:
				readConstant().writeln();
				break;

			case OpCode.opReturn:
				return InterpretResult.ok;
		}
	}
}
