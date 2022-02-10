module lox.util;

import std.sumtype;
import std.traits : isDelegate, isFunctionPointer;


/**
Entrusts fake purity to a function.

Params:
  t = delegate or function pointer to purify.

Returns: the new function with it's attributes updated to be pure.
*/
auto assumePure(T)(T t)
	if (isFunctionPointer!T || isDelegate!T)
{
	import std.traits : FunctionAttribute, functionAttributes, functionLinkage, SetFunctionAttributes;

	enum attrs = functionAttributes!T | FunctionAttribute.pure_;
	return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}
