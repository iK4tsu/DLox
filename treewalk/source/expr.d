module expr;

import token;
import std.variant;

abstract class Expr
{
public:
	interface Visitor
	{
		Variant visitGroupingExpr(Grouping);
		Variant visitUnaryExpr(Unary);
		Variant visitThisExpr(This);
		Variant visitLogicalExpr(Logical);
		Variant visitVariableExpr(Variable);
		Variant visitGetExpr(Get);
		Variant visitAssignExpr(Assign);
		Variant visitSuperExpr(Super);
		Variant visitCallExpr(Call);
		Variant visitSetExpr(Set);
		Variant visitLiteralExpr(Literal);
		Variant visitBinaryExpr(Binary);
	}

	static class Grouping : Expr
	{
	public:
		// constructor
		this(Expr expression)
		{
			this.expression = expression;
		}

		override Variant accept(Visitor visitor) { return visitor.visitGroupingExpr(this); }

		Expr expression;
	}

	static class Unary : Expr
	{
	public:
		// constructor
		this(Token operator, Expr right)
		{
			this.operator = operator;
			this.right = right;
		}

		override Variant accept(Visitor visitor) { return visitor.visitUnaryExpr(this); }

		Token operator;
		Expr right;
	}

	static class This : Expr
	{
	public:
		// constructor
		this(Token keyword)
		{
			this.keyword = keyword;
		}

		override Variant accept(Visitor visitor) { return visitor.visitThisExpr(this); }

		Token keyword;
	}

	static class Logical : Expr
	{
	public:
		// constructor
		this(Expr left, Token operator, Expr right)
		{
			this.left = left;
			this.operator = operator;
			this.right = right;
		}

		override Variant accept(Visitor visitor) { return visitor.visitLogicalExpr(this); }

		Expr left;
		Token operator;
		Expr right;
	}

	static class Variable : Expr
	{
	public:
		// constructor
		this(Token name)
		{
			this.name = name;
		}

		override Variant accept(Visitor visitor) { return visitor.visitVariableExpr(this); }

		Token name;
	}

	static class Get : Expr
	{
	public:
		// constructor
		this(Expr object, Token name)
		{
			this.object = object;
			this.name = name;
		}

		override Variant accept(Visitor visitor) { return visitor.visitGetExpr(this); }

		Expr object;
		Token name;
	}

	static class Assign : Expr
	{
	public:
		// constructor
		this(Token name, Expr value)
		{
			this.name = name;
			this.value = value;
		}

		override Variant accept(Visitor visitor) { return visitor.visitAssignExpr(this); }

		Token name;
		Expr value;
	}

	static class Super : Expr
	{
	public:
		// constructor
		this(Token keyword, Token method)
		{
			this.keyword = keyword;
			this.method = method;
		}

		override Variant accept(Visitor visitor) { return visitor.visitSuperExpr(this); }

		Token keyword;
		Token method;
	}

	static class Call : Expr
	{
	public:
		// constructor
		this(Expr callee, Token paren, Expr[] arguments)
		{
			this.callee = callee;
			this.paren = paren;
			this.arguments = arguments;
		}

		override Variant accept(Visitor visitor) { return visitor.visitCallExpr(this); }

		Expr callee;
		Token paren;
		Expr[] arguments;
	}

	static class Set : Expr
	{
	public:
		// constructor
		this(Expr object, Token name, Expr value)
		{
			this.object = object;
			this.name = name;
			this.value = value;
		}

		override Variant accept(Visitor visitor) { return visitor.visitSetExpr(this); }

		Expr object;
		Token name;
		Expr value;
	}

	static class Literal : Expr
	{
	public:
		// constructor
		this(typeof(Token.literal) value)
		{
			this.value = value;
		}

		override Variant accept(Visitor visitor) { return visitor.visitLiteralExpr(this); }

		typeof(Token.literal) value;
	}

	static class Binary : Expr
	{
	public:
		// constructor
		this(Expr left, Token operator, Expr right)
		{
			this.left = left;
			this.operator = operator;
			this.right = right;
		}

		override Variant accept(Visitor visitor) { return visitor.visitBinaryExpr(this); }

		Expr left;
		Token operator;
		Expr right;
	}

	abstract Variant accept(Visitor);
}
