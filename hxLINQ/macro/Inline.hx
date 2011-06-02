package hxLINQ.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import hxLINQ.macro.Helper;

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
		return expr == null? null : switch (expr.expr) {
			case EConst(c): 
				switch(c) {
					case CIdent(s):
						s == find ? replace : { expr:EConst(c), pos:expr.pos };
					default:
						{ expr:EConst(c), pos:expr.pos };
				}
			case EArray(e1, e2): 
				{ expr:EArray(replaceIdent(e1, find, replace), replaceIdent(e2, find, replace)), pos:expr.pos };
			case EBinop(op, e1, e2): 
				{ expr:EBinop(op, replaceIdent(e1, find, replace), replaceIdent(e2, find, replace)), pos:expr.pos };
			case EField(e, field): 
				{ expr:EField(replaceIdent(e, find, replace), field), pos:expr.pos };
			case EType(e, field): 
				{ expr:EType(replaceIdent(e, find, replace), field), pos:expr.pos };
			case EParenthesis(e): 
				{ expr:EParenthesis(replaceIdent(e, find, replace)), pos:expr.pos };
			case EObjectDecl(fields):
				var newfields = [];
				for (f in fields) newfields.push({ field:f.field, expr:replaceIdent(f.expr, find, replace) });
				{ expr:EObjectDecl(newfields), pos:expr.pos };
			case EArrayDecl(values):
				var newvalues = [];
				for (v in values) newvalues.push(replaceIdent(v, find, replace));
				{ expr:EArrayDecl(newvalues), pos:expr.pos };
			case ECall(e, params):
				var newparams = [];
				for (p in params) newparams.push(replaceIdent(p, find, replace));
				{ expr:ECall(replaceIdent(e, find, replace),newparams), pos:expr.pos };
			case ENew(t, params):
				var newparams = [];
				for (p in params) newparams.push(replaceIdent(p, find, replace));
				var newt = {
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.copy(),
					sub: t.sub
				}
				{ expr:ENew(newt,newparams), pos:expr.pos };
			case EUnop(p, postFix, e): 
				{ expr:EUnop(p, postFix, replaceIdent(e, find, replace)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:v.type, expr:replaceIdent(v.expr, find, replace) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: f.ret,
					expr: f.expr,
					params: []
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:replaceIdent(a.value, find, replace) } );
				for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in exprs) newexprs.push(replaceIdent(e, find, replace));
				{ expr:EBlock(newexprs), pos:expr.pos };
			case EFor(v, it, expr):
				{ expr:EFor(v, replaceIdent(it, find, replace), replaceIdent(expr, find, replace)), pos:expr.pos };
			case EIf(econd, eif, eelse):
				{ expr:EIf(replaceIdent(econd, find, replace), replaceIdent(eif, find, replace), replaceIdent(eelse, find, replace)), pos:expr.pos };
			case EWhile(econd, e, normalWhile):
				{ expr:EWhile(replaceIdent(econd, find, replace), replaceIdent(e, find, replace), normalWhile), pos:expr.pos };
			case ESwitch(e, cases, edef):
				var newcases = [];
				for (c in cases) {
					var newvalues = [];
					for (v in c.values) newvalues.push(replaceIdent(v, find, replace));
					newcases.push( { values:newvalues, expr:replaceIdent(c.expr, find, replace) } );
				}
				{ expr:ESwitch(replaceIdent(e, find, replace), newcases, replaceIdent(edef, find, replace)), pos:expr.pos };
			case ETry(e, catches):
				var newcatches = [];
				for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:replaceIdent(c.expr, find, replace) } );
				{ expr:ETry(replaceIdent(e, find, replace), newcatches), pos:expr.pos };
			case EReturn(e):
				e == null ? { expr:EConst(CIdent("null")), pos:expr.pos } : replaceIdent(e, find, replace);
			case EBreak: 
				{ expr:EBreak, pos:expr.pos };
			case EContinue: 
				{ expr:EContinue, pos:expr.pos };
			case EUntyped(e): 
				{ expr:EUntyped(replaceIdent(e, find, replace)), pos:expr.pos };
			case EThrow(e):
				{ expr:EThrow(replaceIdent(e, find, replace)), pos:expr.pos };
			case ECast(e, t):
				{ expr:ECast(replaceIdent(e, find, replace), t), pos:expr.pos };
			case EDisplay(e, isCall):
				{ expr:EDisplay(replaceIdent(e, find, replace), isCall), pos:expr.pos };
			case EDisplayNew(t):
				{ expr:EDisplayNew(t), pos:expr.pos };
			case ETernary(econd, eif, eelse):
				{ expr:ETernary(replaceIdent(econd, find, replace), replaceIdent(eif, find, replace), replaceIdent(eelse, find, replace)), pos:expr.pos };
		}
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
		return expr == null? null : switch (expr.expr) {
			case EConst(c): 
				{ expr:EConst(c), pos:expr.pos };
			case EArray(e1, e2): 
				{ expr:EArray(removeEReturn(e1), removeEReturn(e2)), pos:expr.pos };
			case EBinop(op, e1, e2): 
				{ expr:EBinop(op, removeEReturn(e1), removeEReturn(e2)), pos:expr.pos };
			case EField(e, field): 
				{ expr:EField(removeEReturn(e), field), pos:expr.pos };
			case EType(e, field): 
				{ expr:EType(removeEReturn(e), field), pos:expr.pos };
			case EParenthesis(e): 
				{ expr:EParenthesis(removeEReturn(e)), pos:expr.pos };
			case EObjectDecl(fields):
				var newfields = [];
				for (f in fields) newfields.push({ field:f.field, expr:removeEReturn(f.expr) });
				{ expr:EObjectDecl(newfields), pos:expr.pos };
			case EArrayDecl(values):
				var newvalues = [];
				for (v in values) newvalues.push(removeEReturn(v));
				{ expr:EArrayDecl(newvalues), pos:expr.pos };
			case ECall(e, params):
				var newparams = [];
				for (p in params) newparams.push(removeEReturn(p));
				{ expr:ECall(removeEReturn(e),newparams), pos:expr.pos };
			case ENew(t, params):
				var newparams = [];
				for (p in params) newparams.push(removeEReturn(p));
				var newt = {
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.copy(),
					sub: t.sub
				}
				{ expr:ENew(newt,newparams), pos:expr.pos };
			case EUnop(p, postFix, e): 
				{ expr:EUnop(p, postFix, removeEReturn(e)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:v.type, expr:removeEReturn(v.expr) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: f.ret,
					expr: f.expr,
					params: []
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:removeEReturn(a.value) } );
				for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in exprs) newexprs.push(removeEReturn(e));
				{ expr:EBlock(newexprs), pos:expr.pos };
			case EFor(v, it, expr):
				{ expr:EFor(v, removeEReturn(it), removeEReturn(expr)), pos:expr.pos };
			case EIf(econd, eif, eelse):
				{ expr:EIf(removeEReturn(econd), removeEReturn(eif), removeEReturn(eelse)), pos:expr.pos };
			case EWhile(econd, e, normalWhile):
				{ expr:EWhile(removeEReturn(econd), removeEReturn(e), normalWhile), pos:expr.pos };
			case ESwitch(e, cases, edef):
				var newcases = [];
				for (c in cases) {
					var newvalues = [];
					for (v in c.values) newvalues.push(removeEReturn(v));
					newcases.push( { values:newvalues, expr:removeEReturn(c.expr) } );
				}
				{ expr:ESwitch(removeEReturn(e), newcases, removeEReturn(edef)), pos:expr.pos };
			case ETry(e, catches):
				var newcatches = [];
				for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:removeEReturn(c.expr) } );
				{ expr:ETry(removeEReturn(e), newcatches), pos:expr.pos };
			case EReturn(e):
				e == null ? { expr:EConst(CIdent("null")), pos:expr.pos } : removeEReturn(e);
			case EBreak: 
				{ expr:EBreak, pos:expr.pos };
			case EContinue: 
				{ expr:EContinue, pos:expr.pos };
			case EUntyped(e): 
				{ expr:EUntyped(removeEReturn(e)), pos:expr.pos };
			case EThrow(e):
				{ expr:EThrow(removeEReturn(e)), pos:expr.pos };
			case ECast(e, t):
				{ expr:ECast(removeEReturn(e), t), pos:expr.pos };
			case EDisplay(e, isCall):
				{ expr:EDisplay(removeEReturn(e), isCall), pos:expr.pos };
			case EDisplayNew(t):
				{ expr:EDisplayNew(t), pos:expr.pos };
			case ETernary(econd, eif, eelse):
				{ expr:ETernary(removeEReturn(econd), removeEReturn(eif), removeEReturn(eelse)), pos:expr.pos };
		}
	}
}