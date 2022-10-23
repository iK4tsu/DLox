module scanner;

// Scanner being globaly defined is for easiness of the book
Scanner scanner;

struct Scanner
{
	immutable(char)* start;
	immutable(char)* current;
	immutable(char)* end;
	size_t line;
}

struct Token
{
	TokenType type;
	immutable(char)* start;
	size_t length;
	size_t line;
}

enum TokenType
{
	// single char tokens
	left_paren, right_paren, left_brace, right_brace,
	comma, dot, minus, plus, semicolon, slash, star,

	// one or two char tokens
	bang, bang_equal, equal, equal_equal,
	greater, greater_equal, less, less_equal,

	// literals
	identifier, string_, number,

	// keywords
	and, class_, else_, false_, fun, for_, if_, nil, or,
	print, return_, super_, this_, true_, var, while_,

	error, eof,
}

void initScanner(const string source)
{
	scanner.start = &source[0];
	scanner.current = &source[0];
	scanner.end = &source[$ - 1] + 1; // points to address past the last
	scanner.line = 1;
}

Token scanToken()
{
	scanner.start = scanner.current;

	if (isAtEnd()) return makeToken(TokenType.eof);

	return errorToken!"Unexpected character."();
}

private bool isAtEnd()
{
	return scanner.current == scanner.end;
}

private Token makeToken(TokenType type)
{
	return Token(type, scanner.start, scanner.current - scanner.start, scanner.line);
}

private Token errorToken(alias message)()
{
	return Token(TokenType.error, &message[0], message.length, scanner.line);
}
