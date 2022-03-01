module lox.compiler;


struct Compiler
{
	import lox.dynamicarray;
	import lox.scanner;
	import lox.token;
	import lox.tokentype;

	@safe pure nothrow @nogc
	void compile(return in const(char)[] source) return scope
	{
		scanner = Scanner(source);
		size_t line;
		while (true)
		{
			Token token = scanner.scanToken();
			debug
			{
				import core.stdc.stdio : printf;
				if (token.line != line)
				{
					printf("%4lu ", token.line);
					line = token.line;
				}
				else
				{
					printf("   | ");
				}
				printf("%2d '%.*s'\n", token.type, cast(int) token.length, token.start);
				if (token.type == TokenType.eof) break;
			}
		}
	}

	Scanner scanner;
}
