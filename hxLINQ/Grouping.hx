package hxLINQ;

@:allow(hxLINQ)
class Grouping<K,V> {
	public var key(default,null):K;
	private var values:Array<V>;

	public function new(key:K):Void {
		this.key = key;
		values = new Array<V>();
	}

	private function add(val:V):Void {
		values.push(val);
	}

	public function iterator():Iterator<V> {
		return values.iterator();
	}
}