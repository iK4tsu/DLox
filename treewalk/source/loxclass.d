module loxclass;

import interpreter;
import loxinstance;
import loxcallable;
import loxfunction;
import std.variant;

class LoxClass : LoxCallable
{
public:
	this(string name, LoxClass superclass, LoxFunction[string] methods)
	{
		this.name = name;
		this.methods = methods;
		this.superclass = superclass;
	}

	LoxFunction findMethod(string name)
	{
		if (auto fun = name in methods) return *fun;
		if (superclass) return superclass.findMethod(name);
		return null;
	}

	override Variant call(Interpreter interpreter, Variant[] arguments)
	{
		LoxInstance instance = new LoxInstance(this);
		LoxFunction initializer = findMethod("init");

		if (initializer) initializer.bind(instance).call(interpreter, arguments);

		return Variant(instance);
	}

	override int arity()
	{
		LoxFunction initializer = findMethod("init");
		if (!initializer) return 0;
		return initializer.arity();
	}

	override string toString() const
	{
		return name;
	}

	string name;
	LoxFunction[string] methods;
	LoxClass superclass;
}
