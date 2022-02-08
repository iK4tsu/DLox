module loxinstance;

import loxclass;
import runtimeerror;
import token;
import std.variant;

class LoxInstance
{
public:
	this(LoxClass klass) { this.klass = klass; }

	Variant get(Token name)
	{
		if (auto field = name.lexeme in fields) return *field;
		if (auto method = klass.findMethod(name.lexeme)) return Variant(method.bind(this));
		throw new RuntimeError(name, "Undefined property '" ~ name.lexeme ~ "'.");
	}

	void set(Token name, Variant value)
	{
		fields[name.lexeme] = value;
	}

	override string toString()
	{
		return klass.name ~ " instance";
	}

private:
	LoxClass klass;
	Variant[string] fields;
}
