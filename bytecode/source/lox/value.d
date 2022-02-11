module lox.value;

struct Value
{
	@trusted nothrow @nogc
	void print() scope
	{
		import core.stdc.stdio : printf;
		printf("%g", value);
	}

	double value;
	alias value this;
}
