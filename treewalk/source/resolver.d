module resolver;

import expr;
import interpreter;
import lox;
import stmt;
import token;
import std.container;
import std.range;
import std.variant;

class Resolver : Expr.Visitor, Stmt.Visitor
{
public:
	this(Interpreter interpreter)
	{
		this.interpreter = interpreter;
	}

	void resolve(Stmt[] statements)
	{
		foreach (statement; statements)
		{
			resolve(statement);
		}
	}

	override Variant visitBlockStmt(Stmt.Block stmt)
	{
		beginScope();
		resolve(stmt.statements);
		endScope();
		return Variant(null);
	}

	override Variant visitClassStmt(Stmt.Class stmt)
	{
		ClassType enclosingClass = currentClass;
		currentClass = ClassType.class_;
		scope(exit) currentClass = enclosingClass;

		declare(stmt.name);
		define(stmt.name);

		if (stmt.superclass)
		{
			if (stmt.superclass.name.lexeme == stmt.name.lexeme)
				Lox.error(stmt.superclass.name, "A class can't inherit from itself.");

			currentClass = ClassType.subclass;

			resolve(stmt.superclass);
			beginScope();
			scopes.back["super"] = true;
		}

		beginScope();
		scopes.back["this"] = true;
		scope(exit) endScope();

		foreach (method; stmt.methods)
		{
			auto declaration = method.name.lexeme == "init"
				? FunctionType.initializer
				: FunctionType.method;
			resolveFunction(method, declaration);
		}

		if (stmt.superclass) endScope();

		return Variant(null);
	}

	override Variant visitExpressionStmt(Stmt.Expression stmt)
	{
		resolve(stmt.expression);
		return Variant(null);
	}

	override Variant visitFunctionStmt(Stmt.Function stmt)
	{
		declare(stmt.name);
		define(stmt.name);
		resolveFunction(stmt, FunctionType.fun);
		return Variant(null);
	}

	override Variant visitIfStmt(Stmt.If stmt)
	{
		resolve(stmt.condition);
		resolve(stmt.thenBranch);
		if (stmt.elseBranch) resolve(stmt.elseBranch);
		return Variant(null);
	}

	override Variant visitPrintStmt(Stmt.Print stmt)
	{
		resolve(stmt.expression);
		return Variant(null);
	}

	override Variant visitReturnStmt(Stmt.Return stmt)
	{
		if (currentFunction == FunctionType.none) Lox.error(stmt.keyword, "Can't return from top-level code.");
		if (stmt.value)
		{
			if (currentFunction == FunctionType.initializer) Lox.error(stmt.keyword, "Can't return a value from an initializer.");
			resolve(stmt.value);
		}
		return Variant(null);
	}

	override Variant visitVarStmt(Stmt.Var stmt)
	{
		declare(stmt.name);
		if (stmt.initializer) resolve(stmt.initializer);
		define(stmt.name);
		return Variant(null);
	}

	override Variant visitWhileStmt(Stmt.While stmt)
	{
		resolve(stmt.condition);
		resolve(stmt.body);
		return Variant(null);
	}

	override Variant visitVariableExpr(Expr.Variable expr)
	{
		if (!scopes.empty && expr.name.lexeme in scopes.back &&  scopes.back[expr.name.lexeme] == false)
		{
			Lox.error(expr.name, "Can't read local variable in it's initializer.");
		}

		resolveLocal(expr, expr.name);
		return Variant(null);
	}

	override Variant visitAssignExpr(Expr.Assign expr)
	{
		resolve(expr.value);
		resolveLocal(expr, expr.name);
		return Variant(null);
	}

	override Variant visitBinaryExpr(Expr.Binary expr)
	{
		resolve(expr.left);
		resolve(expr.right);
		return Variant(null);
	}

	override Variant visitCallExpr(Expr.Call expr)
	{
		resolve(expr.callee);
		foreach (arg; expr.arguments) resolve(arg);
		return Variant(null);
	}

	override Variant visitGetExpr(Expr.Get expr)
	{
		resolve(expr.object);
		return Variant(null);
	}

	override Variant visitGroupingExpr(Expr.Grouping expr)
	{
		resolve(expr.expression);
		return Variant(null);
	}

	override Variant visitLiteralExpr(Expr.Literal expr)
	{
		return Variant(null);
	}

	override Variant visitLogicalExpr(Expr.Logical expr)
	{
		resolve(expr.left);
		resolve(expr.right);
		return Variant(null);
	}

	override Variant visitSetExpr(Expr.Set expr)
	{
		resolve(expr.value);
		resolve(expr.object);
		return Variant(null);
	}

	override Variant visitSuperExpr(Expr.Super expr)
	{
		with (ClassType)
		{
			if (currentClass == none) Lox.error(expr.keyword, "Can't use 'super' outside of a class.");
			else if (currentClass != subclass) Lox.error(expr.keyword, "Can't use 'super' in a class with no SuperClass.");
			resolveLocal(expr, expr.keyword);
			return Variant(null);
		}
	}

	override Variant visitThisExpr(Expr.This expr)
	{
		if (currentClass == ClassType.none)
		{
			Lox.error(expr.keyword, "Can't use 'this' outside of a class.");
			return Variant(null);
		}

		resolveLocal(expr, expr.keyword);
		return Variant(null);
	}

	override Variant visitUnaryExpr(Expr.Unary expr)
	{
		resolve(expr.right);
		return Variant(null);
	}

private:
	void resolve(Stmt stmt)
	{
		stmt.accept(this);
	}

	void resolve(Expr expr)
	{
		expr.accept(this);
	}

	void resolveFunction(Stmt.Function fun, FunctionType type)
	{
		FunctionType enclosingFunction = currentFunction;
		currentFunction = type;
		scope(exit) currentFunction = enclosingFunction;

		beginScope();
		foreach (param; fun.params)
		{
			declare(param);
			define(param);
		}
		resolve(fun.body);
		endScope();
	}

	void beginScope()
	{
		scopes ~= (bool[string]).init;
	}

	void endScope()
	{
		scopes.popBack();
	}

	void declare(Token name)
	{
		if (scopes.empty) return;

		/**
		Atention: this does not account for inner scopes of a scope!
		Lox does not implement this but if same named variables declared in same
		scope are not allowed then it should extend to inner scopes, IMO

		{
			var a;
			{
				var a; // should not be allowed
			}
		}

		This is simple, just verify all scopes back to front instead of back only

		Resolving the above brings another tricky case, same named variables are
		not allowed in inner scopes even if declared inside a function! Well,
		this can be argued, but I think it should be allowed

		{
			var a;
			fun foo()
			{
				var a; // allowed
				{
					var a; // not allowed shadows foo.a
				}
			}
		}

		To solve this, the easiest way is to add another variable to the Resolver
		that stores the index of the last function created. That is our break
		point when searching for variable declarations. We can still access them
		directly if there isn't a variable with same name declared in the function.

		{
			var a;
			fun foo()
			{
				var b = a; // access outer a --> var a = a should work too
				var a; // declare foo.a
			}
		}
		*/
		if (name.lexeme in scopes.back) Lox.error(name, "Already a variable with this name in this scope.");
		scopes.back[name.lexeme] = false;
	}

	void define(Token name)
	{
		if (scopes.empty) return;

		scopes.back[name.lexeme] = true;
	}

	void resolveLocal(Expr expr, Token name)
	{
		foreach_reverse (i, scp; scopes)
		{
			if (name.lexeme in scp)
			{
				interpreter.resolve(expr, scopes.length - 1 - i);
				return;
			}
		}
	}

	enum FunctionType { none, fun, initializer, method }
	enum ClassType { none, class_, subclass }

	Interpreter interpreter;
	bool[string][] scopes; // used as a stack
	FunctionType currentFunction = FunctionType.none;
	ClassType currentClass = ClassType.none;
}
