package hxLINQ;

@:allow(hxLINQ)
class LINQ<T,C:Iterable<T>> {
	inline static public function linq<T,C:Iterable<T>>(iterable:C):LINQ<T,C> {
		return new LINQ(iterable);
	}
	
	public var items(default, null):#if js Iterable<T> #else C #end;
	public var defaultValue(default, null):T;
	
	public function new(items:C):Void {
		if (items == null) throw "items should not be null.";
		
		this.items = items;
		this.defaultValue = null;
	}
}

@:allow(hxLINQ)
class OrderedLINQ<T,C:Iterable<T>> extends LINQ<T,C> {
	private var sortFns:Array<T->T->Int>;

	public function new(dataItems:C, sortFns:Array<T->T->Int>) {
		super(dataItems);
		this.sortFns = sortFns;
	}
}

typedef LINQtoIterable = hxLINQ.iterable.LINQtoIterable;
typedef OrderedLINQtoIterable = hxLINQ.iterable.OrderedLINQtoIterable;

typedef LINQtoIterator = hxLINQ.iterable.LINQtoIterator;

typedef LINQtoArray = hxLINQ.iterable.LINQtoArray;
typedef OrderedLINQtoArray = hxLINQ.iterable.OrderedLINQtoArray;