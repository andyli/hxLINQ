package hxLINQ.iterable;

using hxLINQ.LINQ;

class OrderedLINQtoIterable {
	static public function thenBy<T, C:Iterable<T>, T2>(linq:OrderedLINQ<T,C>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray:Array<T> = linq.toArray();
		var _sortFns = linq.sortFns.concat([
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

	static public function thenByDescending<T, C:Iterable<T>, T2>(linq:OrderedLINQ<T,C>, clause:T->T2):OrderedLINQ<T,Array<T>> {
		var tempArray:Array<T> = linq.toArray();
		var _sortFns = linq.sortFns.concat([
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