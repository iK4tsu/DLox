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
	skipWhitespace();
	scanner.start = scanner.current;

	if (isAtEnd()) return makeToken(TokenType.eof);

	immutable ch = advance();

	import std.ascii : isAlpha, isDigit;
	if (ch.isDigit()) return makeNumber();
	if (ch.isAlpha() || ch == '_') return makeIdentifier();

	switch (ch) with (TokenType)
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

		case '"': return makeString();

		default:
	}

	return errorToken!"Unexpected character."();
}

private void skipWhitespace()
{
	while (true)
	{
		switch (peek())
		{
			case '\n': scanner.line++; goto case;
			case ' ':
			case '\r':
			case '\t': advance(); goto default;

			case '/':
				if (match('/'))
				{
					while (peek() != '\n' && !isAtEnd())
						advance();
				}
				goto default;

			default: return;
		}
	}
}

private Token makeIdentifier()
{
	auto checkKeyword(size_t offset, string remaining, TokenType tokenType)
	{
		if (scanner.start[offset .. scanner.current - scanner.start] == remaining)
			return tokenType;

		return TokenType.identifier;
	}

	auto identifierType()
	{
		switch (scanner.start[0]) with (TokenType)
		{
			case 'a': return checkKeyword(1, "nd", and);
			case 'c': return checkKeyword(1, "lass", class_);
			case 'e': return checkKeyword(1, "lse", else_);
			case 'i': return checkKeyword(1, "f", if_);
			case 'n': return checkKeyword(1, "il", nil);
			case 'o': return checkKeyword(1, "or", or);
			case 'p': return checkKeyword(1, "rint", print);
			case 'r': return checkKeyword(1, "eturn", return_);
			case 's': return checkKeyword(1, "uper", super_);
			case 'v': return checkKeyword(1, "ar", var);
			case 'w': return checkKeyword(1, "hile", while_);

			case 'f': if (scanner.current - scanner.start > 1) switch (scanner.start[1])
			{
				case 'a': return checkKeyword(2, "lse", false_);
				case 'o': return checkKeyword(2, "r", for_);
				case 'u': return checkKeyword(2, "n", fun);
				default:
			} break;

			case 't': if (scanner.current - scanner.start > 1) switch (scanner.start[1])
			{
				case 'h': return checkKeyword(2, "is", this_);
				case 'r': return checkKeyword(2, "ue", true_);
				default:
			} break;

			default:
		}

		return TokenType.identifier;
	}

	import std.ascii : isAlpha, isDigit;
	while (isAlpha(peek()) || isDigit(peek()) || peek() == '_') advance();
	return makeToken(identifierType());
}

private Token makeString()
{
	while (peek() != '"' && !isAtEnd())
	{
		if (peek() == '\n') scanner.line++;
		advance();
	}

	if (isAtEnd()) return errorToken!"Unterminated string."();

	// the closing quote
	advance();
	return makeToken(TokenType.string_);
}

private Token makeNumber()
{
	import std.ascii : isDigit;
	while (isDigit(peek())) advance();

	if (peek() == '.' && !isDigit(peekNext()))
	{
		advance();
		while (isDigit(peek())) advance();
	}

	return makeToken(TokenType.number);
}

private char advance()
{
	return *scanner.current++;
}

private char peek()
{
	return *scanner.current;
}

private char peekNext()
{
	if (isAtEnd()) return '\0';
	return scanner.current[1];
}

private bool match(in char expected)
{
	if (isAtEnd()) return false;
	if (*scanner.current != expected) return false;
	scanner.current++;
	return true;
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
