package hxLINQ.macro;

import haxe.macro.Expr;

class Inline 
{
	@:macro static public function eFunctionToEBlock(e:Expr):Expr {
		switch(e.expr) {
			case EFunction(name, f):
				if (countEReturn(e) != 1) return throw "Function should have 1 return.";
				
				if (f.args.length == 0) {
					return removeEReturn(f.expr);
				} else {
					var vars = [];
					for (a in f.args) vars.push({ name:a.name, type:a.type, expr:a.value });
					return {
						expr:EBlock([
							{expr:EVars(vars), pos:e.pos },
							removeEReturn(f.expr)
						]),
						pos:e.pos
					}
				}
			default: return throw "Accept EFunction only.";
		}
	}
	
	static public function countEReturn(expr:Null<Expr>):Int {
		var num = 0;
		Helper.traverse(expr, function(e) {
			if (e != null) switch(e.expr) {
				case EReturn(e): ++num;
				default:
			}
			return true;
		});
		return num;
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
				{ expr:ENew(Reflect.copy(t),newparams), pos:expr.pos };
			case EUnop(p, postFix, e): 
				{ expr:EUnop(p, postFix, removeEReturn(e)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:Reflect.copy(v.type), expr:removeEReturn(v.expr) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: Reflect.copy(f.ret),
					expr: removeEReturn(f.expr),
					params: []
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:removeEReturn(a.value) } );
				for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in newexprs) newexprs.push(removeEReturn(e));
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
				removeEReturn(e);
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