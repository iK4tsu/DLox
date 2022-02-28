module lox.scanner;

struct Scanner
{
	import lox.dynamicarray;

	@disable this(this);

	@safe pure nothrow @nogc
	this(return in const(char)[] source)
	{
		// the lifetime of source is guarateed to be longer than the Scanner
		this.start = source.length ? &source[0] : null;
		this.end = source.length ? &source[$ - 1] : null;
		this.current = this.start;
	}

	const(char)* start;
	const(char)* end;
	const(char)* current;
	size_t line = 1;
}
