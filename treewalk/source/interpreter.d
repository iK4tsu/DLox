module interpreter;

import std.conv : to;
import std.format : format;
import std.stdio : writeln;
import std.sumtype : match;
import std.variant;
import environment;
import expr;
import lox;
import loxcallable;
import loxclass;
import loxfunction;
import loxinstance;
import runtimeerror;
import stmt;
import token;
import tokentype;

class Interpreter : Expr.Visitor, Stmt.Visitor
{
public:
	this()
	{
		this.globals = new Environment();
		this.environment = globals;

		globals.define("clock", Variant(new class LoxCallable {
			override int arity() { return 0; }
			override Variant call(Interpreter interpreter, Variant[] arguments)
			{
				import std.datetime.systime;
				return Clock.currTime.toUnixTime.to!double.to!Variant;
			}

			override string toString() { return "<native fn>"; }
		}));
	}

	void interpret(Stmt[] statements)
	{
		try {
			foreach (statement; statements) execute(statement);
		} catch (RuntimeError e) {
			Lox.runtimeError(e);
		}
	}

	override Variant visitGroupingExpr(Expr.Grouping expr) { return evaluate(expr.expression); }
	override Variant visitLiteralExpr(Expr.Literal expr) { return expr.value.match!(to!Variant); }
	override Variant visitUnaryExpr(Expr.Unary expr)
	{
		Variant right = evaluate(expr.right);
		switch (expr.operator.type) with (TokenType)
		{
			case bang: return Variant(!truthy(right));
			case minus:
				checkNumberOperand(expr.operator, right);
				return Variant(-right.get!double);
			default: return Variant(null);
		}
	}

	override Variant visitBinaryExpr(Expr.Binary expr)
	{
		Variant left = evaluate(expr.left);
		Variant right = evaluate(expr.right);
		switch (expr.operator.type) with (TokenType)
		{
			case bang_equal: return Variant(left != right);
			case equal_equal: return Variant(left == right);

			case greater:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double >  right.get!double);

			case greater_equal:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double >= right.get!double);

			case less:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double <  right.get!double);

			case less_equal:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double <= right.get!double);

			case minus:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double -  right.get!double);

			case plus:
				if (left.type is typeid(double) && right.type is typeid(double))
					return Variant(left.get!double + right.get!double);

				if (left.type is typeid(string) && right.type is typeid(string))
					return Variant(left.get!string ~ right.get!string);

				throw new RuntimeError(expr.operator, "Both operands must be strings or numbers.");

			case slash:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double / right.get!double);

			case star:
				checkNumberOperand(expr.operator, left, right);
				return Variant(left.get!double * right.get!double);

			default: return Variant(null);
		}
	}

	override Variant visitVariableExpr(Expr.Variable expr)
	{
		return lookUpVariable(expr.name, expr);
	}

	override Variant visitAssignExpr(Expr.Assign expr)
	{
		Variant value = evaluate(expr.value);
		if (auto dist = expr in locals) environment.assignAt(*dist, expr.name, value);
		else globals.assign(expr.name, value);
		return value;
	}

	override Variant visitLogicalExpr(Expr.Logical expr)
	{
		Variant left = evaluate(expr.left);
		if (expr.operator.type == TokenType.or)
		{
			if (truthy(left)) return left;
		}
		else // and operator
		{
			if (!truthy(left)) return left;
		}

		// if or is false on the left side
		// if and is true on the left side
		return evaluate(expr.right);
	}

	override Variant visitSetExpr(Expr.Set expr)
	{
		Variant object = evaluate(expr.object);

		if (!object.convertsTo!LoxInstance) throw new RuntimeError(expr.name, "Only instances have fields.");

		Variant value = evaluate(expr.value);
		object.get!LoxInstance.set(expr.name, value);

		return value;
	}

	override Variant visitSuperExpr(Expr.Super expr)
	{
		size_t distance = locals[expr];
		LoxClass superclass = environment.getAt(distance, "super").get!LoxClass;
		LoxInstance object = environment.getAt(distance - 1, "this").get!LoxInstance;
		LoxFunction method = superclass.findMethod(expr.method.lexeme);
		if (!method) throw new RuntimeError(expr.method, format!"Undefined property '%s'."(expr.method.lexeme));
		return Variant(method.bind(object));
	}

	override Variant visitThisExpr(Expr.This expr)
	{
		return lookUpVariable(expr.keyword, expr);
	}

	override Variant visitCallExpr(Expr.Call expr)
	{
		Variant callee = evaluate(expr.callee);

		Variant[] arguments;
		foreach (argument; expr.arguments) arguments ~= evaluate(argument);

		if (!callee.convertsTo!LoxCallable) throw new RuntimeError(expr.paren, "Can only call functions and classes.");
		LoxCallable loxFunction = callee.get!LoxCallable;
		if (arguments.length != loxFunction.arity()) throw new RuntimeError(
			expr.paren, format!"Expected %s arguments but got %s"(
				loxFunction.arity(),
				arguments.length,
			)
		);
		return loxFunction.call(this, arguments);
	}

	override Variant visitGetExpr(Expr.Get expr)
	{
		Variant object = evaluate(expr.object);
		if (object.convertsTo!LoxInstance) return object.get!LoxInstance.get(expr.name);
		throw new RuntimeError(expr.name, "Only instances have properties.");
	}

	override Variant visitExpressionStmt(Stmt.Expression stmt)
	{
		evaluate(stmt.expression);
		return Variant(null);
	}

	override Variant visitPrintStmt(Stmt.Print stmt)
	{
		Variant value = evaluate(stmt.expression);
		stringify(value).writeln;
		return Variant(null);
	}

	override Variant visitVarStmt(Stmt.Var stmt)
	{
		Variant value = stmt.initializer ? evaluate(stmt.initializer) : Variant(null);
		environment.define(stmt.name.lexeme, value);
		return Variant(null);
	}

	override Variant visitBlockStmt(Stmt.Block stmt)
	{
		executeBlock(stmt.statements, new Environment(environment));
		return Variant(null);
	}

	override Variant visitClassStmt(Stmt.Class stmt)
	{
		LoxClass superclass;

		if (stmt.superclass)
		{
			auto superclass_ = evaluate(stmt.superclass);
			if (!superclass_.convertsTo!LoxClass)
				throw new RuntimeError(stmt.superclass.name, "SuperClass must be a class.");
			superclass = superclass_.get!LoxClass;
		}

		environment.define(stmt.name.lexeme, Variant(null));

		if (stmt.superclass)
		{
			environment = new Environment(environment);
			environment.define("super", Variant(superclass));
		}

		LoxFunction[string] methods;
		foreach (method; stmt.methods)
		{
			auto fun = new LoxFunction(method, environment, method.name.lexeme == "init");
			methods[method.name.lexeme] = fun;
		}
		LoxClass klass = new LoxClass(stmt.name.lexeme, superclass, methods);

		if (stmt.superclass) environment = environment.enclosing;

		environment.assign(stmt.name, Variant(klass));
		return Variant(null);
	}

	override Variant visitIfStmt(Stmt.If stmt)
	{
		if (truthy(evaluate(stmt.condition))) execute(stmt.thenBranch);
		else if (stmt.elseBranch) execute(stmt.elseBranch);
		return Variant(null);
	}

	override Variant visitWhileStmt(Stmt.While stmt)
	{
		while (truthy(evaluate(stmt.condition))) execute(stmt.body);
		return Variant(null);
	}

	override Variant visitFunctionStmt(Stmt.Function stmt)
	{
		LoxFunction fun = new LoxFunction(stmt, environment, false);
		environment.define(stmt.name.lexeme, fun.to!Variant);
		return Variant(null);
	}

	override Variant visitReturnStmt(Stmt.Return stmt)
	{
		import returnexception;
		Variant value = stmt.value ? evaluate(stmt.value).to!Variant : null.to!Variant;
		throw new ReturnException(value);
	}

private:
	void checkNumberOperand(Token operator, Variant operand)
	{
		if (operand.type !is typeid(double)) throw new RuntimeError(operator, "Operand must be a number.");
	}

	void checkNumberOperand(Token operator, Variant left, Variant right)
	{
		import std.algorithm : any;
		import std.range : only;
		if (only(left,right).any!"a.type !is typeid(double)") throw new RuntimeError(operator, "Operands must be numbers.");
	}

	Variant evaluate(Expr expr) { return expr.accept(this); }

	bool truthy(Variant variant)
	{
		if (variant == null) return false;
		if (variant.type is typeid(bool)) return variant.get!bool;
		return true;
	}

	void execute(Stmt stmt)
	{
		stmt.accept(this);
	}

	public void resolve(Expr expr, size_t depth)
	{
		locals[expr] = depth;
	}

	public void executeBlock(Stmt[] statements, Environment environment)
	{
		Environment previous = this.environment;
		try
		{
			this.environment = environment;
			foreach (stmt; statements) execute(stmt);
		}
		finally
		{
			this.environment = previous;
		}
	}

	string stringify(Variant variant)
	{
		if (variant.type is typeid(null)) return "nil";
		if (variant.type is typeid(double))
		{
			import std.string : endsWith;
			string ret = variant.toString();
			if (ret.endsWith(".0")) ret = ret[0..$-2];
			return ret;
		}

		return variant.toString();
	}

	Variant lookUpVariable(Token name, Expr expr)
	{
		if (auto dist = expr in locals) return environment.getAt(*dist, name.lexeme);
		else return globals.get(name);
	}

	public Environment globals;
	Environment environment;
	size_t[Expr] locals;
}
