module app;

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import lox.dynamicarray;
import lox.vm;

extern(C) int main(int argc, char** argv)
{
	version(dlox_unittest)
	{
		import lox.dynamicarray;

		static foreach (unit; __traits(getUnitTests, lox.dynamicarray))
		{{
			unit();
			printf("%.*s -> passed\n", cast(int) __traits(identifier, unit).length, __traits(identifier, unit).ptr);
		}}
	}
	else
	{
		VM vm = VM.initialize();

		switch (argc)
		{
			case 1: repl(vm); break;
			case 2: runFile(vm, argv[1]); break;
			default:
				fprintf(stderr, "Usage: dlox [path]\n");
				return 64;
		}
	}

	return 0;
}


void repl(ref VM vm)
{
	// should be dynamically allocated but oh well
	char[1024] buf;

	while (true)
	{
		printf("> ");

		if (!fgets(buf.ptr, 1024, stdin))
		{
			printf("\n");
			break;
		}

		import core.stdc.string : strlen;
		vm.interpret(buf[0 .. strlen(buf.ptr)]);
	}
}

void runFile(ref VM vm, in const(char)* path)
{
	import lox.vm : InterpretResult;
	import core.memory : pureFree;

	char[] source = readFile(path);

	/// we have the ownership of source
	scope(exit) pureFree(source.ptr);

	InterpretResult result = vm.interpret(source);

	switch (result) with (InterpretResult)
	{
		case compileError: exit(65);
		case runtimeError: exit(70);
		default:
	}
}

char[] readFile(in const(char)* path)
{
	FILE* fp = fopen(path, "rb");

	if (!fp)
	{
		fprintf(stderr, "Not enough memory to read file '%s'", path);
		exit(74);
	}

	scope(exit) fclose(fp);

	fseek(fp, 0, SEEK_END);
	size_t sz = ftell(fp);
	rewind(fp);

	import lox.mallocator;
	void[] buf = Mallocator.allocate(sz * char.sizeof);

	if (fread(buf.ptr, char.sizeof, sz, fp) < sz)
	{
		fprintf(stderr, "Could not read file '%s'", path);
		exit(74);
	}

	// returning ownership!
	return (cast(char*) buf.ptr)[0 .. sz];
}
