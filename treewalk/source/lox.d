module lox;

import std.format : format;
import std.stdio;

import interpreter;
import resolver;
import runtimeerror;
import scanner;
import token;
import tokentype;

class Lox
{
public:
	static this()
	{
		interpreter = new Interpreter();
	}

	static runFile(string path)
	{
		import core.stdc.stdlib : exit;
		import std.file : readText;
		run(path.readText());
		if (ctError) exit(65);
		if (rtError) exit(70);
	}

	static runPrompt()
	{
		while (true)
		{
			"> ".write;
			string line = readln();
			if (!line.length) break;
			run(line);
			ctError = false;
		}
	}

	static run(string source)
	{
		auto scanner = new Scanner(source);
		auto tokens = scanner.scanTokens();

		import astprinter;
		import expr;
		import parser;
		import stmt;
		Stmt[] statements = (new Parser(tokens)).parse();
		if (ctError) return;
		(new Resolver(interpreter)).resolve(statements);
		if (ctError) return;
		interpreter.interpret(statements);
	}

	static report(size_t line, string file, string msg)
	{
		import std.experimental.logger : logf, LogLevel;
		stderr.writefln!"[line:%s] Error: %s: %s"(line, file, msg);
		ctError = true;
	}

	static error(size_t line, string msg)
	{
		import std.experimental.logger : logf, LogLevel;
		report(line, "dlox_repl", msg);
	}
	static error(Token token, string msg)
	{
		if (token.type == TokenType.eof) report(token.line, "at end", msg);
		else report(token.line, format!"at '%s'"(token.lexeme), msg);
	}

	static runtimeError(RuntimeError e)
	{
		writefln!"%s\n[line %s]"(e.msg, e.token.line);
		rtError = true;
	}

private:
	static Interpreter interpreter;
	static bool ctError;
	static bool rtError;
}
