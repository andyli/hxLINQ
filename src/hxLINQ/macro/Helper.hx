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
	 * @param	callb				Accepts a Null<Expr> and a stack(List<Expr> using push/pop, first is current), return a TraverseControl.
	 * @param	?preorder = true	Should the traversal run in preorder or postorder.
	 * @param	?getChildrenFunc	Default to getChildren.
	 * @param	?stack				Internal use to maintain the travesal stack to pass to callb.
	 * @return						Did the traversal reach the end, ie. hadn't stopped by TCExit.
	 */
	static public function traverse(expr:Null<Expr>, callb:Null<Expr>->List<Expr>->TraverseControl, ?preorder:Bool = true, ?getChildrenFunc:Null<Expr>->Array<Null<Expr>>, ?stack:List<Expr>):Bool {
		if (stack == null) stack = new List();
		if (getChildrenFunc == null) getChildrenFunc = getChildren;
		stack.push(expr);
		
		var ret:Bool;
		try {
			ret = 
				(preorder ? switch (callb(expr,stack)) {
						case TCContinue: true;
						case TCNoChildren: throw TCNoChildren;
						case TCExit: false;
					} : true) 
				&& getChildrenFunc(expr).foreach(function(e) return traverse(e,callb,preorder,getChildrenFunc,stack))
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
	
	/**
	 * Return an Array of Expr that the input holds.
	 */
	static public function getChildren(expr:Null<Expr>):Array<Null<Expr>> {
		return expr == null ? [] : switch (expr.expr) {
			case EConst(c): [];
			case EArray(e1, e2): [e1, e2];
			case EBinop(op, e1, e2): [e1, e2];
			case EField(e, field): [e];
			case EType(e, field): [e];
			case EParenthesis(e): [e];
			case EObjectDecl(fields): fields.map(function(f) return f.expr).array();
			case EArrayDecl(values): values.copy();
			case ECall(e, params): [e].concat(params);
			case ENew(t, params): params.copy();
			case EUnop(p, postFix, e): [e];
			case EVars(vars): vars.map(function(v) return v.expr).array();
			case EFunction(n, f): [f.expr].concat(f.args.map(function(a) return a.value).array());
			case EBlock(exprs): exprs.copy();
			case EFor(v, it, expr): [it, expr];
			case EIf(econd, eif, eelse): [econd, eif, eelse];
			case EWhile(econd, e, normalWhile): [econd, e];
			case ESwitch(e, cases, edef): [e].concat(cases.fold(function(c,a) return c.values.concat([c.expr]).concat(a),[])).concat([edef]);
			case ETry(e, catches): [e].concat(catches.map(function(c) return c.expr).array());
			case EReturn(e): [e];
			case EBreak: [];
			case EContinue: [];
			case EUntyped(e): [e];
			case EThrow(e): [e];
			case ECast(e,t): [e];
			case EDisplay(e, isCall): [e];
			case EDisplayNew(t): [];
			case ETernary(econd, eif, eelse): [econd, eif, eelse];
		}
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
	
	/**
	 * Recursivly reconstruct an Expr with postorder traversal.
	 * @param	expr
	 * @param	callb	Accepts a Null<Expr> and a stack(List<Expr> using push/pop, first is current), return a Null<Expr> that replace the input.
	 * @param	?stack	Internal use to maintain the travesal stack to pass to callb.
	 * @return			A new reconstructed Expr.
	 */
	static public function reconstruct(expr:Null<Expr>, callb:Null<Expr>->List<Expr>->Null<Expr>, ?stack:List<Expr>):Null<Expr> {
		if (stack == null) stack = new List();
		stack.push(expr);
		
		var r = expr == null ? callb(null,stack) : callb(switch (expr.expr) {
			case EConst(c): 
				expr;
			case EArray(e1, e2): 
				{ expr:EArray(reconstruct(e1,callb,stack), reconstruct(e2,callb,stack)), pos:expr.pos };
			case EBinop(op, e1, e2):
				{ expr:EBinop(op, reconstruct(e1,callb,stack), reconstruct(e2,callb,stack)), pos:expr.pos };
			case EField(e, field): 
				{ expr:EField(reconstruct(e,callb,stack), field), pos:expr.pos };
			case EType(e, field): 
				{ expr:EType(reconstruct(e,callb,stack), field), pos:expr.pos };
			case EParenthesis(e): 
				{ expr:EParenthesis(reconstruct(e,callb,stack)), pos:expr.pos };
			case EObjectDecl(fields):
				var newfields = [];
				for (f in fields) newfields.push({ field:f.field, expr:reconstruct(f.expr,callb,stack) });
				{ expr:EObjectDecl(newfields), pos:expr.pos };
			case EArrayDecl(values):
				var newvalues = [];
				for (v in values) newvalues.push(reconstruct(v,callb,stack));
				{ expr:EArrayDecl(newvalues), pos:expr.pos };
			case ECall(e, params):
				var newparams = [];
				for (p in params) newparams.push(reconstruct(p,callb,stack));
				{ expr:ECall(reconstruct(e,callb,stack),newparams), pos:expr.pos };
			case ENew(t, params):
				var newparams = [];
				for (p in params) newparams.push(reconstruct(p,callb,stack));
				var newt = {
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.copy(),
					sub: t.sub
				}
				{ expr:ENew(newt,newparams), pos:expr.pos };
			case EUnop(op, postFix, e): 
				{ expr:EUnop(op, postFix, reconstruct(e,callb,stack)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:v.type, expr:reconstruct(v.expr,callb,stack) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: f.ret,
					expr: reconstruct(f.expr,callb,stack),
					params: []
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:reconstruct(a.value,callb,stack) } );
				for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in exprs) newexprs.push(reconstruct(e,callb,stack));
				{ expr:EBlock(newexprs), pos:expr.pos };
			case EFor(v, it, expr):
				{ expr:EFor(v, reconstruct(it,callb,stack), reconstruct(expr,callb,stack)), pos:expr.pos };
			case EIf(econd, eif, eelse):
				{ expr:EIf(reconstruct(econd,callb,stack), reconstruct(eif,callb,stack), reconstruct(eelse,callb,stack)), pos:expr.pos };
			case EWhile(econd, e, normalWhile):
				{ expr:EWhile(reconstruct(econd,callb,stack), reconstruct(e,callb,stack), normalWhile), pos:expr.pos };
			case ESwitch(e, cases, edef):
				var newcases = [];
				for (c in cases) {
					var newvalues = [];
					for (v in c.values) newvalues.push(reconstruct(v,callb,stack));
					newcases.push( { values:newvalues, expr:reconstruct(c.expr,callb,stack) } );
				}
				{ expr:ESwitch(reconstruct(e,callb,stack), newcases, reconstruct(edef,callb,stack)), pos:expr.pos };
			case ETry(e, catches):
				var newcatches = [];
				for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:reconstruct(c.expr,callb,stack) } );
				{ expr:ETry(reconstruct(e,callb,stack), newcatches), pos:expr.pos };
			case EReturn(e):
				{ expr:EReturn(reconstruct(e,callb,stack)), pos:expr.pos };
			case EBreak: 
				expr;
			case EContinue: 
				expr;
			case EUntyped(e): 
				{ expr:EUntyped(reconstruct(e,callb,stack)), pos:expr.pos };
			case EThrow(e):
				{ expr:EThrow(reconstruct(e,callb,stack)), pos:expr.pos };
			case ECast(e, t):
				{ expr:ECast(reconstruct(e,callb,stack), t), pos:expr.pos };
			case EDisplay(e, isCall):
				{ expr:EDisplay(reconstruct(e,callb,stack), isCall), pos:expr.pos };
			case EDisplayNew(t):
				expr;
			case ETernary(econd, eif, eelse):
				{ expr:ETernary(reconstruct(econd,callb,stack), reconstruct(eif,callb,stack), reconstruct(eelse,callb,stack)), pos:expr.pos };
		},stack);
		
		stack.pop();
		return r;
	}
	
	/**
	 * Clone an Expr.
	 * @param	expr
	 * @param	?deep	Recursivly or not.
	 * @return			The clone of input.
	 */
	static public function clone(expr:Null<Expr>, ?deep:Bool = true):Null<Expr> {
		if (deep)
			return reconstruct(expr, function(e,s) return clone(e, false));
		else
			return expr == null? null : switch (expr.expr) {
				case EConst(c): 
					{ expr:EConst(c), pos:expr.pos };
				case EArray(e1, e2): 
					{ expr:EArray(e1, e2), pos:expr.pos };
				case EBinop(op, e1, e2): 
					{ expr:EBinop(op, e1, e2), pos:expr.pos };
				case EField(e, field): 
					{ expr:EField(e, field), pos:expr.pos };
				case EType(e, field): 
					{ expr:EType(e, field), pos:expr.pos };
				case EParenthesis(e): 
					{ expr:EParenthesis(e), pos:expr.pos };
				case EObjectDecl(fields):
					var newfields = [];
					for (f in fields) newfields.push( { field:f.field, expr:f.expr } );
					{ expr:EObjectDecl(newfields), pos:expr.pos };
				case EArrayDecl(values):
					{ expr:EArrayDecl(values.copy()), pos:expr.pos };
				case ECall(e, params):
					{ expr:ECall(e, params.copy()), pos:expr.pos };
				case ENew(t, params):
					var newt = {
						pack: t.pack.copy(),
						name: t.name,
						params: t.params.copy(),
						sub: t.sub
					}
					{ expr:ENew(newt, params.copy()), pos:expr.pos };
				case EUnop(p, postFix, e): 
					{ expr:EUnop(p, postFix, e), pos:expr.pos };
				case EVars(vars): 
					var newvars = [];
					for (v in vars) newvars.push( { name:v.name, type:v.type, expr:v.expr } );
					{ expr:EVars(newvars), pos:expr.pos };
				case EFunction(n, f):
					var newf = {
						args: [],
						ret: f.ret,
						expr: f.expr,
						params: []
					}
					for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:a.value } );
					for (p in f.params) newf.params.push( { name:p.name, constraints:p.constraints.copy() } );
					{ expr:EFunction(n, newf), pos:expr.pos };
				case EBlock(exprs):
					{ expr:EBlock(exprs.copy()), pos:expr.pos };
				case EFor(v, it, expr):
					{ expr:EFor(v, it, expr), pos:expr.pos };
				case EIf(econd, eif, eelse):
					{ expr:EIf(econd, eif, eelse), pos:expr.pos };
				case EWhile(econd, e, normalWhile):
					{ expr:EWhile(econd, e, normalWhile), pos:expr.pos };
				case ESwitch(e, cases, edef):
					var newcases = [];
					for (c in cases) newcases.push( { values:c.values.copy(), expr:c.expr } );
					{ expr:ESwitch(e, newcases, edef), pos:expr.pos };
				case ETry(e, catches):
					var newcatches = [];
					for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:c.expr } );
					{ expr:ETry(e, newcatches), pos:expr.pos };
				case EReturn(e):
					{ expr:EReturn(e), pos:expr.pos };
				case EBreak: 
					{ expr:EBreak, pos:expr.pos };
				case EContinue: 
					{ expr:EContinue, pos:expr.pos };
				case EUntyped(e): 
					{ expr:EUntyped(e), pos:expr.pos };
				case EThrow(e):
					{ expr:EThrow(e), pos:expr.pos };
				case ECast(e, t):
					{ expr:ECast(e, t), pos:expr.pos };
				case EDisplay(e, isCall):
					{ expr:EDisplay(e, isCall), pos:expr.pos };
				case EDisplayNew(t):
					{ expr:EDisplayNew(t), pos:expr.pos };
				case ETernary(econd, eif, eelse):
					{ expr:ETernary(econd, eif, eelse), pos:expr.pos };
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