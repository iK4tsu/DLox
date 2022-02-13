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

	@disable this();

	/// Correctly initializes the VM
	@safe pure nothrow @nogc
	static initialize()
	{
		VM vm = VM.init;
		vm.initVM();
		return vm;
	}

	/// Gets the VM in its initial state
	@safe pure nothrow @nogc
	void initVM() scope
	{
		// better than stack = stack.initialize()
		resetStack();
	}

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

	/// Clears the VM's stack
	@safe pure nothrow @nogc
	void resetStack() scope
	{
		stack.reset();
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

				printf("%-10s", " ".ptr);
				for (auto slot = &stack[0]; slot < stack.top; () @trusted { slot++; } ())
				{
					printf("[ ");
					slot.print();
					printf(" ]");
				}
				printf("\n");

				const str = chunk.disassembleInstructionf(cast(size_t)(ip - &chunk.code[0]));
				printf("%.*s", cast(int) str.length, str[].ptr);
			}

			/// boiler plate for binary operations
			void binopfun(string op)()
			{
				const b = stack.pop();
				const a = stack.pop();
				stack.push(Value(mixin("a" ~ op ~ "b")));
			}

			final switch (readByte()) with (OpCode)
			{
				case add:
					binopfun!"+"();
					break;
				case constant: {
					Value constant = readConstant();
					stack.push(constant);
					break;
				}
				case divide:
					binopfun!"/"();
					break;
				case multiply:
					binopfun!"*"();
					break;
				case negate:
					stack.push(Value(-stack.pop()));
					break;
				case return_: {
					stack.pop();
					return InterpretResult.ok;
				}
				case subtract:
					binopfun!"-"();
					break;
			}
		}
	}

	Chunk* chunk;
	ubyte* ip;

	Stack stack;
}

struct Stack
{
	import lox.value;

	@disable this();

	/// correctly initializes stack
	@safe pure nothrow @nogc
	static initialize()
	{
		Stack stack = Stack.init;
		stack.reset();
		return stack;
	}

	/**
	Removes the element at the top of the stack

	Returns: the removed element.
	*/
	@safe pure nothrow @nogc
	Value pop() scope
	{
		return () @trusted { return *--top; } ();
	}

	/**
	Inserts an element to the top of the stack.

	Params:
		value = element to add.
	*/
	@safe pure nothrow @nogc
	void push(in Value value) scope
	{
		() @trusted {*top++ = value; } ();
	}

	/// Clears the stack
	@safe pure nothrow @nogc
	void reset() scope
	{
		top = () @trusted { return &stack[0]; } ();
	}

	enum stackmax = ubyte.max;
	Value[stackmax] stack;
	alias stack this;
	Value* top;
}
