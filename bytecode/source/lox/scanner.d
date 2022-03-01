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
		skipWhitespace();
		start = current;
		if (atEnd()) return makeToken(TokenType.eof);

		const char c = advance();

		switch (c) with (TokenType)
		{
			case '(': return makeToken(left_paren);
			case ')': return makeToken(right_paren);
			case '{': return makeToken(left_brace);
			case '}': return makeToken(right_brace);
			case ';': return makeToken(semicolon);
			case ',': return makeToken(comma);
			case '.': return makeToken(dot);
			case '-': return makeToken(minus);
			case '+': return makeToken(plus);
			case '/': return makeToken(slash);
			case '*': return makeToken(star);
			case '!': return makeToken(match('=') ? bang_equal : bang);
			case '=': return makeToken(match('=') ? equal_equal : equal);
			case '<': return makeToken(match('=') ? less_equal : less);
			case '>': return makeToken(match('=') ? greater_equal : greater);
			case '"': return scanString();
			case '0': .. // isDigit
			case '9': return scanNumber();
			default:
		}

		return errorToken("Unexpected character.");
	}

	@safe pure nothrow @nogc
	const(char) advance() scope
	{
		return () @trusted { return *current++; } ();
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

	@safe pure nothrow @nogc
	bool match(in char expected) scope
	{
		if (atEnd()) return false;
		if (*current != expected) return false;

		() @trusted { current++; } ();
		return true;
	}

	@safe pure nothrow @nogc
	const(char) peek() scope
	{
		return *current;
	}

	@safe pure nothrow @nogc
	const(char) peekNext() scope
	{
		if (atEnd()) return '\0';
		return () @trusted { return *(current + 1); } ();
	}

	@safe pure nothrow @nogc
	Token scanNumber() return scope
	{
		import std.ascii : isDigit;

		while (peek.isDigit()) advance();

		if (peek() == '.' && peekNext.isDigit())
		{
			advance();
			while (peek.isDigit()) advance();
		}

		return makeToken(TokenType.number);
	}

	@safe pure nothrow @nogc
	Token scanString() return scope
	{
		while (peek() != '"' && !atEnd())
		{
			if (peek() == '\n') line++;
			advance();
		}

		if (atEnd()) return errorToken("Unterminated string.");

		advance(); // closing '"'
		return makeToken(TokenType.string_);
	}

	@safe pure nothrow @nogc
	void skipWhitespace() scope
	{
		while (true)
		{
			switch (peek())
			{
				case '/':
					if (peekNext() == '/')
					{
						while (peek() != '\n' && !atEnd())
							advance();
					}

					return;
				case '\n': line++; goto case;
				case ' ':
				case '\r':
				case '\t': advance(); goto default;
				default: return;
			}
		}
	}

	const(char)* start;
	const(char)* end;
	const(char)* current;
	size_t line = 1;
}
