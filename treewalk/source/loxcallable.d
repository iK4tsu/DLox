module loxcallable;

import interpreter;
import std.variant;

interface LoxCallable
{
	int arity();
	Variant call(Interpreter interpreter, Variant[] arguments);
}
