#!/usr/bin/env rdmd

module tools.generateast;

void main(string[] args)
{
	if (args.length < 2)
	{
		import std.stdio;
		stderr.writeln("Usage: generate-ast <path>");
		return;
	}

	defineAst(args[1], "Expr", [
		"Assign"   : ["Token name", "Expr value"],
		"Binary"   : ["Expr left", "Token operator", "Expr right"],
		"Call"     : ["Expr callee", "Token paren", "Expr[] arguments"],
		"Get"      : ["Expr object", "Token name" ],
		"Grouping" : ["Expr expression"],
		"Literal"  : ["typeof(Token.literal) value"],
		"Logical"  : ["Expr left", "Token operator", "Expr right"],
		"Set"      : ["Expr object", "Token name", "Expr value"],
		"Super"    : ["Token keyword", "Token method"],
		"This"     : ["Token keyword"],
		"Unary"    : ["Token operator", "Expr right"],
		"Variable" : ["Token name"],
	]);

	defineAst(args[1], "Stmt", [
		"Block"      : ["Stmt[] statements"],
		"Class"      : ["Token name", "Expr.Variable superclass", "Function[] methods"],
		"Expression" : ["Expr expression"],
		"Function"   : ["Token name", "Token[] params", "Stmt[] body"],
		"If"         : ["Expr condition", "Stmt thenBranch", "Stmt elseBranch"],
		"Print"      : ["Expr expression"],
		"Return"     : ["Token keyword", "Expr value"],
		"Var"        : ["Token name", "Expr initializer"],
		"While"      : ["Expr condition", "Stmt body"],
	]);
}

void defineAst(string path, string base, string[][string] derivatives)
{
	import std.array : join, split, back;
	import std.file : write;
	import std.format : format;
	import std.path : buildPath;
	import std.range : repeat;
	import std.string;

	auto filepath = path.buildPath(base.toLower()~".d");

	auto genDerivatives = {
		auto fieldHelper = (string[] fields, bool ctor) {
			import std.range : repeat;
			string str;
			foreach (field; fields)
			{
				if (ctor)
					str ~= q{this.%s = %s;
					}.format(field.split(' ').back, field.split(' ').back);
				else
					str ~= q{%s;
					}.format(field).chop();
			}
			return str.stripRight();
		};

		string str;
		foreach (name, fields; derivatives)
		{
			str ~= q{
			static class %s : %s
			{
			public:
				// constructor
				this(%s)
				{
					%s
				}

				override Variant accept(Visitor visitor) { return visitor.visit%s%s(this); }

				%s
			}
		}.format(
				name, base, fields.join(", "),
				fieldHelper(fields, true).stripLeft(),
				name, base,
				fieldHelper(fields, false).stripLeft()
			);
		}
		return str.strip();
	};

	auto genVisitors = () {
		string str;
		foreach (name, fields; derivatives)
		{
			str ~= q{
				Variant visit%s%s(%s);
			}.format(name, base, name).stripRight();
		}
		return str.strip();
	};

	filepath.write(q{
		module %s;
		%s
		import token;
		import std.variant;

		abstract class %s
		{
		public:
			interface Visitor
			{
				%s
			}

			%s

			abstract Variant accept(Visitor);
		}
	}.format(
		base.toLower(),
		(base == "Expr" ? "" : "import expr;"),
		base,
		genVisitors(),
		genDerivatives()
	).outdent.stripLeft());
}
