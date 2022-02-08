module returnexception;

import std.variant;

class ReturnException : Exception
{
public:
	this(Variant value)
	{
		super("");
		this.value = value;
	}

	Variant value;
}
