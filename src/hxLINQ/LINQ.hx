/*
	hxLINQ
	HaXe version of LINQ. Based on the "LINQ to JavaScript (JSLINQ)":http://jslinq.codeplex.com Project.

	JSLINQ is licensed under the Microsoft Reciprocal License (Ms-RL)
	Copyright (C) 2009 Chris Pietschmann (http://pietschsoft.com). All rights reserved.
	The license can be found here: http://jslinq.codeplex.com/license
*/

package hxLINQ;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

import hxLINQ.macro.Helper;
using hxLINQ.macro.Helper;

using tink.macro.tools.TypeTools;

using Std;
using Lambda;
#end


/*
 * For LINQ, Array is not a case of Iterable.
 * It is because Array<BaseType> is Iterable<Null<BaseType>>, but we want BaseType instead of Null<BaseType>.
 */
@:macro class LINQtoArray {
	static public function linq<T>(?data:ExprRequire<Array<T>>):ExprRequire<LINQ<Array<T>,T>> {
		var dataType = Context.typeof(data);
		
		switch(Context.follow(dataType)) {
			case TInst(t, params):
				if (t.get().name == "Array" && t.get().pack.length == 0) {
					var arrayType = params[0].toComplex();
					return { 
						expr: ENew( 
							{ 
								sub: null, 
								name: "LINQ", 
								pack: ["hxLINQ"], 
								params: arrayType == null ? [] : [ TPType(dataType.toComplex()),TPType(arrayType) ] 
							},
							[data]
						), 
						pos: Context.currentPos() 
					}
				}
			default:
		}
		
		return throw "Should be an Array.";
	}
}

@:macro class LINQtoIterable {
	static public function linq<T>(?data:ExprRequire<Iterable<T>>):ExprRequire<LINQ<Iterable<T>,T>> {
		var dataType = Context.typeof(data);
		var itrblItemType = dataType.getItrblItemType().toComplex();
		return { 
			expr: ENew( 
				{ 
					sub: null, 
					name: "LINQ", 
					pack: ["hxLINQ"], 
					params: itrblItemType == null ? [] : [ TPType(dataType.toComplex()), TPType(itrblItemType) ]
				},
				[data]
			), 
			pos: Context.currentPos() 
		};
	}
}

@:macro class LINQtoIterator {
	static public function linq<T>(?data:ExprRequire<Iterator<T>>):ExprRequire<LINQ<Iterator<T>,T>> {
		var dataType = Context.typeof(data);
		var itrItemType = dataType.getItrItemType().toComplex();
		return { 
			expr: ENew( 
				{ 
					sub: null, 
					name: "LINQ", 
					pack: ["hxLINQ"], 
					params: itrItemType == null ? [] : [ TPType(dataType.toComplex()), TPType(itrItemType) ]
				},
				[data]
			), 
			pos: Context.currentPos() 
		};
	}
}

@:macro class LINQmethod {
	static public function where<D,I>(linq:ExprRequire<LINQ<D,I>>, clause:ExprRequire < I->Int->Bool > ):ExprRequire<LINQ<D,I>> {
		if (Context.defined("display")) {
			switch(clause.expr) { 
				case EFunction(name, func):
					/*
					 * Infer T->Int->Bool to clause.
					 */
					
					var pos = clause.pos;
					
					if (func.ret == null)
						func.ret = TPath( { sub:null, name: "Bool", pack: [], params: [] } );
					else 
						if (Context.follow(func.ret.toType()).string() != Context.getType("Bool").string())
							throw "clause should return Bool.";
					
					var itemType = linq.getItemType();
					
					if (func.args.length > 0)
						if (func.args[0].type == null)
							func.args[0].type = itemType.toComplex();
						else 
							if (Context.follow(func.args[0].type.toType()).string() != Context.follow(itemType).string())
								throw func.args[0].name + " of clause should be " + itemType.string() + ".";
					
					if (func.args.length > 1)
						if (func.args[1].type == null)
							func.args[1].type = TPath( { sub:null, name: "Int", pack: [], params: [] } );
						else
							if (Context.follow(func.ret.toType()).string() != Context.getType("Int").string())
								throw "clause should be T->Int->Bool.";
				default:
			};
			
			return clause;
		}
		return linq;
	}
	
	static public function toArray<D,I>(linq:ExprRequire<LINQ<D,I>>):ExprRequire<Array<I>> {
		var pos = Context.currentPos();
		
		var eCalls = linq.toECallArray();
		var dataExpr; //Expr of data source
		var dataI = eCalls.length; //index of dataExpr in eCalls
		while (--dataI >= 0) {
			if (["linq", "where"].indexOf(eCalls[dataI].getECallFieldName()) == -1) {
				dataExpr = switch(eCalls[dataI].expr) {
					//new LINQ(data)
					case ENew(t, params): params[0];
					
					//data.linq()
					default: eCalls[dataI]; 
				}
				break;
			}
		}
		
		/*
		var dataType = linq.getDataType();
		var dataIsArray = switch(Context.follow(dataType)) {
			case TInst(t, params): t.get().name == "Array" && t.get().pack.length == 0;
			default: false;
		}*/
		
		var wheres = eCalls.filter(function(e) return e.getECallFieldName() == "where");
		var needCounter = false;
		if (wheres.length > 0) {
			var econd;
			for (w in wheres) {
				if (econd == null) {
					switch(w.expr) {
						case ECall(e, params):
							switch(params[0].expr) { //clause
								case EFunction(name, f):
									if (!needCounter && f.args.length >= 2) { //need counter
										needCounter = true;
										//TO-DO
									}
								default: throw "Accept function only at this moment.";
							};
						default: throw "why not a ECall here?";
					}
				}
			}
		}
		
		var econd = { expr:EConst(CIdent("true")), pos:pos };
		var vars = [ { name:"__r", type:null, expr: { expr:EArrayDecl([]), pos:pos } } ];
		
		
		var loopBlockExprs = 
			[
				{
					expr: EIf(
						econd, 
						//__r.push(__itm);
						{
							expr: ECall(
								{ expr: EField( { expr:EConst(CIdent("__r")), pos:pos }, "push"), pos:pos },
								[ { expr:EConst(CIdent("__itm")), pos:pos } ]
							),
							pos:pos
						}, 
						null
					),
					pos:pos
				}
			];
						
		if (needCounter) {
			vars.push( { name:"__i", type:null, expr: { expr:EConst(CInt("0")), pos:pos } } );
			
			loopBlockExprs.push(
				//++__i;
				{
					expr: EUnop(OpIncrement, false, { expr:EConst(CIdent("__i")), pos:pos } ),
					pos:pos
				}
			);
		}
		
		return {
			expr: EBlock([
				{ expr: EVars(vars), pos:pos },
				//for (__itm in @dataExpr)
				{
					expr: EFor({ expr:EIn({expr:EConst(CIdent("__itm")), pos:pos}, dataExpr), pos:pos }, {
						expr: EBlock(loopBlockExprs),
						pos:pos
					}),
					pos:pos
				},
				//__r;
				{ expr: EConst(CIdent("__r")), pos:pos }
			]),
			pos:pos
		};
	}
}

/**
 * D is the data source type, for example Array<String>.
 * I is the item type, for example if D is Array<String>, I would be String.
 */
#if !debug extern #end 
class LINQ<D,I> {	
	public function new(data:D):Void {
		throw "LINQ instence can't be used in runtime. You should call for example toArray() after creating it.";
	}

	/*
	public function iterator():Iterator<T> {
		return items.iterator();
	}

	public function where(clause:T->Int->Bool):LINQ<T> {
		var i = 0;
		var newList = new List<T>();
		for (item in items) {
			if (clause(item,i++)) {
				newList.add(item);
			}
		}
		return new LINQ(newList);
	}

	public function select<F>(clause:T->F):LINQ<F> {
		var newList = new List<F>();
		
		for (item in items) {
			var newItem = clause(item);
			if (newItem != null) {
				newList.add(newItem);
			}
		}
		return new LINQ(newList);
	}

	public function orderBy<T2>(clause:T->T2):OrderedLINQ<T> {
		var tempArray = items.array();
		var sortFn = function(a, b) {
			var x = clause(a);
            var y = clause(b);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function orderByDescending<T2>(clause:T->T2):OrderedLINQ<T> {
		var tempArray = items.array();
		var sortFn = function(a, b) {
			var x = clause(b);
            var y = clause(a);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function groupBy<F>(clause:T->F) : LINQ<IGrouping<F,T>> {
		var lists = new Array<Grouping<F,T>>();
		
		for (item in items) {
			var f = clause(item);
			var list = new LINQ(lists).where(function(g:IGrouping<F,T>, i:Int) return g.key == f).first();
			if (list == null) {	
				list = new Grouping<F,T>(f);
				lists.push(list);
			}
			list.add(item);
		}

		return new LINQ(cast lists);
	}

	public function selectMany<F>(clause:T->Array<F>):LINQ<F> {
		var r = new Array<F>();
		for (item in items){
			var a = clause(item);
			r = r.concat(a);
		}
		return new LINQ(r);
	}

	public function count(?clause:T->Int->Bool):Int {
		if (clause == null) {
			return items.count();
		} else {
			return this.where(clause).items.count();
		}
	}

	public function aggregate<F>(seed:F, clause:F->T->F):F {
		var result = seed;
		for (item in items) {
			result = clause(result,item);
		}
		return result;
	}

	public function min(?clause:T->Float):Float {
		if (clause == null){
			return this.aggregate(cast this.first(), cast Math.min);
		} else {
			return this.aggregate(clause(this.first()), function(s:Float,i:T) return Math.min(s,clause(i)));
		}
	}

	public function max(?clause:T->Float):Float {
		if (clause == null){
			return this.aggregate(cast this.first(), cast Math.max);
		} else {
			return this.aggregate(clause(this.first()), function(s:Float,i:T) return Math.max(s,clause(i)));
		}
	}

	public function sum(?clause:T->Float):Float {
		if (clause == null){
			return this.aggregate(0.0, function(s:Float,i:T) return s + cast i);
		} else {
			return this.aggregate(0.0, function(s:Float,i:T) return s + clause(i));
		}
	}

	public function average(?clause:T->Float):Float {
		return this.sum(clause)/this.count();
	}

	public function distinct<F>(clause:T->F):LINQ<F> {
		var newItem;
		var retVal = new List<F>();
		for (item in items) {
			newItem = clause(item);
			if (!retVal.exists(function (f:F) return f == newItem)) {
				retVal.add(newItem);
			}
		}
		return new LINQ(retVal);
	}

	public function any(clause:T->Int->Bool):Bool {
		var i = 0;
		for (item in items) {
			if (clause(item,i++)) {
				return true;
			}
		}
		return false;
	}

	public function all(clause:T->Int->Bool):Bool {
		var i = 0;
		for (item in items) {
			if (!clause(item,i++)) {
				return false;
			}
		}
		return true;
	}

	public function reverse():LINQ<T> {
		var tempAry = items.array();
		tempAry.reverse();
		return new LINQ(tempAry);
	}

	public function first(?clause:T->Int->Bool):T {
		if (clause != null) {
			return this.where(clause).first();
		} else {
			return items.iterator().next();
		}
	}

	public function last(?clause:T->Int->Bool):T {
		if (clause != null) {
			return this.where(clause).last();
		} else {
			if (!items.empty()) {
				return items.array().pop();
			} else {
				return null;
			}
		}
	}

	public function elementAt(i:Int):T {
		var count = 0;
		for (item in items) {
			if (count++ == i) return item;
		}
		return null;
	}

	public function concat(items:Iterable<T>):LINQ<T> {
		var tmpAry = this.items.array();
		return new LINQ(tmpAry.concat(items.array()));
	}

	public function intersect<T2>(items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T> {
		if (clause == null){
			clause = function (item:T, index:Int, item2:Dynamic, index2:Int) { return item == item2; };
		}

		var result = new List<T>();
		var ia = 0;
		var ib = 0;
		for (a in this.items) {
			for (b in items) {
				if (clause(a,ia,b,ib++)) {
					result.add(a);
				}
			}
			++ia;
		}
		return new LINQ(result);
	}

	public function defaultIfEmpty(defaultValue:Iterable<T>):Iterable<T> {
		if (this.empty()) {
			return defaultValue;
		} else {
			return this;
		}
	}

	public function elementAtOrDefault(i:Int, defaultValue:T):T {
		if (i < 0) return defaultValue;
		var r = this.elementAt(i);
		return r == null ? defaultValue : r;
	}

	public function firstOrDefault(defaultValue:T):T {
		var r = this.first();
		return r == null ? defaultValue : r;
	}

	public function lastOrDefault(defaultValue:T):T {
		var r = this.last();
		return r == null ? defaultValue : r;
	}

	
	static private function indexOf<F>(items:Iterable<F>, item:F):Int {
		var i = 0;
		for (_item in items) {
			if (_item == item) {
				return i;
			} else {
				i++;
			}
		}
		return -1;
	}
	*/	
	
	/*
	public function where(clause:T->Int->Bool):LINQ<T> {
		var i = 0;
		var newList = new List<T>();
		for (item in items) {
			if (clause(item,i++)) {
				newList.add(item);
			}
		}
		return new LINQ(newList);
	}
	*/
}
/*
private class OrderedLINQ<T> extends LINQ<T> {
	private var sortFns:Array<T->T->Int>;

	public function new(dataItems:Iterable<T>, sortFns:Array<T->T->Int>) {
		super(dataItems);
		this.sortFns = sortFns;
	}
	
	public function thenBy<T2>(clause:T->T2):OrderedLINQ<T> {
		var tempArray:Array<T> = items.array();
		var _sortFns = sortFns.copy();
		_sortFns.push(function(a, b) {
			var x = clause(a);
            var y = clause(b);
			return Reflect.compare(x,y);
		});

		tempArray.sort(function(a, b) {
			var r:Int = 0;
			for (sortFn in _sortFns){
		        r = sortFn(a,b);
		        if (r != 0) break;
			}
			
            return r;
		});

		return new OrderedLINQ(tempArray, _sortFns);
	}

	public function thenByDescending<T2>(clause:T->T2):OrderedLINQ<T> {
		var tempArray:Array<T> = items.array();
		var _sortFns = sortFns.copy();
		_sortFns.push(function(a, b) {
			var x = clause(b);
            var y = clause(a);
			return Reflect.compare(x,y);
		});

		tempArray.sort(function(a, b) {
			var r:Int = 0;
			for (sortFn in _sortFns){
		        r = sortFn(a,b);
		        if (r != 0) break;
			}
			
            return r;
		});

		return new OrderedLINQ(tempArray, _sortFns);
	}
}

interface IGrouping<K,V> {
	public var key(default,null):K;

	public function iterator():Iterator<V>;
}

private class Grouping<K,V> implements IGrouping<K,V> {
	public var key(default,null):K;
	private var values:List<V>;

	public function new(key:K):Void {
		this.key = key;
		values = new List<V>();
	}

	public function add(val:V):Void {
		values.add(val);
	}

	public function iterator():Iterator<V> {
		return values.iterator();
	}
}

*/