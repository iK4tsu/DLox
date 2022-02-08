import std.stdio;

import scanner;

void main(string[] args)
{
	import astprinter;
	import expr;
	import token;
	import tokentype;
	import lox;
	import std.conv;
	import std.variant;

	switch (args.length) with (Lox)
	{
		case 1: runPrompt(); break;
		case 2: runFile(args[1]); break;
		default: "Usage: dlox [file]".writeln;
	}
}
