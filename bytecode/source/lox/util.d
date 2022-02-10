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


/// a type that can either hold something or nothing
alias Optional(T) = SumType!(None, Some!T);

/// a type that holds nothing
struct None {}

/// helper that creates a 'None'
enum none(T) = Optional!T.init;

/// a type that holds something
struct Some(T) { T value; alias value this; }

/// helper that creates a 'Some'
Optional!T some(T)(T value) { return Optional!T(Some!T(value)); }
