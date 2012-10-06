/*
	hxLINQ
	HaXe version of LINQ. Based on the "LINQ to JavaScript (JSLINQ)":http://jslinq.codeplex.com Project.

	JSLINQ is licensed under the Microsoft Reciprocal License (Ms-RL)
	Copyright (C) 2009 Chris Pietschmann (http://pietschsoft.com). All rights reserved.
	The license can be found here: http://jslinq.codeplex.com/license
*/

package hxLINQ;

using Lambda;

class LINQ<T,C:Iterable<T>> {
	public function new(dataItems:C):Void {
		this.items = dataItems;
	}

	public function iterator():Iterator<T> {
		return items.iterator();
	}

	public function where(clause:T->Int->Bool):LINQ<T,List<T>> {
		var i = 0;
		var newList = new List<T>();
		for (item in items) {
			if (clause(item,i++)) {
				newList.add(item);
			}
		}
		return new LINQ(newList);
	}

	public function select<F>(clause:T->F):LINQ<F,List<F>> {
		var newList = new List<F>();
		
		for (item in items) {
			var newItem = clause(item);
			if (newItem != null) {
				newList.add(newItem);
			}
		}
		return new LINQ(newList);
	}

	public function orderBy<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = items.array();
		var sortFn = function(a, b) {
			var x = clause(a);
            var y = clause(b);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function orderByDescending<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = items.array();
		var sortFn = function(a, b) {
			var x = clause(b);
            var y = clause(a);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function groupBy<F>(clause:T->F) : LINQ<Grouping<F,T>,Array<Grouping<F,T>>> {
		var lists = new Array<Grouping<F,T>>();
		
		for (item in items) {
			var f = clause(item);
			var list = new LINQ(lists).where(function(g:Grouping<F,T>, i:Int) return g.key == f).first();
			if (list == null) {	
				list = new Grouping<F,T>(f);
				lists.push(list);
			}
			list.add(item);
		}

		return new LINQ(lists);
	}

	public function selectMany<F>(clause:T->Array<F>):LINQ<F,Array<F>> {
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

	public function distinct<F>(clause:T->F):LINQ<F,List<F>> {
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

	public function reverse():LINQ<T,Array<T>> {
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

	public function concat(items:Iterable<T>):LINQ<T,Array<T>> {
		var tmpAry = this.items.array();
		return new LINQ(tmpAry.concat(items.array()));
	}

	public function intersect<T2>(items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T,List<T>> {
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

	public var items(default,null):C;
	
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
}

class OrderedLINQ<T,C:Iterable<T>> extends LINQ<T,C> {
	private var sortFns:Array<T->T->Int>;

	public function new(dataItems:C, sortFns:Array<T->T->Int>) {
		super(dataItems);
		this.sortFns = sortFns;
	}
	
	public function thenBy<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray:Array<T> = items.array();
		var _sortFns = sortFns.concat([
			function(a, b) {
				var x = clause(a);
	            var y = clause(b);
				return Reflect.compare(x,y);
			}
		]);

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

	public function thenByDescending<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray:Array<T> = items.array();
		var _sortFns = sortFns.concat([
			function(a, b) {
				var x = clause(b);
	            var y = clause(a);
				return Reflect.compare(x,y);
			}
		]);

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

@:allow(hxLINQ.LINQ)
private class Grouping<K,V> {
	public var key(default,null):K;
	private var values:List<V>;

	public function new(key:K):Void {
		this.key = key;
		values = new List<V>();
	}

	private function add(val:V):Void {
		values.add(val);
	}

	public function iterator():Iterator<V> {
		return values.iterator();
	}
}
