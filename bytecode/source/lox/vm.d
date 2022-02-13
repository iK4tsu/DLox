module lox.vm;

/// debuging purposes only
version = debug_trace_execution;

enum InterpretResult
{
	ok,
	compileError,
	runtimeError,
}

struct VM
{
	import lox.chunk;
	import lox.value;

	/**
	Interprets and runs a chunk of bytecode.

	Params:
		chunk = chunk to interpret.

	Returns: an InterpretResult with success or error value.
	*/
	@safe pure nothrow @nogc
	InterpretResult interpret(ref Chunk chunk) scope
	{
		this.chunk = &chunk;
		this.ip = () @trusted { return &chunk.code[0]; } ();
		return run();
	}

	/**
	Runs the current chunk stored.

	Returns: an InterpretResult with success or error value.
	*/
	@safe pure nothrow @nogc
	InterpretResult run() scope
	{
		scope readByte = () @trusted => *ip++;
		scope readConstant = () => chunk.constants[readByte()];
		while (true)
		{
			version(debug_trace_execution)
			debug {
				import core.stdc.stdio : printf;
				const str = chunk.disassembleInstructionf(cast(size_t)(ip - &chunk.code[0]));
				printf("%.*s", cast(int) str.length, str[].ptr);
			}

			final switch (readByte()) with (OpCode)
			{
				case constant: {
					Value constant = readConstant();
					break;
				}
				case return_: return InterpretResult.ok;
			}
		}
	}

	Chunk* chunk;
	ubyte* ip;
}
