module environment;

import token;
import runtimeerror;
import std.format : format;
import std.variant;

class Environment
{
public:
	this() {}
	this(Environment enclosing)
	{
		this.enclosing = enclosing;
	}

	Variant get(Token name)
	{
		if (auto value = name.lexeme in values) return *value;
		else if (enclosing) return enclosing.get(name);
		else throw new RuntimeError(name, "Undefined variable %s.".format(name.lexeme));
	}

	void assign(Token name, Variant rhs)
	{
		if (auto value = name.lexeme in values) *value = rhs;
		else if (enclosing) enclosing.assign(name, rhs);
		else throw new RuntimeError(name, "Undefined variable %s.".format(name.lexeme));
	}

	void define(string name, Variant value)
	{
		values[name] = value;
	}

	Variant getAt(size_t distance, string name)
	{
		return ancestor(distance).values[name];
	}

	void assignAt(size_t distance, Token name, Variant value)
	{
		ancestor(distance).values[name.lexeme] = value;
	}

	Environment ancestor(size_t distance)
	{
		Environment env = this;
		foreach (i; 0..distance)
		{
			env = env.enclosing;
		}
		return env;
	}

	Environment enclosing;

private:
	Variant[string] values;
}
