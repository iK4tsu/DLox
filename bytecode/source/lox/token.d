module lox.token;

struct Token
{
	import lox.tokentype;

	TokenType type;
	const(char)* start;
	size_t length;
	size_t line;
}
