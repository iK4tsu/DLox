module vm;

import std.stdio : writeln;

import chunk;
import value;

// VM being globaly defined is for easiness of the book
VM vm;

struct VM
{
	Chunk* chunk;
	ubyte* ip;
	Value[256] stack;
	Value* stackTop;
}


void initVM()
{
	resetStack();
}

void freeVM() {}

private void resetStack()
{
	vm.stackTop = &vm.stack[0];
}



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

void push(Value value)
{
	*vm.stackTop = value;
	vm.stackTop++;
}

Value pop()
{
	vm.stackTop--;
	return *vm.stackTop;
}

private InterpretResult run()
{
	auto readByte = () => *vm.ip++;
	auto readConstant = () => vm.chunk.constants[readByte()];

	while (true)
	{
		debug (debugTraceExecution)
		{
			import std.stdio : writefln;
			writefln!"%10s%s"("", vm.stack[0 .. vm.stackTop - &vm.stack[0]]);

			import chunkdebug;
			disassembleInstruction(*vm.chunk, vm.ip - &vm.chunk.instructions[0]);
		}

		ubyte instruction = readByte();
		final switch (instruction)
		{
			case OpCode.opConstant:
				readConstant().push();
				break;

			case OpCode.opReturn:
				pop().writeln();
				return InterpretResult.ok;
		}
	}
}
