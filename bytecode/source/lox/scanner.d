module lox.scanner;

struct Scanner
{
	import lox.dynamicarray;
	import lox.token;
	import lox.tokentype;

	@disable this(this);

	@safe pure nothrow @nogc
	this(return in const(char)[] source)
	{
		// the lifetime of source is guarateed to be longer than the Scanner
		this.start = source.length ? &source[0] : null;
		this.end = source.length ? &source[$ - 1] : null;
		this.current = this.start;
	}

	@safe pure nothrow @nogc
	Token scanToken() return scope
	{
		start = current;
		if (atEnd()) return makeToken(TokenType.eof);
		return errorToken("Unexpected character.");
	}

	@safe pure nothrow @nogc
	bool atEnd() scope
	{
		return current >= end;
	}

	@safe pure nothrow @nogc
	Token errorToken(return in string msg) return scope
	{
		import core.stdc.string : strlen;

		Token token;
		token.type = TokenType.error;
		token.start = &msg[0];
		token.length = msg.length;
		token.line = this.line;

		return token;
	}

	@safe pure nothrow @nogc
	Token makeToken(TokenType type) return scope
	{
		Token token;
		token.type = type;
		token.start = start;
		token.length = current - start;
		token.line = line;

		return token;
	}

	const(char)* start;
	const(char)* end;
	const(char)* current;
	size_t line = 1;
}
