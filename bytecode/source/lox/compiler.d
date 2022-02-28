module lox.compiler;


struct Compiler
{
	import lox.dynamicarray;
	import lox.scanner;

	@safe pure nothrow @nogc
	void compile(return in const(char)[] source) return scope
	{
		scanner = Scanner(source);
	}

	Scanner scanner;
}
