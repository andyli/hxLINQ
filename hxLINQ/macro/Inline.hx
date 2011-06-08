package hxLINQ.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import hxLINQ.macro.Helper;

using Lambda;

class Inline 
{
	@:macro static public function eFunctionToEBlock(e:Expr, ?arguments:ExprRequire<Array<Dynamic>>):Expr {
		var args = arguments == null ? [] : switch(arguments.expr) {
			case EArrayDecl(values): values;
			case EConst(c): 
				switch(c) { 
					case CIdent(s): 
						s == "null" ? [] : return throw "Needs arguments in [arg0, arg1, ...] form.";
					default:
						return throw "Needs arguments in [arg0, arg1, ...] form.";
				}
			default: return throw "Needs arguments in [arg0, arg1, ...] form.";
		}
		
		switch(e.expr) {
			case EFunction(name, f):
				if (isReturnVoid(e) && countEReturn(f.expr) == 0) return f.expr; 
				if (!isFinalReturn(f.expr)) return throw "Cannot inline a not final return.";
				
				if (f.args.length == 0) {
					return removeEReturn(f.expr);
				} else {
					var hasVarBeUsedTwice = false;
					var vars = [];
					for (i in 0...f.args.length) {
						var a = f.args[i];
						vars.push( { name:a.name, type:a.type, expr: i < args.length ? args[i] : a.value } );
						
						if (!hasVarBeUsedTwice && countIdent(f.expr, a.name) > 1) hasVarBeUsedTwice = true;
					}
					if (hasVarBeUsedTwice){
						return {
							expr:EBlock([
								{expr:EVars(vars), pos:e.pos },
								removeEReturn(f.expr)
							]),
							pos:e.pos
						}
					} else {
						var rExpr = removeEReturn(f.expr);
						for (i in 0...f.args.length) {
							var a = f.args[i];
							rExpr = replaceIdent(rExpr, a.name, vars[i].expr);
						}
						return rExpr;
					}
				}
			default: return throw "Accept EFunction only.";
		}
	}
	
	static public function isFinalReturn(expr:Null<Expr>):Bool {
		if (expr == null) return false;
		
		switch (expr.expr) {
			case EConst(c): 
				return false;
			case EArray(e1, e2): 
				return false;
			case EBinop(op, e1, e2): 
				return false;
			case EField(e, field): 
				return false;
			case EType(e, field): 
				return false;
			case EParenthesis(e): 
				return isFinalReturn(e);
			case EObjectDecl(fields):
				return false;
			case EArrayDecl(values):
				return false;
			case ECall(e, params):
				return false;
			case ENew(t, params):
				return false;
			case EUnop(p, postFix, e): 
				return false;
			case EVars(vars): 
				return false;
			case EFunction(n, f):
				return false;
			case EBlock(exprs):
				for (i in 0...exprs.length - 1) if (countEReturn(exprs[i]) > 0) return false;
				return isFinalReturn(exprs[exprs.length-1]);
			case EFor(v, it, expr):
				return false;
			case EIf(econd, eif, eelse):
				return isFinalReturn(eif) && isFinalReturn(eelse);
			case EWhile(econd, e, normalWhile):
				return false;
			case ESwitch(e, cases, edef):
				if (edef != null && !isFinalReturn(edef)) return false;
				for (c in cases) if (!isFinalReturn(c.expr)) return false;
				return true;
			case ETry(e, catches):
				return false; //TODO
			case EReturn(e):
				return countEReturn(e) == 0;
			case EBreak: 
				return false;
			case EContinue: 
				return false;
			case EUntyped(e): 
				return isFinalReturn(e);
			case EThrow(e):
				return false;
			case ECast(e, t):
				return false;
			case EDisplay(e, isCall):
				return false;
			case EDisplayNew(t):
				return false;
			case ETernary(econd, eif, eelse):
				return isFinalReturn(eif) && isFinalReturn(eelse);
		}
	}
	
	static public function replaceIdent(expr:Null<Expr>, find:String, replace:Null<Expr>):Null<Expr> {
		return Helper.reconstruct(expr, function(e,s) return e == null? null : switch (e.expr) {
			case EConst(c): 
				switch(c) {
					case CIdent(s): s == find ? replace : e;
					default: e;
				}
			default: e;
		});
	}
	
	static public function countIdent(expr:Null<Expr>, name:String):Int {
		var num = 0;
		Helper.traverse(expr, function(e,s) {
			if (e != null) switch(e.expr) {
				case EConst(c): 
					switch(c) {
						case CIdent(s):
							if (s == name) ++num;
						default:
					}
				default:
			}
			return TCContinue;
		});
		return num;
	}
	
	/*
	 * Count number of return expression. Does not count the ones inside a local function.
	 */
	static public function countEReturn(expr:Null<Expr>):Int {
		var num = 0;
		Helper.traverse(expr, function(e,s) {
			if (e != null) switch(e.expr) {
				case EReturn(e): ++num;
				case EFunction(name, f): return TCNoChildren;
				default:
			}
			return TCContinue;
		});
		return num;
	}
	
	static public function isReturnVoid(expr:Null<Expr>):Bool {
		#if macro
		try {
			switch (Context.typeof(expr)) {
				case TFun(args, ret):
					switch (ret) {
						case TEnum(t, params): if (t.get().name == "Void") return true;
						default:
					}
				default:
			}
		} catch (e:Dynamic) {}
		#end
		switch(expr.expr) {
			case EFunction(name, f):
				if (f.ret != null) switch(f.ret) {
					case TPath(p):
						if (p.name == "Void" && p.pack.length == 0) return true;
					default:
				}
			default: return throw "Not a function.";
		}
		return false;
	}
	
	/*
	 * Return a new Expr that all EReturn is removed.
	 */
	static public function removeEReturn(expr:Null<Expr>):Null<Expr> {
		return Helper.reconstruct( expr, 
			function(e, s) {
				//check if it is inside a function or not
				if (s.exists(function (es) return es == null ? false : switch(es.expr) { case EFunction(_, _):true; default:false; } ))
					return e;
				else
					return e == null ? null : switch (e.expr) {
						case EReturn(re):
							re == null ? { expr:EConst(CIdent("null")), pos:e.pos } : re;
						default: e;
					}
			}
		);
	}
}