package hxLINQ.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;

enum TraverseControl {
	TCExit;
	TCNoChildren;
	TCContinue;
}

class Helper {
	/**
	 * Traverse the Expr recusively.
	 * @param	expr
	 * @param	callb				Accepts a Null<Expr> and a stack(List<Expr> using push/pop, first is current), return true if the traversal should be continued.
	 * @param	?preorder = true	Should the traversal run in preorder or postorder.
	 * @return						Did the traversal reach the end, ie. hadn't stopped by TCExit.
	 */
	static public function traverse(expr:Null<Expr>, callb:Null<Expr>->List<Expr>->TraverseControl, ?preorder:Bool = true, ?stack:List<Expr>):Bool {
		if (stack == null) stack = new List();
		stack.push(expr);
		
		var ret:Bool;
		try {
			ret = 
				(preorder ? switch (callb(expr,stack)) {
						case TCContinue: true;
						case TCNoChildren: throw TCNoChildren;
						case TCExit: false;
					} : true) 
				&& (expr == null ? true : switch (expr.expr) {
						case EConst(c): true;
						case EArray(e1, e2): traverse(e1,callb,preorder,stack) && traverse(e2,callb,preorder,stack);
						case EBinop(op, e1, e2): traverse(e1,callb,preorder,stack) && traverse(e2,callb,preorder,stack);
						case EField(e, field): traverse(e,callb,preorder,stack);
						case EType(e, field): traverse(e,callb,preorder,stack);
						case EParenthesis(e): traverse(e,callb,preorder,stack);
						case EObjectDecl(fields): fields.foreach(function(f) return traverse(f.expr,callb,preorder,stack));
						case EArrayDecl(values): values.foreach(function(v) return traverse(v,callb,preorder,stack));
						case ECall(e, params): traverse(e,callb,preorder,stack) && params.foreach(function(v) return traverse(v,callb,preorder,stack));
						case ENew(t, params): params.foreach(function(v) return traverse(v,callb,preorder,stack));
						case EUnop(p, postFix, e): traverse(e,callb,preorder,stack);
						case EVars(vars): vars.foreach(function(v) return traverse(v.expr,callb,preorder,stack));
						case EFunction(n, f): traverse(f.expr, callb, preorder) && f.args.foreach(function(a) return traverse(a.value, callb, preorder));
						case EBlock(exprs): exprs.foreach(function(v) return traverse(v,callb,preorder,stack));
						case EFor(v, it, expr): traverse(it,callb,preorder,stack) && traverse(expr,callb,preorder,stack);
						case EIf(econd, eif, eelse): traverse(econd,callb,preorder,stack) && traverse(eif,callb,preorder,stack) && traverse(eelse,callb,preorder,stack);
						case EWhile(econd, e, normalWhile): traverse(econd,callb,preorder,stack) && traverse(e,callb,preorder,stack);
						case ESwitch(e, cases, edef): traverse(e,callb,preorder,stack) && cases.foreach(function(c) return c.values.foreach(function(v) return traverse(v,callb,preorder,stack)) && traverse(c.expr,callb,preorder,stack)) && traverse(edef,callb,preorder,stack);
						case ETry(e, catches): traverse(e,callb,preorder,stack) && catches.foreach(function(c) return traverse(c.expr,callb,preorder,stack));
						case EReturn(e): traverse(e,callb,preorder,stack);
						case EBreak: true;
						case EContinue: true;
						case EUntyped(e): traverse(e,callb,preorder,stack);
						case EThrow(e): traverse(e,callb,preorder,stack);
						case ECast(e,t): traverse(e,callb,preorder,stack);
						case EDisplay(e, isCall): traverse(e,callb,preorder,stack);
						case EDisplayNew(t): true;
						case ETernary(econd, eif, eelse): traverse(econd,callb,preorder,stack) && traverse(eif,callb,preorder,stack) && traverse(eelse,callb,preorder,stack);
					}) 
				&& (preorder ? true : switch (callb(expr,stack)) {
						case TCContinue: true;
						case TCExit: false;
						case TCNoChildren: throw #if debug "TCNoChildren has no effect on postorder traversal." #else TCNoChildren #end ;
					});
		} catch (tc:TraverseControl) {
			ret = switch(tc) {
				case TCNoChildren: true;
				default: throw tc;
			}
		}
		
		stack.pop();
		return ret;
	}
	
	/*
	 * Store all ECall of a chained method call Expr into an Array.
	 */
	static public function toECallArray(expr:Expr, ?output:Array<Expr>):Array<Expr> {
		if (output == null) output = [];
		
		switch(expr.expr) {
			case ECall(e, params): 
				switch(e.expr) {
					case EField(e, field):
						toECallArray(e, output);
					default:
				}
			default:
		}
		output.push(expr);
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
			function(e,s) return expr == null ? TCContinue : switch(e.expr) {
				case EDisplay(_,_), EDisplayNew(_): TCExit;
				default: TCContinue;
			});
	}
	
	/*
	 * Deep clone an Expr.
	 */
	static public function clone(expr:Null<Expr>):Null<Expr> {
		return expr == null? null : switch (expr.expr) {
			case EConst(c): 
				{ expr:EConst(c), pos:expr.pos };
			case EArray(e1, e2): 
				{ expr:EArray(clone(e1), clone(e2)), pos:expr.pos };
			case EBinop(op, e1, e2): 
				{ expr:EBinop(op, clone(e1), clone(e2)), pos:expr.pos };
			case EField(e, field): 
				{ expr:EField(clone(e), field), pos:expr.pos };
			case EType(e, field): 
				{ expr:EType(clone(e), field), pos:expr.pos };
			case EParenthesis(e): 
				{ expr:EParenthesis(clone(e)), pos:expr.pos };
			case EObjectDecl(fields):
				var newfields = [];
				for (f in fields) newfields.push({ field:f.field, expr:clone(f.expr) });
				{ expr:EObjectDecl(newfields), pos:expr.pos };
			case EArrayDecl(values):
				var newvalues = [];
				for (v in values) newvalues.push(clone(v));
				{ expr:EArrayDecl(newvalues), pos:expr.pos };
			case ECall(e, params):
				var newparams = [];
				for (p in params) newparams.push(clone(p));
				{ expr:ECall(clone(e),newparams), pos:expr.pos };
			case ENew(t, params):
				var newparams = [];
				for (p in params) newparams.push(clone(p));
				var newt = {
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.copy(),
					sub: t.sub
				}
				{ expr:ENew(newt,newparams), pos:expr.pos };
			case EUnop(p, postFix, e): 
				{ expr:EUnop(p, postFix, clone(e)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:v.type, expr:clone(v.expr) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: f.ret,
					expr: clone(f.expr),
					params: []
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:clone(a.value) } );
				for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in newexprs) newexprs.push(clone(e));
				{ expr:EBlock(newexprs), pos:expr.pos };
			case EFor(v, it, expr):
				{ expr:EFor(v, clone(it), clone(expr)), pos:expr.pos };
			case EIf(econd, eif, eelse):
				{ expr:EIf(clone(econd), clone(eif), clone(eelse)), pos:expr.pos };
			case EWhile(econd, e, normalWhile):
				{ expr:EWhile(clone(econd), clone(e), normalWhile), pos:expr.pos };
			case ESwitch(e, cases, edef):
				var newcases = [];
				for (c in cases) {
					var newvalues = [];
					for (v in c.values) newvalues.push(clone(v));
					newcases.push( { values:newvalues, expr:clone(c.expr) } );
				}
				{ expr:ESwitch(clone(e), newcases, clone(edef)), pos:expr.pos };
			case ETry(e, catches):
				var newcatches = [];
				for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:clone(c.expr) } );
				{ expr:ETry(clone(e), newcatches), pos:expr.pos };
			case EReturn(e):
				{ expr:EReturn(clone(e)), pos:expr.pos };
			case EBreak: 
				{ expr:EBreak, pos:expr.pos };
			case EContinue: 
				{ expr:EContinue, pos:expr.pos };
			case EUntyped(e): 
				{ expr:EUntyped(clone(e)), pos:expr.pos };
			case EThrow(e):
				{ expr:EThrow(clone(e)), pos:expr.pos };
			case ECast(e, t):
				{ expr:ECast(clone(e), t), pos:expr.pos };
			case EDisplay(e, isCall):
				{ expr:EDisplay(clone(e), isCall), pos:expr.pos };
			case EDisplayNew(t):
				{ expr:EDisplayNew(t), pos:expr.pos };
			case ETernary(econd, eif, eelse):
				{ expr:ETernary(clone(econd), clone(eif), clone(eelse)), pos:expr.pos };
		}
	}
	
	#if macro
	/**
	 * Get Type of a ComplexType.
	 * @param	com
	 * @param	pos		Default to Context.currentPos().
	 * @return			Type of the ComplexType.
	 */
	static public function toType(com:ComplexType, ?pos:Position):Type {
		if (pos == null) pos = Context.currentPos();
		//{var $testType:{{com}}; testType;}
		var testType = { expr:EBlock([ { expr:EVars( [ { name: "$testType", type: com, expr: null } ] ), pos:pos }, { expr:EConst(CIdent("$testType")), pos:pos } ]), pos:pos };
		return Context.typeof(testType);
	}
	
	static public function getItrItemType(dataType:Type, ?pos:Position):Type {
		if (pos == null) pos = Context.currentPos();
		
		//{var $testType:{{dataType}}; testType;}.next()
		return Context.typeof( 
			{ 
				expr: ECall( 
					{ 
						expr: EField(
							{
								expr: EBlock([ 
									{ 
										expr:EVars( [ { name: "$testType", type: toComplexType(dataType), expr: null } ] ), 
										pos:pos 
									}, 
									{ 
										expr:EConst(CIdent("$testType")), 
										pos:pos 
									}
								]), 
								pos: pos 
							}, 
							"next"
						), 
						pos: pos 
					},
					[]
				), 
				pos:pos
			}
		);
	}
	
	static public function getItrblItemType(dataType:Type, ?pos:Position):Type {
		if (pos == null) pos = Context.currentPos();
		
		//{var $testType:{{dataType}}; testType;}.iterator().next()
		return Context.typeof( 
			{ 
				expr:ECall( 
					{ 
						expr: EField(
							{ 
								expr: ECall( 
									{ 
										expr: EField(
											{ 
												expr: EBlock([ 
													{ 
														expr:EVars( [ { name: "$testType", type: toComplexType(dataType), expr: null } ] ), 
														pos:pos 
													}, 
													{ 
														expr:EConst(CIdent("$testType")), 
														pos:pos 
													}
												]), 
												pos: pos 
											}, 
											"iterator"
										), 
										pos: pos 
									},
									[]
								), 
								pos:pos
							}, 
							"next"
						), 
						pos: pos
					},
					[]
				),
				pos:pos
			}
		);
	}
	
	/*
	 * Get I from a LINQ Expr
	 */
	public static function getItemType<D,I>(linq:ExprRequire<LINQ<D,I>>) {
		return switch(Context.follow(Context.typeof(linq))) { case TInst(t, params): params[1]; default: throw "linq should be TInst(LINQ,[...])"; }
	}
	
	/*
	 * Get D from a LINQ Expr
	 */
	public static function getDataType<D,I>(linq:ExprRequire<LINQ<D,I>>) {
		return switch(Context.follow(Context.typeof(linq))) { case TInst(t, params): params[0]; default: throw "linq should be TInst(LINQ,[...])"; }
	}
	#end
	
	public static function getFullyQualifiedName(type:BaseType):String {
		return type.pack.join(".") + (type.pack.length > 0 ? "." : "") + type.name;
    }
	
	/*
	 * Turns a Type into a ComplexType.
	 * TODO: TAnonymous is not supported yet.
	 */
	static public function toComplexType(t:Null<Type>):Null<ComplexType> {
		var ct = t == null ? null : switch(t) {
			case TMono: 
				null;
			case TEnum(t, params):
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.exists(function(p) return toComplexType(p) == null) ? [] : params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TInst(t, params):
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.exists(function(p) return toComplexType(p) == null) ? [] : params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TType(t, params): 
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.exists(function(p) return toComplexType(p) == null) ? [] : params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TFun(args, ret): 
				TFunction( args.exists(function(a) return toComplexType(a.t) == null) ? [] : args.map(function(a) return toComplexType(a.t)).array(), toComplexType(ret) );
			case TAnonymous(a): //TODO
				/*
					var a:{
						private var a:Int;
						public var b(default,null):Int;
						var c:Int;
						public function d(dd:Int):String;
					};
					
					//TAnonymous
					{ 
						fields: 
						[ 
							{ 
								type: TInst(Int, []), 
								name: a, 
								params: [], 
								expr: null, 
								kind: FVar(AccNormal, AccNormal), 
								pos: pos, 
								meta: { remove: #function:1, add: #function:3, has: #function:1, get: #function:0 }, 
								isPublic: false 
							}, 
							{ 
								type: TInst(Int, []), 
								name: b, 
								params: [], 
								expr: null, 
								kind: FVar(AccNormal, AccNo), 
								pos: pos, 
								meta: { remove: #function:1, add: #function:3, has: #function:1, get: #function:0 }, 
								isPublic: true }, 
							{ 
								type: TInst(Int, []), 
								name: c, 
								params: [], 
								expr: null, 
								kind: FVar(AccNormal, AccNormal), 
								pos: pos, 
								meta: { remove: #function:1, add: #function:3, has: #function:1, get: #function:0 }, 
								isPublic: true 
							},
							{ 
								type: TFun([ { opt: false, name: dd, t: TInst(Int, []) } ], TInst(String, [])), 
								name: d, 
								params: [], 
								expr: null, 
								kind: FMethod(MethNormal), 
								pos: pos, 
								meta: { remove: #function:1, add: #function:3, has: #function:1, get: #function:0 }, 
								isPublic: true 
							}
						]
					}
				*
				TAnonymous( a.get().fields.map(
					function(cf:ClassField):haxe.macro.Expr.Field {
						return { 
							name: cf.name, 
							doc: null,
							access: [],
							kind: switch(cf.type) {
								case TFun(args, ret): 
									FFun( {
										args: args.map(function(a) return 
											{ 
												name: a.name, 
												opt: a.opt, 
												type: toComplexType(a.t),
												value: null
											} 
										).array(),
										ret: toComplexType(ret),
										expr: null,
										params: []
									} );
								default:
									FVar(toComplexType(cf.type), null);
							}, 
							pos: cf.pos,
							meta: []
						}
					}).array()
				); */ null;
			case TDynamic(t): 
				TPath( { sub: null, name: "Dynamic", pack: [], params: t == null ? [] : [TPType(toComplexType(t))] } );
		}
		
		#if macro
		try {
			toType(ct); //throw error if the type is not found
			return ct;
		} catch (e:Dynamic) {
			switch (ct) {
				case TPath(p): 
					p.pack = []; //for cases of t is a type param. eg. static function myMethod<T>() {  }
					try {
						toType(ct);
						return ct;
					} catch (e:Dynamic) {
						return null;
					}
				default: 
					return null;
			}
		}
		#else
		return ct;
		#end
	}
	
	/*
	 * Return a String dump of the input Expr.
	 */
	@:macro static public function dumpExpr(e:Array<Expr>) {
		return { expr:EConst(CString(Std.string(e))), pos:Context.currentPos() };
	}
	
	/*
	 * Return a String dump of the Type of input Expr.
	 */
	@:macro static public function dumpType(e:Expr, ?follow:Bool = false, ?details:Bool = false) {
		var type = switch(e.expr) { 
			case EConst(c): 
				switch(c) {
					case CType(s): Context.getType(s);
					default: Context.typeof(e);
				}
			default: Context.typeof(e);
		}
		
		if (follow) type = Context.follow(type);
		
		var str = !details ? Std.string(type) : switch (type) {
			case TAnonymous(a): "TAnonymous(" + Std.string(a.get()) + ")";
			case TEnum(t, params): "TEnum(" + Std.string(t.get()) + ", " + Std.string(params) + ")";
			case TInst(t, params): "TInst(" + Std.string(t.get()) + ", " + Std.string(params) + ")";
			case TType(t, params): "TType(" + Std.string(t.get()) + ", " + Std.string(params) + ")";
			default: Std.string(type);
		}
		
		return { expr:EConst(CString(str)), pos:Context.currentPos() };
	}
}