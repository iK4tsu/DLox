module astprinter;

import std.conv : to;
import std.format : format;
import std.variant;
import expr;

/*
/+
The AstPrinter was dropped from the implementation.
So I'm just commenting all of this code so that I do not keep getting compilation
errors for not implementing the visitors for the new expressions
+/

class AstPrinter : Expr.Visitor
{
public:
	string print(Expr expr) { return expr.accept(this).toString(); }

	override Variant visitAssignExpr(Expr.Assign expr) { with(expr) return parenthesize("=", value).to!Variant; }
	override Variant visitBinaryExpr(Expr.Binary expr) { with(expr) return parenthesize(operator.lexeme, left, right).to!Variant; }
	override Variant visitCallExpr(Expr.Call expr) { with(expr) return parenthesize(callee.to!(Expr.Variable).name.lexeme, arguments).to!Variant; }
	override Variant visitGetExpr(Expr.Get expr) { with(expr) return parenthesize(name.lexeme, object).to!Variant; }
	override Variant visitGroupingExpr(Expr.Grouping expr) { with(expr) return parenthesize("group", expression).to!Variant; }
	override Variant visitLiteralExpr(Expr.Literal expr) { with(expr) return value.toString.to!Variant; }
	override Variant visitLogicalExpr(Expr.Logical expr) { with(expr) return parenthesize(operator.lexeme, left, right).to!Variant; }
	override Variant visitSetExpr(Expr.Set expr) { with(expr) return parenthesize(name.lexeme, object).to!Variant; }
	override Variant visitUnaryExpr(Expr.Unary expr) { with(expr) return parenthesize(operator.lexeme, right).to!Variant; }
	override Variant visitVariableExpr(Expr.Variable expr) { with(expr) return name.lexeme.to!Variant; }

private:
	string parenthesize(string name, Expr[] exprs...)
	{
		string str = format!"(%s"(name);

		foreach (expr; exprs)
		{
			str ~= format!" %s"(expr.accept(this));
		}

		return str ~ ')';
	}
}
*/
