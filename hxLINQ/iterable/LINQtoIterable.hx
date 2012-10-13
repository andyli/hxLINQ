package hxLINQ.iterable;

using hxLINQ.LINQ;

class LINQtoIterable<T,C:Iterable<T>> {
	inline static public function linq<T,C:Iterable<T>>(iterable:C):LINQ<T,C> {
		return new LINQ(iterable);
	}
	
	public var items(default, null):C;
	public var defaultValue(default, null):T;
	
	public function new(items:C):Void {
		if (items == null) throw "items should not be null.";
		
		this.items = items;
		this.defaultValue = null;
	}

	public function iterator():Iterator<T> {
		return items.iterator();
	}

	static public function where<T, C:Iterable<T>>(linq:LINQ<T,C>, clause:T->Int->Bool):LINQ<T,Array<T>> {
		var i = 0;
		var newArray = new Array<T>();
		for (item in linq.items) {
			if (clause(item,i++)) {
				newArray.push(item);
			}
		}
		return new LINQ(newArray);
	}

	static public function select<T, C:Iterable<T>, F>(linq:LINQ<T,C>, clause:T->Int->F):LINQ<F,Array<F>> {
		var newArray = new Array<F>();
		
		var i = 0;
		for (item in linq.items) {
			var newItem = clause(item, i++);
			if (newItem != null) {
				newArray.push(newItem);
			}
		}
		return new LINQ(newArray);
	}

	static public function orderBy<T, C:Iterable<T>, T2>(linq:LINQ<T,C>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = linq.toArray();
		var sortFn = function(a, b) {
			var x = clause(a);
			var y = clause(b);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	static public function orderByDescending<T, C:Iterable<T>, T2>(linq:LINQ<T,C>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = linq.toArray();
		var sortFn = function(a, b) {
			var x = clause(b);
			var y = clause(a);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	static public function groupBy<T, C:Iterable<T>, F>(linq:LINQ<T,C>, clause:T->F):LINQ<Grouping<F,T>,Array<Grouping<F,T>>> {
		var arrays = new Array<Grouping<F,T>>();
		
		for (item in linq.items) {
			var f = clause(item);
			var group = where(new LINQ(arrays), function(g:Grouping<F,T>, i:Int) return g.key == f).first();
			if (group == null) {	
				group = new Grouping<F,T>(f);
				arrays.push(group);
			}
			group.add(item);
		}

		return new LINQ(arrays);
	}
	
	static public function join<T, C:Iterable<T>, T2, K, R>(linq:LINQ<T,C>, inner:Iterable<T2>, outerKeySelector:T->K, innerKeySelector:T2->K, resultSelector:T->T2->R, ?comparer:K->Int->K->Int->Bool):LINQ<R,Array<R>> {
		if (comparer == null) comparer = function(ka,_,kb,_) return ka == kb;
		var result = new Array<R>();
		var i = 0;
		for (a in linq.items) {
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
	
	static public function groupJoin<T, C:Iterable<T>, T2, K, R>(linq:LINQ<T,C>, inner:Iterable<T2>, outerKeySelector:T->K, innerKeySelector:T2->K, resultSelector:T->Iterable<T2>->R, ?comparer:K->Int->K->Int->Bool):LINQ<R,Array<R>> {
		if (comparer == null) comparer = function(ka,_,kb,_) return ka == kb;
		var result = new Array<R>();
		var i = 0;
		for (a in linq.items) {
			var ka = outerKeySelector(a);
			result.push(resultSelector(a, where(new LINQ(inner), function(b,i2) return comparer(ka,i,innerKeySelector(b),i2))));
			++i;
		}
		return new LINQ(result);
	}

	static public function selectMany<T, C:Iterable<T>, F>(linq:LINQ<T,C>, clause:T->Int->Array<F>):LINQ<F,Array<F>> {
		var r = new Array<F>();
		var i = 0;
		for (item in linq.items){
			var a = clause(item, i++);
			r = r.concat(a);
		}
		return new LINQ(r);
	}

	static public function count<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):Int {
		if (clause == null) {
			var i = 0;
			for (_item in linq.items) ++i;
			return i;
		} else {
			return count(where(linq, clause));
		}
	}

	static public function aggregate<T, C:Iterable<T>, F>(linq:LINQ<T,C>, seed:F, clause:F->T->F):F {
		var result = seed;
		for (item in linq.items) {
			result = clause(result,item);
		}
		return result;
	}

	static public function min<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Float):Float {
		if (clause == null){
			return linq.aggregate(cast linq.first(), cast Math.min);
		} else {
			return linq.aggregate(clause(linq.first()), function(s:Float,i:T) return Math.min(s,clause(i)));
		}
	}

	static public function max<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Float):Float {
		if (clause == null){
			return linq.aggregate(cast linq.first(), cast Math.max);
		} else {
			return linq.aggregate(clause(linq.first()), function(s:Float,i:T) return Math.max(s,clause(i)));
		}
	}

	static public function sum<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Float):Float {
		if (clause == null){
			return linq.aggregate(0.0, function(s:Float,i:T) return s + cast i);
		} else {
			return linq.aggregate(0.0, function(s:Float,i:T) return s + clause(i));
		}
	}

	static public function average<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Float):Float {
		return linq.sum(clause)/count(linq);
	}

	static public function distinct<T, C:Iterable<T>>(linq:LINQ<T,C>, ?comparer:T->Int->T->Int->Bool):LINQ<T,Array<T>> {
		if (comparer == null) comparer = function(a,_,b,_) return a == b;
		var retVal = new Array<T>();
		var i = 0;
		for (item in linq.items) {
			if (!new LINQ(retVal).any(function(r,i2) return comparer(r,i,item,i2))) {
				retVal.push(item);
			}
			++i;
		}
		return new LINQ(retVal);
	}
	
	static public function contains<T, C:Iterable<T>>(linq:LINQ<T,C>, value:T, ?comparer:T->T->Int->Bool):Bool {
		if (comparer == null) comparer = function(a,b,i) return a == b;
		var i = 0;
		for (item in linq.items) {
			if (comparer(item, value, i++)) return true;
		}
		return false;
	}
	
	static public function empty<T, C:Iterable<T>>(linq:LINQ<T,C>):Bool {
		return !linq.items.iterator().hasNext();
	}

	static public function any<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):Bool {
		if (clause == null) return linq.items.iterator().hasNext();
		
		var i = 0;
		for (item in linq.items) {
			if (clause(item,i++)) {
				return true;
			}
		}
		return false;
	}

	static public function all<T, C:Iterable<T>>(linq:LINQ<T,C>, clause:T->Int->Bool):Bool {
		var i = 0;
		for (item in linq.items) {
			if (!clause(item,i++)) {
				return false;
			}
		}
		return true;
	}

	static public function reverse<T, C:Iterable<T>>(linq:LINQ<T,C>):LINQ<T,Array<T>> {
		var tempAry = linq.toArray();
		tempAry.reverse();
		return new LINQ(tempAry);
	}
	
	static public function single<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return if (clause == null)
			count(linq) == 1 ? linq.first() : throw "There is " + count(linq) + " items.";
		else 
			where(linq, clause).single();
	}

	static public function first<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return if (clause != null) {
			where(linq, clause).first();
		} else {
			linq.items.iterator().next();
		}
	}

	static public function last<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return if (clause != null) {
			where(linq, clause).last();
		} else {
			if (linq.any()) {
				linq.toArray().pop();
			} else {
				null;
			}
		}
	}

	static public function elementAt<T, C:Iterable<T>>(linq:LINQ<T,C>, i:Int):T {
		var count = 0;
		for (item in linq.items) {
			if (count++ == i) return item;
		}
		return null;
	}

	static public function concat<T, C:Iterable<T>>(linq:LINQ<T,C>, items:Iterable<T>):LINQ<T,Array<T>> {
		return new LINQ(linq.toArray().concat(new LINQ(items).toArray()));
	}
	
	static public function skip<T, C:Iterable<T>>(linq:LINQ<T,C>, count:Int):LINQ<T,Array<T>> {
		return linq.skipWhile(function(e,i) return i < count);
	}
	
	static public function skipWhile<T, C:Iterable<T>>(linq:LINQ<T,C>, predicate:T->Int->Bool):LINQ<T,Array<T>> {
		var i = 0;
		var newArray = new Array<T>();
		for (item in linq.items) {
			if (newArray.length > 0 || !predicate(item,i++)) {
				newArray.push(item);
			}
		}
		return new LINQ(newArray);
	}
	
	static public function take<T, C:Iterable<T>>(linq:LINQ<T,C>, count:Int):LINQ<T,Array<T>> {
		return linq.takeWhile(function(e,i) return i < count);
	}
	
	static public function takeWhile<T, C:Iterable<T>>(linq:LINQ<T,C>, predicate:T->Int->Bool):LINQ<T,Array<T>> {
		var i = 0;
		var newArray = new Array<T>();
		for (item in linq.items) {
			if (predicate(item,i++)) {
				newArray.push(item);
			} else {
				break;
			}
		}
		return new LINQ(newArray);
	}

	static public function intersect<T, C:Iterable<T>, T2>(linq:LINQ<T,C>, items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T,Array<T>> {
		if (clause == null){
			clause = function (item:T, index:Int, item2:Dynamic, index2:Int) { return item == item2; };
		}

		var result = new Array<T>();
		var ia = 0;
		for (a in linq.items) {
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
	
	static public function except<T, C:Iterable<T>, T2>(linq:LINQ<T,C>, items:Iterable<T2>, ?clause:T->Int->T2->Int->Bool):LINQ<T,Array<T>> {
		if (clause == null){
			clause = function (item:T, index:Int, item2:Dynamic, index2:Int) { return item == item2; };
		}

		var result = new Array<T>();
		var remove = new LINQ(items);
		var ia = 0;
		for (a in linq.items) {
			if (!remove.any(function(b,ib) return clause(a,ia,b,ib)))
				result.push(a);
			++ia;
		}
		return new LINQ(result);
	}

	static public function defaultIfEmpty<T, C:Iterable<T>>(linq:LINQ<T,C>, ?defaultValue:T):LINQ<T,C> {
		var r = new LINQ(linq.items);
		r.defaultValue = defaultValue;
		return r;
	}

	static public function elementAtOrDefault<T, C:Iterable<T>>(linq:LINQ<T,C>, i:Int):T {
		var count = 0;
		for (item in linq.items) {
			if (count++ == i) return item;
		}
		return linq.defaultValue;
	}
	
	static public function singleOrDefault<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return linq.any(clause) ? linq.single(clause) : linq.defaultValue;
	}

	static public function firstOrDefault<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return linq.any(clause) ? linq.first(clause) : linq.defaultValue;
	}

	static public function lastOrDefault<T, C:Iterable<T>>(linq:LINQ<T,C>, ?clause:T->Int->Bool):T {
		return linq.any(clause) ? linq.last(clause) : linq.defaultValue;
	}
	
	static public function ofType<T, C:Iterable<T>, T2>(linq:LINQ<T,C>, type:Class<T2>):LINQ<T2,Array<T2>> {
		var newArray = new Array<T2>();
		for (item in linq.items) {
			if (Std.is(item,type)) {
				newArray.push(cast item);
			}
		}
		return new LINQ(newArray);
	}
	
	static public function toArray<T, C:Iterable<T>>(linq:LINQ<T,C>):Array<T> {
		var array = [];
		for (_item in linq.items){
			array.push(_item);
		}
		return array;
	}
	
	static public function toList<T, C:Iterable<T>>(linq:LINQ<T,C>):List<T> {
		var list = new List<T>();
		for (_item in linq.items){
			list.add(_item);
		}
		return list;
	}
}