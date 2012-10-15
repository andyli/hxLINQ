package hxLINQ.iterable;

using hxLINQ.LINQ;

class LINQtoArray {
	static public function count<T>(linq:LINQ<T,Array<T>>, ?clause:T->Int->Bool):Int {
		return if (clause == null) {
			linq.items.length;
		} else {
			linq.where(clause).count();
		}
	}
}
