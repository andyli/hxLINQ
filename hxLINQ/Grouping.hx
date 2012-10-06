package hxLINQ;

@:allow(hxLINQ)
class Grouping<K,V> {
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