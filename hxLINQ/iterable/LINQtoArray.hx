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
}
