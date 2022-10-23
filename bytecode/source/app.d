module app;

import std.stdio : readln, stderr, write;
import core.stdc.stdlib : exit;

import chunk;
import chunkdebug;
import vm;

void main(string[] args)
{
	initVM();
	scope(exit) freeVM();

	Chunk chunk;
	initChunk(chunk);

	switch (args.length)
	{
		case 1: repl(); break;
		case 2: runFile(args[1]); break;
		default:
			stderr.writeln("Usage: clox [path]");
			exit(64);
	}
}

private void repl()
{
	while (true)
	{
		"> ".write;
		string line = readln();
		if (!line.length) break;
		interpret(line);
	}
}

private void runFile(string path)
{
	import core.stdc.stdlib : exit;
	import std.file : readText;
	InterpretResult result = interpret(path.readText());
	switch (result) with (InterpretResult)
	{
		case compileError: exit(65);
		case runtimeError: exit(70);
		default:
	}
}
