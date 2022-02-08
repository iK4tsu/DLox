module token;

struct Token
{
	import std.sumtype;
	import tokentype;
	this(T)(TokenType type, string lexeme, T literal, size_t line)
	{
		this.type = type;
		this.lexeme = lexeme;
		this.literal = literal;
		this.line = line;
	}

	TokenType type;
	string lexeme;
	SumType!(double, string, typeof(null), bool) literal;
	size_t line;
}
