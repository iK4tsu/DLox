module compiler;

import scanner;


void compile(in string source)
{
	initScanner(source);
	size_t line = 0;
	while (true)
	{
		import std.stdio : write, writefln;

		Token token = scanToken();
		if (token.line != line)
		{
			writefln!"%04s"(token.line);
			line = token.line;
		}
		else
		{
			write("   | ");
		}

		writefln!"%2s '%s'"(token.type, token.start[0 .. token.length]);

		if (token.type == TokenType.eof) break;
	}
}
