/*
	hxLINQ
	HaXe version of LINQ. Based on the "LINQ to JavaScript (JSLINQ)":http://jslinq.codeplex.com Project.

	JSLINQ is licensed under the Microsoft Reciprocal License (Ms-RL)
	Copyright (C) 2009 Chris Pietschmann (http://pietschsoft.com). All rights reserved.
	The license can be found here: http://jslinq.codeplex.com/license
*/

package hxLINQ.iterable;

import hxLINQ.*;

class LINQtoIterable<T,C:Iterable<T>> {
	inline static public function linq<T,C:Iterable<T>>(iterable:C):LINQ<T,C> {
		return new LINQ(iterable);
	}
	
	public var items(default, null):C;
	public var defaultValue(default, null):T;
	
	public function new(dataItems:C):Void {
		this.items = dataItems;
		this.defaultValue = null;
	}

	public function iterator():Iterator<T> {
		return items.iterator();
	}

	public function where(clause:T->Int->Bool):LINQ<T,Array<T>> {
		var i = 0;
		var newArray = new Array<T>();
		for (item in items) {
			if (clause(item,i++)) {
				newArray.push(item);
			}
		}
		return new LINQ(newArray);
	}

	public function select<F>(clause:T->Int->F):LINQ<F,Array<F>> {
		var newArray = new Array<F>();
		
		var i = 0;
		for (item in items) {
			var newItem = clause(item, i++);
			if (newItem != null) {
				newArray.push(newItem);
			}
		}
		return new LINQ(newArray);
	}

	public function orderBy<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = toArray();
		var sortFn = function(a, b) {
			var x = clause(a);
            var y = clause(b);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function orderByDescending<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = toArray();
		var sortFn = function(a, b) {
			var x = clause(b);
            var y = clause(a);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	public function groupBy<F>(clause:T->F):LINQ<Grouping<F,T>,Array<Grouping<F,T>>> {
		var arrays = new Array<Grouping<F,T>>();
		
		for (item in items) {
			var f = clause(item);
			var group = new LINQ(arrays).where(function(g:Grouping<F,T>, i:Int) return g.key == f).first();
			if (group == null) {	
				group = new Grouping<F,T>(f);
				arrays.push(group);
			}
			group.add(item);
		}

		return new LINQ(arrays);
	}
	
	public function join<T2,K,R>(inner:Iterable<T2>, outerKeySelector:T->K, innerKeySelector:T2->K, resultSelector:T->T2->R, ?comparer:K->Int->K->Int->Bool):LINQ<R,Array<R>> {
		if (comparer == null) comparer = function(ka,_,kb,_) return ka == kb;
		var result = new Array<R>();
		var i = 0;
		for (a in this.items) {
			var ka = outerKeySelector(a);
			var i2 = 0;
			for (b in inner) {
				if (comparer(ka,i,innerKeySelector(b),i2++)) {
					result.push(resultSelector(a, b));
				}
			}
			++i;
		}
		return new LINQ(result);
	}
	
	public function groupJoin<T2,K,R>(inner:Iterable<T2>, outerKeySelector:T->K, innerKeySelector:T2->K, resultSelector:T->Iterable<T2>->R, ?comparer:K->Int->K->Int->Bool):LINQ<R,Array<R>> {
		if (comparer == null) comparer = function(ka,_,kb,_) return ka == kb;
		var result = new Array<R>();
		var i = 0;
		for (a in this.items) {
			var ka = outerKeySelector(a);
			result.push(resultSelector(a, new LINQ(inner).where(function(b,i2) return comparer(ka,i,innerKeySelector(b),i2))));
			++i;
		}
		return new LINQ(result);
	}

	public function selectMany<F>(clause:T->Int->Array<F>):LINQ<F,Array<F>> {
		var r = new Array<F>();
		var i = 0;
		for (item in items){
			var a = clause(item, i++);
			r = r.concat(a);
		}
		return new LINQ(r);
	}

	public function count(?clause:T->Int->Bool):Int {
		if (clause == null) {
			var i = 0;
			for (_item in items) ++i;
			return i;
		} else {
			return this.where(clause).count();
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

	public function distinct(?comparer:T->Int->T->Int->Bool):LINQ<T,Array<T>> {
		if (comparer == null) comparer = function(a,_,b,_) return a == b;
		var retVal = new Array<T>();
		var i = 0;
		for (item in items) {
			if (!new LINQ(retVal).any(function(r,i2) return comparer(r,i,item,i2))) {
				retVal.push(item);
			}
			++i;
		}
		return new LINQ(retVal);
	}
	
	public function contains(value:T, ?comparer:T->T->Int->Bool):Bool {
		if (comparer == null) comparer = function(a,b,i) return a == b;
		var i = 0;
		for (item in items) {
			if (comparer(item, value, i++)) return true;
		}
		return false;
	}

	public function any(?clause:T->Int->Bool):Bool {
		if (clause == null) return items.iterator().hasNext();
		
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
		var tempAry = toArray();
		tempAry.reverse();
		return new LINQ(tempAry);
	}

	public function first(?clause:T->Int->Bool):T {
		return if (clause != null) {
			this.where(clause).first();
		} else {
			items.iterator().next();
		}
	}

	public function last(?clause:T->Int->Bool):T {
		return if (clause != null) {
			this.where(clause).last();
		} else {
			if (any()) {
				toArray().pop();
			} else {
				null;
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
		return new LINQ(toArray().concat(new LINQ(items).toArray()));
	}

	public function intersect<T2>(items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T,Array<T>> {
		if (clause == null){
			clause = function (item:T, index:Int, item2:Dynamic, index2:Int) { return item == item2; };
		}

		var result = new Array<T>();
		var ia = 0;
		for (a in this.items) {
			var ib = 0;
			for (b in items) {
				if (clause(a,ia,b,ib++)) {
					result.push(a);
				}
			}
			++ia;
		}
		return new LINQ(result);
	}
	
	public function except<T2>(items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T,Array<T>> {
		if (clause == null){
			clause = function (item:T, index:Int, item2:Dynamic, index2:Int) { return item == item2; };
		}

		var result = new Array<T>();
		var remove = new LINQ(items);
		var ia = 0;
		for (a in this.items) {
			if (!remove.any(function(b,ib) return clause(a,ia,b,ib)))
				result.push(a);
			++ia;
		}
		return new LINQ(result);
	}

	public function defaultIfEmpty(?defaultValue:T):LINQ<T,C> {
		var r = new LINQ(items);
		r.defaultValue = defaultValue;
		return r;
	}

	public function elementAtOrDefault(i:Int):T {
		var count = 0;
		for (item in items) {
			if (count++ == i) return item;
		}
		return defaultValue;
	}

	public function firstOrDefault():T {
		return any() ? first() : defaultValue;
	}

	public function lastOrDefault():T {
		return any() ? last() : defaultValue;
	}
	
	public function ofType<T2>(type:Class<T2>):LINQ<T2,Array<T2>> {
		var newArray = new Array<T2>();
		for (item in items) {
			if (Std.is(item,type)) {
				newArray.push(cast item);
			}
		}
		return new LINQ(newArray);
	}
	
	public function toArray():Array<T> {
		var array = [];
		for (_item in items){
			array.push(_item);
		}
		return array;
	}
	
	public function toList():List<T> {
		var list = new List<T>();
		for (_item in items){
			list.add(_item);
		}
		return list;
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
}

class OrderedLINQ<T,C:Iterable<T>> extends LINQ<T,C> {
	private var sortFns:Array<T->T->Int>;

	public function new(dataItems:C, sortFns:Array<T->T->Int>) {
		super(dataItems);
		this.sortFns = sortFns;
	}
	
	public function thenBy<T2>(clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray:Array<T> = toArray();
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
		var tempArray:Array<T> = toArray();
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