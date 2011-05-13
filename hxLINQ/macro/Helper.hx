package hxLINQ.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

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
				case EDisplay(_,_), EDisplayNew(_): false;
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
	
	#if macro
	/**
	 * Get Type of a ComplexType.
	 * @param	com
	 * @param	pos		You can simply feed Context.currentPos().
	 * @return			Type of the ComplexType.
	 */
	static public function toType(com:ComplexType, pos:Position):Type {
		//{var $testType:{{com}}; testType;}
		var testType = { expr:EBlock([ { expr:EVars( [ { name: "$testType", type: com, expr: null } ] ), pos:pos }, { expr:EConst(CIdent("$testType")), pos:pos } ]), pos:pos };
		return Context.typeof(testType);
	}
	#end
	
	public static function getFullyQualifiedName(type:BaseType):String {
		return type.pack.join(".") + (type.pack.length > 0 ? "." : "") + type.name;
    }
	
	static public function toComplexType(t:Null<Type>):Null<ComplexType> {
		return t == null ? null : switch(t) {
			case TMono: 
				null;
			case TEnum(t, params):
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TInst(t, params):
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TType(t, params): 
				TPath( { sub: null, name: t.get().name, pack: t.get().pack, params: params.map(function(p) return TPType(toComplexType(p))).array()} );
			case TFun(args, ret): 
				TFunction( args.map(function(a) return toComplexType(a.t)).array(), toComplexType(ret) );
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
				*/
				TAnonymous( a.get().fields.map(
					function(cf:ClassField):haxe.macro.Expr.Field {
						return { 
							name: cf.name, 
							isPublic: cf.isPublic, 
							type: switch(cf.type) {
								case TFun(args, ret): 
									FFun( args.map(function(a) return { name: a.name, opt: a.opt, type: toComplexType(a.t) } ).array(), toComplexType(ret) );
								default:
									FVar(toComplexType(cf.type));
							}, 
							pos: cf.pos 
						}
					}).array()
				);
			case TDynamic(t): 
				TPath( { sub: null, name: "Dynamic", pack: [], params: [TPType(toComplexType(t))] } );
		}
	}
	
	@:macro static public function dumpExpr(e:Expr) {
		return return { expr:EConst(CString(Std.string(e))), pos:Context.currentPos() };
	}
	
	@:macro static public function dumpType(e:Expr) {
		var type = switch(e.expr) { 
			case EConst(c): 
				switch(c) {
					case CType(s): Context.getType(s);
					default: Context.typeof(e);
				}
			default: Context.typeof(e);
		}
		
		var str = switch (type) {
			case TAnonymous(a): "TAnonymous(" + Std.string(a.get()) + ")";
			default: Std.string(type);
		}
		
		return { expr:EConst(CString(str)), pos:Context.currentPos() };
	}
}