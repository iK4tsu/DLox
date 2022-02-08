module scanner;

import std.ascii : isAlpha, isAlphaNum, isDigit;
import app;

class Scanner
{
	import token;
	import tokentype;
public:
	this(string source)
	{
		this.source = source;
	}

	Token[] scanTokens()
	{
		while (!over())
		{
			start = current;
			scanToken();
		}

		tokens ~= Token(TokenType.eof, "", "", line);
		return tokens;
	}

	void scanToken()
	{
		char c = advance();
		switch (c) with (TokenType)
		{
			case '(': addToken(left_paren); break;
			case ')': addToken(right_paren); break;
			case '{': addToken(left_brace); break;
			case '}': addToken(right_brace); break;
			case ',': addToken(comma); break;
			case '.': addToken(dot); break;
			case '-': addToken(minus); break;
			case '+': addToken(plus); break;
			case ';': addToken(semicolon); break;
			case '*': addToken(star); break;
			case '!': addToken(match('=') ? bang_equal : bang); break;
			case '=': addToken(match('=') ? equal_equal : equal); break;
			case '<': addToken(match('=') ? less_equal : less); break;
			case '>': addToken(match('=') ? greater_equal : greater); break;
			case '/':
				if (match('/'))
					while (peek() != '\n' && !over()) advance();
				else
					addToken(slash);
				break;

			case ' ':
			case '\r':
			case '\t': break;

			case '\n': line++; break;

			case '"': scanString(); break;

			default:
				if (c.isDigit()) // [0-9]
				{
					scanNumber();
				}
				else if (c.isAlpha() || c == '_') // [_a-zA-Z]
				{
					scanIdentifier();
				}
				else
				{
					import lox;
					Lox.error(line, "Unexpected character.");
				}
				break;
		}
	}

	void scanIdentifier()
	{
		while (peek.isAlphaNum() || peek() == '_') advance(); // [_a-zA-Z0-9]

		TokenType* p = source[start..current] in keywords;
		addToken(p ? *p : TokenType.identifier);
	}

	void scanNumber()
	{
		while (peek.isDigit()) advance();

		if (peek() == '.' && peekNext.isDigit())
		{
			advance();
			while (peek.isDigit()) advance();
		}

		import std.conv : to;
		addToken(TokenType.number, source[start..current].to!double);
	}

	void scanString()
	{
		while (peek() != '"' && !over())
		{
			if (peek() == '\n') line++;
			advance();
		}

		if (over())
		{
			import lox;
			Lox.error(line, "Unterminated string.");
			return;
		}

		advance();
		addToken(TokenType.string_, source[start+1..current-1]);
	}

	bool match(char expected)
	{
		if (over()) return false;
		if (peek() != expected) return false;

		advance();
		return true;
	}

	char peek()
	{
		if (over()) return '\0';
		else return source[current];
	}

	char peekNext()
	{
		if (current + 1 >= source.length) return '\0';
		else return source[current + 1];
	}

	bool over() { return current >= source.length; }

	char advance() { return source[current++]; }
	void addToken(TokenType type) { addToken(type, ""); }
	void addToken(T)(TokenType type, T literal)
	{
		tokens ~= Token(type, source[start..current], literal, line);
	}

private:
	string source;
	Token[] tokens;
	size_t start;
	size_t current;
	size_t line = 1;
}

private enum keywords = () {
	import tokentype;
	with (TokenType) return [
		"and"    : and,
		"class"  : class_,
		"else"   : else_,
		"false"  : false_,
		"for"    : for_,
		"fun"    : fun,
		"if"     : if_,
		"nil"    : nil,
		"or"     : or,
		"print"  : print,
		"return" : return_,
		"super"  : super_,
		"this"   : this_,
		"true"   : true_,
		"var"    : var,
		"while"  : while_
	];
} ();
