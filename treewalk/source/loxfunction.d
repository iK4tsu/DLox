module loxfunction;

import environment;
import interpreter;
import loxcallable;
import loxinstance;
import stmt;
import std.conv;
import std.format;
import std.variant;

class LoxFunction : LoxCallable
{
public:
	this(Stmt.Function declaration, Environment closure, bool isInitializer)
	{
		this.declaration = declaration;
		this.closure = closure;
		this.isInitializer = isInitializer;
	}

	LoxFunction bind(LoxInstance instance)
	{
		Environment environment = new Environment(closure);
		environment.define("this", Variant(instance));
		return new LoxFunction(declaration, environment, isInitializer);
	}

	override Variant call(Interpreter interpreter, Variant[] arguments)
	{
		Environment environment = new Environment(closure);
		foreach (i, argument; arguments)
		{
			environment.define(declaration.params[i].lexeme, argument);
		}

		import returnexception;
		try
		{
			interpreter.executeBlock(declaration.body, environment);
		}
		catch (ReturnException returnValue)
		{
			if (isInitializer) return closure.getAt(0, "this");
			return Variant(returnValue.value);
		}

		if (isInitializer) return closure.getAt(0, "this");
		return Variant(null);
	}

	override int arity()
	{
		return declaration.params.length.to!int;
	}

	override string toString()
	{
		return declaration.name.lexeme.format!"<fn %s>";
	}

private:
	Stmt.Function declaration;
	Environment closure;
	bool isInitializer;
}
