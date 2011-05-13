package hxLINQ.macro;

import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;

class Helper {
	/*
	 * Store all ECall of a chained method call Expr into an Array.
	 */
	static public function toECallArray(expr:Expr, ?output:Array<Expr>):Array<Expr> {
		if (output == null) output = [];
		
		output.push(expr);
		switch(expr.expr) {
			case ECall(e, params): 
				switch(e.expr) {
					case EField(e, field):
						toECallArray(e, output);
					default:
				}
			default:
		}
		return output;
	}
	
	/*
	 * Get the method call name from a ECall. If the input is not a ECall(EField()), "" is returned.
	 */
	static public function getECallFieldName(expr:Expr):String {
		return switch (expr.expr) {
			case ECall(e, params): 
				switch(e.expr) {
					case EField(e, field): field;
					default: "";
				}
			default: "";
		}
	}
	
	static public function getECallParams(expr:Expr):Array<Expr> {
		return switch (expr.expr) {
			case ECall(e, params): params;
			default: null;
		}
	}
	
	/*
	 * Recursively search for EDisplay/EDisplayNew.
	 */
	static public function hasEDisplay(expr:Expr):Bool {
		return !traverse(expr, 
			function(e) return expr == null ? true : switch(e.expr) {
				case EDisplay(e, isCall): false;
				case EDisplayNew(t): false;
				default: true;
			});
	}
	
	/**
	 * Traverse the Expr recusively.
	 * @param	expr
	 * @param	callb				Accepts a Null<Expr> and return if the traversal should be continued.
	 * @param	?preorder = true	Should the traversal run in preorder or postorder.
	 * @return						Did the traversal reach the end, ie. hadn't stopped by callb.
	 */
	static public function traverse(expr:Null<Expr>, callb:Null<Expr>->Bool, ?preorder = true):Bool {
		return (preorder ? callb(expr) : true) && (expr == null ? true : switch (expr.expr) {
			case EConst(c): true;
			case EArray(e1, e2): traverse(e1,callb,preorder) && traverse(e2,callb,preorder);
			case EBinop(op, e1, e2): traverse(e1,callb,preorder) && traverse(e2,callb,preorder);
			case EField(e, field): traverse(e,callb,preorder);
			case EType(e, field): traverse(e,callb,preorder);
			case EParenthesis(e): traverse(e,callb,preorder);
			case EObjectDecl(fields): fields.foreach(function(f) return traverse(f.expr,callb,preorder));
			case EArrayDecl(values): values.foreach(function(v) return traverse(v,callb,preorder));
			case ECall(e, params): traverse(e,callb,preorder) && params.foreach(function(v) return traverse(v,callb,preorder));
			case ENew(t, params): params.foreach(function(v) return traverse(v,callb,preorder));
			case EUnop(p, postFix, e): traverse(e,callb,preorder);
			case EVars(vars): vars.foreach(function(v) return traverse(v.expr,callb,preorder));
			case EFunction(f): traverse(f.expr,callb,preorder);
			case EBlock(exprs): exprs.foreach(function(v) return traverse(v,callb,preorder));
			case EFor(v, it, expr): traverse(it,callb,preorder) && traverse(expr,callb,preorder);
			case EIf(econd, eif, eelse): traverse(econd,callb,preorder) && traverse(eif,callb,preorder) && traverse(eelse,callb,preorder);
			case EWhile(econd, e, normalWhile): traverse(econd,callb,preorder) && traverse(e,callb,preorder);
			case ESwitch(e, cases, edef): traverse(e,callb,preorder) && cases.foreach(function(c) return c.values.foreach(function(v) return traverse(v,callb,preorder)) && traverse(expr,callb,preorder)) && traverse(edef,callb,preorder);
			case ETry(e, catches): traverse(e,callb,preorder) && catches.foreach(function(c) return traverse(c.expr,callb,preorder));
			case EReturn(e): traverse(e,callb,preorder);
			case EBreak: true;
			case EContinue: true;
			case EUntyped(e): traverse(e,callb,preorder);
			case EThrow(e): traverse(e,callb,preorder);
			case ECast(e,t): traverse(e,callb,preorder);
			case EDisplay(e, isCall): traverse(e,callb,preorder);
			case EDisplayNew(t): true;
			case ETernary(econd, eif, eelse): traverse(econd,callb,preorder) && traverse(eif,callb,preorder) && traverse(eelse,callb,preorder);
		}) && (preorder ? true : callb(expr));
	}
}