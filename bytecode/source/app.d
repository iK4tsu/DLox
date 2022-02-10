module app;

extern(C) int main(int argc, char** argv)
{
	version(dlox_unittest)
	{
		import core.stdc.stdio : printf;
		import lox.dynamicarray;

		static foreach (unit; __traits(getUnitTests, lox.dynamicarray))
		{{
			unit();
			printf("%.*s -> passed\n", cast(int) __traits(identifier, unit).length, __traits(identifier, unit).ptr);
		}}
	}

	return 0;
}
