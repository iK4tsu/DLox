module parser;

import expr;
import stmt;
import token;
import tokentype;
import std.conv : to;
import std.format;

class ParseError : Exception
{
	import std.exception : basicExceptionCtors;
	mixin basicExceptionCtors;
}

class Parser
{
public:
	this(Token[] tokens)
	{
		this.tokens = tokens;
	}

	Stmt[] parse()
	{
		Stmt[] statements;
		while (!atEnd()) statements ~= declaration();
		return statements;
	}

private:
	Expr expression()
	{
		return assignment();
	}

	Stmt declaration()
	{
		with (TokenType) try {
			if (match(class_)) return classDeclaration();
			if (match(fun)) return this.fun("function");
			if (match(var)) return varDeclaration();
			else return statement();
		}
		catch (ParseError)
		{
			synchronize();
			return null;
		}
	}

	Stmt.Class classDeclaration()
	{
		with (TokenType)
		{
			Token name = consume(identifier, "Expect class name.");

			Expr.Variable superclass;
			if (match(less))
			{
				consume(identifier, "Expect superclass name.");
				superclass = new Expr.Variable(previous());
			}

			consume(left_brace, "Expect '{' before class body.");

			Stmt.Function[] methods;
			while (!check(right_brace) && !atEnd()) methods ~= this.fun("method");

			consume(right_brace, "Expect '}' after class body.");

			return new Stmt.Class(name, superclass, methods);
		}
	}

	Stmt.Function fun(string kind)
	{
		with (TokenType)
		{
			Token name = consume(identifier, kind.format!"Expect %s name.");
			consume(left_paren, kind.format!"Expect '(' after %s name.");
			Token[] parameters;
			if (!check(right_paren)) do
			{
				if (parameters.length >= 255) error(peek(), "Can't more than 255 parameters.");
				parameters ~= consume(identifier, "Expect parameter name.");
			} while (match(comma));
			consume(right_paren, "Expect ')' after parameters.");
			consume(left_brace, kind.format!"Expect '{' before %s body");
			Stmt[] body = block();
			return new Stmt.Function(name, parameters, body);
		}
	}

	Stmt varDeclaration()
	{
		with (TokenType)
		{
			Token name = consume(identifier, "Expect variable name.");
			Expr initializer;
			if (match(equal)) initializer = expression();
			consume(semicolon, "Expect ';' after variable declaration");
			return new Stmt.Var(name, initializer);
		}
	}

	Stmt statement()
	{
		with (TokenType)
		{
			if (match(if_)) return ifStatement();
			if (match(for_)) return forStatement();
			if (match(while_)) return whileStatement();
			if (match(print)) return printStatement();
			if (match(return_)) return returnStatement();
			if (match(left_brace)) return new Stmt.Block(block());
			return expressionStatement();
		}
	}

	Stmt ifStatement()
	{
		with (TokenType)
		{
			consume(left_paren, "Expect '(' after 'if'.");
			Expr condition = expression();
			consume(right_paren, "Expect ')' after 'if' condition.");

			Stmt thenBranch = statement();
			Stmt elseBranch;
			if (match(else_)) elseBranch = statement();

			return new Stmt.If(condition, thenBranch, elseBranch);
		}
	}

	Stmt forStatement()
	{
		with (TokenType)
		{
			consume(left_paren, "Expect '(' after 'if'.");
			Stmt initializer;
			if (match(var)) initializer = varDeclaration();
			else if (!match(semicolon)) initializer = expressionStatement();

			Expr condition;
			if (!check(semicolon)) condition = expression();
			consume(semicolon, "Expect ';' after loop condition.");

			Expr increment;
			if (!check(right_paren)) increment = expression();
			consume(right_paren, "Expect ')' after for clauses.");

			Stmt bodyBranch = statement();

			if (increment) bodyBranch = new Stmt.Block([bodyBranch, new Stmt.Expression(increment)]);
			if (!condition) condition = new Expr.Literal(true.to!(typeof(Token.literal)));
			bodyBranch = new Stmt.While(condition, bodyBranch);
			if (initializer) bodyBranch = new Stmt.Block([initializer, bodyBranch]);

			return bodyBranch;
		}
	}

	Stmt whileStatement()
	{
		with (TokenType)
		{
			consume(left_paren, "Expect '(' after 'while'.");
			Expr condition = expression();
			consume(right_paren, "Expect ')' after 'while' condition.");

			return new Stmt.While(condition, statement());
		}
	}

	Stmt printStatement()
	{
		Expr value = expression();
		consume(TokenType.semicolon, "Expect ';' after value.");
		return new Stmt.Print(value);
	}

	Stmt returnStatement()
	{
		Token keyword = previous();
		Expr value = !check(TokenType.semicolon) ? expression() : null;
		consume(TokenType.semicolon, "Expect ';' after return value.");
		return new Stmt.Return(keyword, value);
	}

	Stmt expressionStatement()
	{
		Expr expr = expression();
		consume(TokenType.semicolon, "Expect ';' after expression.");
		return new Stmt.Expression(expr);
	}

	Stmt[] block()
	{
		with (TokenType)
		{
			Stmt[] statements;
			while (!check(right_brace) && !atEnd()) statements ~= declaration();
			consume(right_brace, "Expect '}' after after block.");
			return statements;
		}
	}

	Expr assignment()
	{
		Expr expr = or();
		if (match(TokenType.equal))
		{
			Token equals = previous();
			Expr value = assignment();

			if (auto var = cast(Expr.Variable) expr)
			{
				Token name = var.name;
				return new Expr.Assign(name, value);
			}
			else if (auto get = cast(Expr.Get) expr)
			{
				return new Expr.Set(get.object, get.name, value);
			}

			error(equals, "Invalid assignment target.");
		}

		return expr;
	}

	Expr or()
	{
		Expr expr = and();

		while (match(TokenType.or))
		{
			Token operator = previous();
			Expr right = and();
			expr = new Expr.Logical(expr, operator, right);
		}

		return expr;
	}

	Expr and()
	{
		Expr expr = equality();

		while (match(TokenType.and))
		{
			Token operator = previous();
			Expr right = equality();
			expr = new Expr.Logical(expr, operator, right);
		}

		return expr;
	}

	Expr equality()
	{
		Expr expr = comparison();
		with (TokenType) while (match(bang_equal, equal_equal))
		{
			Token operator = previous();
			Expr right = comparison();
			expr = new Expr.Binary(expr, operator, right);
		}

		return expr;
	}

	Expr comparison()
	{
		Expr expr = term();
		with (TokenType) while (match(greater, greater_equal, less, less_equal))
		{
			Token operator = previous();
			Expr right = term();
			expr = new Expr.Binary(expr, operator, right);
		}

		return expr;
	}

	Expr term()
	{
		Expr expr = factor();
		with (TokenType) while (match(minus, plus))
		{
			Token operator = previous();
			Expr right = factor();
			expr = new Expr.Binary(expr, operator, right);
		}

		return expr;
	}

	Expr factor()
	{
		Expr expr = unary();
		with (TokenType) while (match(slash, star))
		{
			Token operator = previous();
			Expr right = unary();
			expr = new Expr.Binary(expr, operator, right);
		}

		return expr;
	}

	Expr unary()
	{
		with (TokenType) if (match(bang, minus)) {
			Token operator = previous();
			Expr right = unary();
			return new Expr.Unary(operator, right);
		}

		return call();
	}

	Expr call()
	{
		Expr expr = primary();

		while (true) with (TokenType)
		{
			if (match(left_paren)) expr = finishCall(expr);
			else if (match(dot))
			{
				Token name = consume(identifier, "Expect property name after '.'.");
				expr = new Expr.Get(expr, name);
			}
			else break;
		}

		return expr;
	}

	Expr finishCall(Expr callee)
	{
		Expr[] arguments;

		with (TokenType)
		{
			if (!check(right_paren)) do
			{
				if (arguments.length >= 255) error(peek(), "Can't have more than 255 arguments.");
				arguments ~= expression();
			} while (match(comma));

			Token paren = consume(right_paren, "Expect ')' after arguments.");

			return new Expr.Call(callee, paren, arguments);
		}
	}

	Expr primary()
	{
		with (TokenType)
		{
			import std.conv : to;
			if (match(false_)) return new Expr.Literal(false.to!(typeof(Token.literal)));
			if (match(true_)) return new Expr.Literal(true.to!(typeof(Token.literal)));
			if (match(nil)) return new Expr.Literal(null.to!(typeof(Token.literal)));
			if (match(number, string_)) return new Expr.Literal(previous.literal);
			if (match(super_))
			{
				Token keyword = previous();
				consume(dot, "Expect '.' after super.");
				Token method = consume(identifier, "Expect superclass method name.");
				return new Expr.Super(keyword, method);
			}
			if (match(this_)) return new Expr.This(previous());
			if (match(identifier)) return new Expr.Variable(previous());
			if (match(left_paren))
			{
				Expr expr = expression();
				consume(right_paren, "Expect ')' after expression.");
				return new Expr.Grouping(expr);
			}
		}

		throw error(peek(), "Expect expression.");
	}

	bool match(TokenType[] types...)
	{
		foreach (type; types) if (check(type))
		{
			advance();
			return true;
		}

		return false;
	}

	Token consume(TokenType type, string message)
	{
		import lox;
		if (check(type)) return advance();
		throw error(peek(), message);
	}

	bool check(TokenType type)
	{
		return atEnd() ? false : peek.type == type;
	}

	Token advance()
	{
		if (!atEnd()) current++;
		return previous();
	}

	bool atEnd() { with (TokenType) return peek.type == eof; }
	Token peek() { return tokens[current]; }
	Token previous() { return tokens[current-1]; }

	ParseError error(Token token, string message)
	{
		import lox;
		Lox.error(token, message);
		return new ParseError("");
	}

	void synchronize()
	{
		advance();
		while (!atEnd()) with (TokenType)
		{
			if (previous.type == semicolon) return;
			switch (peek.type)
			{
				case class_:
				case for_:
				case fun:
				case if_:
				case print:
				case return_:
				case var:
				case while_: return;
				default:
			}
			advance();
		}
	}

	Token[] tokens;
	size_t current;
}
