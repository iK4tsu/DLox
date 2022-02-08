module runtimeerror;

import token;

class RuntimeError : Exception
{
public:
	this(Token token, string msg)
	{
		super(msg);
		this.token = token;
	}

	immutable Token token;
}
