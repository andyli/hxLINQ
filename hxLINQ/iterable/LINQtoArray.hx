package hxLINQ.iterable;

using hxLINQ.LINQ;

class LINQtoArray {
	static public function orderBy<T, T2>(linq:LINQ<T,Array<T>>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = linq.items.copy();
		var sortFn = function(a, b) {
			var x = clause(a);
			var y = clause(b);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}

	static public function orderByDescending<T, T2>(linq:LINQ<T,Array<T>>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray = linq.items.copy();
		var sortFn = function(a, b) {
			var x = clause(b);
			var y = clause(a);
			return Reflect.compare(x,y);
		}
		tempArray.sort(sortFn);

		return new OrderedLINQ(tempArray, [sortFn]);
	}
	
	static public function count<T>(linq:LINQ<T,Array<T>>, ?clause:T->Int->Bool):Int {
		return if (clause == null) {
			linq.items.length;
		} else {
			linq.where(clause).count();
		}
	}

	static public function reverse<T>(linq:LINQ<T,Array<T>>):LINQ<T,Array<T>> {
		var tempAry = linq.items.copy();
		tempAry.reverse();
		return new LINQ(tempAry);
	}

	static public function any<T>(linq:LINQ<T,Array<T>>, ?clause:T->Bool):Bool {
		if (clause == null) return linq.items.length > 0;
		
		for (item in linq.items) {
			if (clause(item)) {
				return true;
			}
		}
		return false;
	}

	inline static public function first<T>(linq:LINQ<T,Array<T>>, ?clause:T->Bool):T {
		return if (clause != null) {
			linq.where(function(e,i) return clause(e)).first();
		} else {
			linq.items[0];
		}
	}

	inline static public function last<T>(linq:LINQ<T,Array<T>>, ?clause:T->Bool):T {
		return if (clause != null) {
			linq.where(function(e,i) return clause(e)).last();
		} else {
			if (linq.any()) {
				linq.items[linq.items.length-1];
			} else {
				null;
			}
		}
	}

	inline static public function elementAt<T>(linq:LINQ<T,Array<T>>, i:Int):T {
		return linq.items[i];
	}

	inline static public function concat<T>(linq:LINQ<T,Array<T>>, items:Iterable<T>):LINQ<T,Array<T>> {
		return new LINQ(linq.items.concat(new LINQ(items).toArray()));
	}

	inline static public function elementAtOrDefault<T>(linq:LINQ<T,Array<T>>, i:Int):T {
		return if (i < linq.items.length)
			linq.items[i];
		else
			linq.defaultValue;
	}
	
	inline static public function toArray<T>(linq:LINQ<T,Array<T>>):Array<T> {
		return linq.items.copy();
	}
}
