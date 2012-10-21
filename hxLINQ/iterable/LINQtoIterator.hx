package hxLINQ.iterable;

using hxLINQ.LINQ;

class LINQtoIterator {
	static public function linq<T>(iterator:Iterator<T>):LINQ<T,Iterable<T>> {
		return new LINQ({
			iterator:function() return iterator
		});
	}
}