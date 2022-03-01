module lox.tokentype;

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
