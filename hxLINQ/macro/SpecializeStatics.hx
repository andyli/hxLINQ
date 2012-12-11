package hxLINQ.macro;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;
using hxLINQ.LINQ;
#end
class SpecializeStatics {
	static public function specializeTypeParamDeclArray(a:Array<TypeParamDecl>, typeMap:Hash<ComplexType>):Array<TypeParamDecl> {
		var ret = [];
		for (tpd in a) {
			if (typeMap.exists(tpd.name)) continue;
			
			ret.push({
				name: tpd.name,
				constraints: tpd.constraints == null ? null : tpd.constraints.linq().select(function(ct,_) return specializeComplexType(ct, typeMap)).items,
				params: tpd.params == null ? null : specializeTypeParamDeclArray(tpd.params, typeMap)
			});
		}
		return ret;
	}
	
	static public function toSpecializeTypeParamDeclArray(a:Array<{ name: String, t: Type }>, typeMap:Hash<ComplexType>):Array<TypeParamDecl> {
		var ret = [];
		for (nt in a) {
			if (typeMap.exists(nt.name)) continue;
			
			ret.push({
				name: nt.name,
				constraints: switch(nt.t){
					case TInst(t, params):
						switch(t.get().kind) {
							case KTypeParameter(constraints):
								constraints.linq().select(function(c,_) return Context.toComplexType(c)).items;
							default: throw t.get().kind;
						}
					default: throw nt.t;
				},
				params: []
			});
		}
		return ret;
	}
	
	static public function specializeComplexType(t:ComplexType, typeMap:Hash<ComplexType>):ComplexType {
		//trace(t);
		var r = t == null ? null : switch (t) {
			case TPath(p): 
				if (typeMap.exists(p.name)) {
					typeMap.get(p.name);
				} else {
					try {
						Context.typeof(macro cast(null, $t)); //if it is a type param, it will throw
						t;
					} catch (e:Dynamic) {
						TPath({
							pack: [],
							name: p.name,
							params: p.params.linq().select(function(p,_) return switch(p){
								case TPType(t):
									TPType(specializeComplexType(t, typeMap));
								case TPExpr(e):
									p;
							}).items,
							sub: p.sub
						});
					}
				}
			case TFunction(args, ret):
				TFunction(args.linq().select(function(a,_) return specializeComplexType(a, typeMap)).items, specializeComplexType(ret, typeMap));
			case TAnonymous(fields):
				TAnonymous(fields.linq().select(function(field,_) return {
					name: field.name,
					doc: field.doc,
					access: field.access,
					kind: switch (field.kind) {
						case FVar(t, e): 
							FVar(specializeComplexType(t, typeMap), e);
						case FFun(f): 
							FFun({
								args: f.args.linq().select(function(a, _) return {
									name: a.name,
									opt: a.opt,
									type: specializeComplexType(a.type, typeMap),
									value: a.value
								}).items,
								ret: specializeComplexType(f.ret, typeMap),
								expr: f.expr,
								params: specializeTypeParamDeclArray(f.params, typeMap)
							});
						case FProp(get, set, t, e):
							FProp(get, set, specializeComplexType(t, typeMap), e);
					},
					pos: field.pos,
					meta: field.meta
				}).items);
			case TParent(t):
				TParent(specializeComplexType(t, typeMap));
			case TExtend(p, fields):
				throw "not supported yet " + t;
			case TOptional(t):
				TOptional(specializeComplexType(t, typeMap));
		}
		//trace(r);
		return r;
	}
	
	@:macro static public function build(cls:ExprOf<Class<Dynamic>>, map:ExprOf<Array<Dynamic>>):Array<Field> {
		var fields = Context.getBuildFields();
		var clsType = switch (Context.typeof(cls)) {
			case TType(t,p): switch(Context.getType(t.toString().split("#").join(""))) {
				case TInst(t,p): t.get();
				default: throw t.toString();
			}
			default: throw Context.typeof(cls);
		}
		
		var mapExpect = "map should be an Array of cast expressions, eg. [cast(T,Int), cast(C,Array<Int>)]";
		var typeMap = new Hash<ComplexType>();
		switch (map.expr) {
			case EArrayDecl(vs):
				for (v in vs) {
					switch (v.expr) {
						case ECast(e,t):
							var paramName = switch (e.expr) {
								case EConst(c): switch (c) {
									case CIdent(s): s;
									default: throw mapExpect;
								}
								default: throw mapExpect;
							}
							typeMap.set(paramName, t);
						default: throw mapExpect;
					}
				} 
			default: throw mapExpect;
		}
		
		for (staticMthd in clsType.statics.get()) {
			var staticMthdFunc = switch(Context.getTypedExpr(staticMthd.expr()).expr) {
				case EFunction(name, f): f;
				default: throw Context.getTypedExpr(staticMthd.expr()).expr;
			}
			var field = {
				name: staticMthd.name,
				doc: staticMthd.doc,
				access: staticMthd.isPublic ? [AStatic, APublic] : [AStatic, APrivate],
				kind: FFun({
					args: staticMthdFunc.args.linq().select(function(arg, _){
						return {
							name: arg.name,
							opt: arg.opt,
							type: specializeComplexType(arg.type, typeMap),
							value: arg.value
						}
					}).items,
					ret: specializeComplexType(staticMthdFunc.ret, typeMap),
					expr: staticMthdFunc.expr,
					params: toSpecializeTypeParamDeclArray(staticMthd.params, typeMap)
				}),
				pos: staticMthd.pos
			}
			trace(field);
			fields.push(field);
		}
		return fields;
	}
}