module stmt;
import expr;
import token;
import std.variant;

abstract class Stmt
{
public:
	interface Visitor
	{
		Variant visitPrintStmt(Print);
		Variant visitExpressionStmt(Expression);
		Variant visitFunctionStmt(Function);
		Variant visitReturnStmt(Return);
		Variant visitIfStmt(If);
		Variant visitClassStmt(Class);
		Variant visitBlockStmt(Block);
		Variant visitVarStmt(Var);
		Variant visitWhileStmt(While);
	}

	static class Print : Stmt
	{
	public:
		// constructor
		this(Expr expression)
		{
			this.expression = expression;
		}

		override Variant accept(Visitor visitor) { return visitor.visitPrintStmt(this); }

		Expr expression;
	}

	static class Expression : Stmt
	{
	public:
		// constructor
		this(Expr expression)
		{
			this.expression = expression;
		}

		override Variant accept(Visitor visitor) { return visitor.visitExpressionStmt(this); }

		Expr expression;
	}

	static class Function : Stmt
	{
	public:
		// constructor
		this(Token name, Token[] params, Stmt[] body)
		{
			this.name = name;
			this.params = params;
			this.body = body;
		}

		override Variant accept(Visitor visitor) { return visitor.visitFunctionStmt(this); }

		Token name;
		Token[] params;
		Stmt[] body;
	}

	static class Return : Stmt
	{
	public:
		// constructor
		this(Token keyword, Expr value)
		{
			this.keyword = keyword;
			this.value = value;
		}

		override Variant accept(Visitor visitor) { return visitor.visitReturnStmt(this); }

		Token keyword;
		Expr value;
	}

	static class If : Stmt
	{
	public:
		// constructor
		this(Expr condition, Stmt thenBranch, Stmt elseBranch)
		{
			this.condition = condition;
			this.thenBranch = thenBranch;
			this.elseBranch = elseBranch;
		}

		override Variant accept(Visitor visitor) { return visitor.visitIfStmt(this); }

		Expr condition;
		Stmt thenBranch;
		Stmt elseBranch;
	}

	static class Class : Stmt
	{
	public:
		// constructor
		this(Token name, Expr.Variable superclass, Function[] methods)
		{
			this.name = name;
			this.superclass = superclass;
			this.methods = methods;
		}

		override Variant accept(Visitor visitor) { return visitor.visitClassStmt(this); }

		Token name;
		Expr.Variable superclass;
		Function[] methods;
	}

	static class Block : Stmt
	{
	public:
		// constructor
		this(Stmt[] statements)
		{
			this.statements = statements;
		}

		override Variant accept(Visitor visitor) { return visitor.visitBlockStmt(this); }

		Stmt[] statements;
	}

	static class Var : Stmt
	{
	public:
		// constructor
		this(Token name, Expr initializer)
		{
			this.name = name;
			this.initializer = initializer;
		}

		override Variant accept(Visitor visitor) { return visitor.visitVarStmt(this); }

		Token name;
		Expr initializer;
	}

	static class While : Stmt
	{
	public:
		// constructor
		this(Expr condition, Stmt body)
		{
			this.condition = condition;
			this.body = body;
		}

		override Variant accept(Visitor visitor) { return visitor.visitWhileStmt(this); }

		Expr condition;
		Stmt body;
	}

	abstract Variant accept(Visitor);
}
