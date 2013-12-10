import haxe.ds.*;
using hxLINQ.LINQ;

typedef Person = { id:Int , firstName:String, lastName:String, bookIds:Array<Int> };

@:expose
class Test extends haxe.unit.TestCase{
	public function testWhere():Void {
		var r = new LINQ(people)
				.where(function(p:Person, i:Int) return p.firstName == "Chris");
		this.assertEquals(2,r.count());

		var r = new LINQ(people)
				.where(function(p:Person, i:Int) return p.firstName == "Chris" && i == 0);
		this.assertEquals(1,r.count());
	}

	public function testSelect():Void {
		var r = new LINQ(people)
				.select(function(p:Person,_) return p.firstName);
		this.assertEquals(10,r.count());
		this.assertTrue(Std.is(r.first(),String));
	}

	public function testSelectMany():Void {
		var r = new LINQ(people)
				.selectMany(function(p:Person,_) return p.bookIds);
		this.assertEquals(30,r.count());
		this.assertTrue(Std.is(r.first(),Int));
	}
	
	public function testSkip():Void {
		var r = new LINQ(people).skip(2);
		this.assertEquals(8, r.count());
	}
	
	public function testTake():Void {
		var r = new LINQ(people).take(2);
		this.assertEquals(2, r.count());
	}

	public function testOrderBy():Void {
		var r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0));
		this.assertEquals(10,r.count());
		this.assertEquals("Bernard",r.first().firstName);
		this.assertEquals("Steve",r.last().firstName);
	}

	public function testOrderByDescending():Void {
		var r = new LINQ(people)
				.orderByDescending(function(p:Person) return p.firstName.charCodeAt(0));
		this.assertEquals(10,r.count());
		this.assertEquals("Bernard",r.last().firstName);
		this.assertEquals("Steve",r.first().firstName);
	}
	
	public function testOrderByString():Void {
		var r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName);
		this.assertEquals(10, r.count());
		this.assertEquals("Bernard",r.first().firstName);
		this.assertEquals("Steve",r.last().firstName);
	}

	public function testOrderByStringDescending():Void {
		var r = new LINQ(people)
				.orderByDescending(function(p:Person) return p.firstName);
		this.assertEquals(10,r.count());
		this.assertEquals("Bernard",r.last().firstName);
		this.assertEquals("Steve",r.first().firstName);
	}

	public function testAggregate():Void {
		var r = new LINQ(people)
					.aggregate(0, function (i:Int, p:Person) return i+p.bookIds.length);
		this.assertEquals(30,r);
	}

	public function testMin():Void {
		var r = new LINQ(people)
					.min(function (p:Person) return p.id);
		this.assertEquals(1, cast r);

		var r = new LINQ([235,3635,585,-1,-1.1,1000])
				.min();
		this.assertEquals(-1.1,r);
	}

	public function testMax():Void {
		var r = new LINQ(people)
					.max(function (p:Person) return p.id);
		this.assertEquals(10, cast r);

		var r = new LINQ([235,3635,585,-1,-1.1,1000])
				.max();
		this.assertEquals(3635,cast r);
	}

	public function testSum():Void {
		var r = new LINQ(people)
					.sum(function (p:Person) return p.id);
		this.assertEquals(55.0, r);

		var r = new LINQ([235,3635,585,-1,-1.1,1000])
				.sum();
		this.assertEquals(235+3635+585-1-1.1+1000,r);
	}

	public function testAverage():Void {
		var r = new LINQ(people)
					.average(function (p:Person) return p.id);
		this.assertEquals(5.5, r);

		var r = new LINQ([235,3635,585,-1,-1.1,1000])
				.average();
		this.assertEquals((235+3635+585-1-1.1+1000)/6,r);
	}

	public function testCount():Void {
		this.assertEquals(10,new LINQ(people).count());

		var r = new LINQ(people)
					.count(function (p:Person) return p.firstName == "Chris");
		this.assertEquals(2,r);
	}

	public function testDistinct():Void {
		var r = new LINQ(people)
				.distinct(function(p:Person,p2:Person) return p.firstName == p2.firstName);
		this.assertEquals(8,r.count());
		
		var r = new LINQ(people)
				.distinct();
		this.assertEquals(10,r.count());
		
		var r = new LINQ([1,1,1])
				.distinct();
		this.assertEquals(1,r.count());
	}

	public function testAny():Void {
		var r = new LINQ(people).any();
		this.assertTrue(r);
		
		var r = new LINQ([null]).any();
		this.assertTrue(r);
		
		var r = new LINQ([]).any();
		this.assertFalse(r);
		
		var r = new LINQ(people)
				.any(function(p:Person) return p.firstName == "Chris");
		this.assertTrue(r);
	}

	public function testEmpty():Void {
		var r = new LINQ(people).empty();
		this.assertFalse(r);
		
		var r = new LINQ([null]).empty();
		this.assertFalse(r);
		
		var r = new LINQ([]).empty();
		this.assertTrue(r);
	}

	public function testContains():Void {
		var p = people[1];		
		var r = new LINQ(people)
				.contains(p);
		this.assertTrue(r);

		var r = new LINQ(people)
				.contains(null);
		this.assertFalse(r);
	}

	public function testAll():Void {
		var r = new LINQ(people)
				.all(function(p:Person) return p.firstName == "Chris");
		this.assertFalse(r);
		
		var r = new LINQ([1, 1, 1])
				.all(function(n) return n == 1);
		this.assertTrue(r);
	}

	public function testReverse():Void {
		var r = new LINQ(people)
				.reverse();
		this.assertEquals(10,r.count());
		this.assertEquals("Kate",r.first().firstName);
		this.assertEquals("Chris",r.last().firstName);
	}
	
	public function testSingle():Void {
		var r = new LINQ([1]).single();
		this.assertEquals(1, r);
		
		try {
			new LINQ(people).single();
			this.assertTrue(false);
		} catch (e:Dynamic) {
			this.assertTrue(true);
		}
		
		var r = new LINQ(people).single(function(p) return p.firstName == "Josh");
		this.assertEquals("Josh", r.firstName);
	}
	
	public function testSingleOrDefault():Void {
		var r = new LINQ([1]).singleOrDefault();
		this.assertEquals(1, r);
		
		try {
			new LINQ(people).singleOrDefault();
			this.assertTrue(false);
		} catch (e:Dynamic) {
			this.assertTrue(true);
		}
		
		var r = new LINQ([]).singleOrDefault();
		this.assertEquals(null, r);
		
		var r = new LINQ(people).singleOrDefault(function(p) return p.firstName == "ABC");
		this.assertEquals(null, r);
	}

	public function testFirst():Void {
		var r = new LINQ(people)
				.first(function(p:Person) return p.firstName == "Chris");
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(1,r.id);
	}

	public function testLast():Void {
		var r = new LINQ(people)
				.last(function(p:Person) return p.firstName == "Chris");
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(8,r.id);
	}

	public function testElementAt():Void {
		var r = new LINQ(people)
				.elementAt(1);
		this.assertEquals("Kate",r.firstName);
		this.assertEquals(2,r.id);
	}
	
	public function testSequenceEqual():Void {
		var r = new LINQ(people).sequenceEqual(people);
		this.assertTrue(r);
		
		var r = new LINQ([1,2,3]).sequenceEqual([3,2,1]);
		this.assertFalse(r);
		
		var r = new LINQ([1,2,3]).sequenceEqual([1,2,3,4]);
		this.assertFalse(r);
		
		var r = new LINQ([1,2,3,4]).sequenceEqual([1,2,3]);
		this.assertFalse(r);
	}
	
	public function testUnion():Void {
		var ints1 = [0, 1, 2];
		var ints2 = [1, 2, 3];
		var r = new LINQ(ints1).union(ints2);
		this.assertEquals(4, r.count());
		
		var ints1 = [5, 3, 9, 7, 5, 9, 3, 7];
		var ints2 = [8, 3, 6, 4, 4, 9, 1, 0];
		var r = new LINQ(ints1).union(ints2).distinct();
		this.assertEquals("5 3 9 7 8 6 4 1 0", r.toArray().join(" "));
	}

	public function testIntersect():Void {
		var nameList1 = ["Chris","Steve","John"];
		var nameList2 = ["Katie","Chris","John", "Aaron"];
		var sample = new LINQ(nameList1).intersect(nameList2);
		this.assertEquals(2,sample.count());

		sample = new LINQ(nameList1)
			.intersect(nameList2);
		this.assertEquals(2,sample.count());

		var sample2 = new LINQ(people)
			.intersect(nameList2, function(item:Person, item2:String) return item.firstName == item2);
		this.assertEquals(4,sample2.count());
	}
	
	public function testExcept():Void {
		var e = people[1];
		
		var r = new LINQ(people)
			.except([e]);
		this.assertEquals(people.length - 1, r.count());
		this.assertFalse(r.any(function(p) return p == e));
		
		var r = new LINQ(people)
			.except([]);
		this.assertEquals(people.length, r.count());
	}

	public function testDefaultIfEmpty():Void {
		var r = new LINQ([])
				.defaultIfEmpty(123);
		this.assertEquals(123,r.firstOrDefault());
		
		var r = new LINQ([])
				.defaultIfEmpty();
		this.assertEquals(null,r.firstOrDefault());
		
		var r = new LINQ<Null<Int>, Array<Null<Int>>>([])
				.defaultIfEmpty(123)
				.defaultIfEmpty();
		this.assertEquals(null,r.firstOrDefault());
	}

	public function testElementAtOrDefault():Void {
		var d = { id: 0, firstName: "", lastName: "", bookIds: [] };

		var r = new LINQ(people)
			.elementAtOrDefault(150);
		this.assertEquals(null,r);

		var r = new LINQ(people)
			.defaultIfEmpty(d)
			.elementAtOrDefault(150);
		this.assertEquals(d,r);
	}

	public function testFirstOrDefault():Void {
		var d = { id: 999, firstName: "Johny", lastName: "Stone", bookIds:[999]};

		var r = new LINQ([])
			.firstOrDefault();
		this.assertEquals(null, r);
		
		var r = new LINQ([])
			.defaultIfEmpty(d)
			.firstOrDefault();
		this.assertEquals("Johny",r.firstName);
		
		var r = new LINQ(people)
			.firstOrDefault();
		this.assertEquals("Chris",r.firstName);
		
		var r = new LINQ(people)
			.defaultIfEmpty(d)
			.firstOrDefault();
		this.assertEquals("Chris",r.firstName);
	}

	public function testLastOrDefault():Void {
		var d = { id: 999, firstName: "Johny", lastName: "Stone", bookIds:[999]};

		var r = new LINQ([])
			.lastOrDefault();
		this.assertEquals(null, r);
		
		var r = new LINQ([])
			.defaultIfEmpty(d)
			.lastOrDefault();
		this.assertEquals("Johny",r.firstName);
		
		var r = new LINQ(people)
			.lastOrDefault();
		this.assertEquals("Kate",r.firstName);
		
		var r = new LINQ(people)
			.defaultIfEmpty(d)
			.lastOrDefault();
		this.assertEquals("Kate",r.firstName);

		var r = new LINQ([])
				.lastOrDefault();
		this.assertEquals(null, r);
	}

	public function testGroupBy():Void {
		var r = new LINQ(people)
				.groupBy(function(p:Person) return p.firstName.charAt(0));
		
		this.assertEquals(6,r.count());
	}

	public function testJoin():Void {
		var magnus = { name: "Hedlund, Magnus" };
		var terry = { name: "Adams, Terry" };
		var charlotte = { name: "Weiss, Charlotte" };

		var barley = { name: "Barley", owner: terry };
		var boots = { name: "Boots", owner: terry };
		var whiskers = { name: "Whiskers", owner: charlotte };
		var daisy = { name: "Daisy", owner: magnus };

		var people = [magnus, terry, charlotte];
		var pets = [barley, boots, whiskers, daisy];

		// Create a list of Person-Pet pairs where 
		// each element is an anonymous type that contains a  
		// Pet's name and the name of the Person that owns the Pet. 
		var query = new LINQ(people)
			.join(
				pets,
				function(person) return person,
				function(pet) return pet.owner,
				function(person, pet) return {
					ownerName: person.name,
					pet: pet.name
				}
			);
		
		this.assertEquals(4,query.count());
		
		this.assertEquals("Daisy",query.elementAt(0).pet);
		
		this.assertEquals(2,query.count(function(pair) return pair.ownerName == "Adams, Terry"));
	}

	public function testGroupJoin():Void {
		var magnus = { name: "Hedlund, Magnus" };
		var terry = { name: "Adams, Terry" };
		var charlotte = { name: "Weiss, Charlotte" };

		var barley = { name: "Barley", owner: terry };
		var boots = { name: "Boots", owner: terry };
		var whiskers = { name: "Whiskers", owner: charlotte };
		var daisy = { name: "Daisy", owner: magnus };

		var people = [magnus, terry, charlotte];
		var pets = [barley, boots, whiskers, daisy];

		// Create a list where each element is an anonymous  
		// type that contains a person's name and  
		// a collection of names of the pets they own. 
		var query = new LINQ(people)
			.groupJoin(
				pets,
				function(person) return person,
				function(pet) return pet.owner,
				function(person, petCollection) return {
					ownerName: person.name,
					pets: new LINQ(petCollection).select(function(pet,_) return pet.name)
				}
			);
		
		this.assertEquals(3,query.count());
		
		this.assertEquals("Adams, Terry",query.elementAt(1).ownerName);
		
		this.assertEquals(2,query.elementAt(1).pets.count());
	}

	public function testThenBy():Void {
		var r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0))
				.thenBy(function(p:Person) return p.lastName.charCodeAt(0))
				.select(function(p:Person,_) return p.id);
		this.assertEquals(10,r.count());
		this.assertEquals("9,1,8,7,4,3,2,10,6,5",r.toArray().join(","));
	}

	public function testThenByDescending():Void {
		var r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0))
				.thenByDescending(function(p:Person) return p.lastName.charCodeAt(0))
				.select(function(p:Person,_) return p.id);
		this.assertEquals(10,r.count());
		this.assertEquals("9,8,1,7,3,4,6,10,2,5",r.toArray().join(","));
	}
	
	public function testIterator():Void {
		var hash = new StringMap();
		for (i in 65...70) hash.set(String.fromCharCode(i), i);
		
		var r = hash.keys().linq();
		this.assertEquals(5, r.count());
	}

	static public var people:Array<Person> = [
		{ id: 1, firstName: "Chris", lastName: "Pearson", bookIds: [1001, 1002, 1003] },
		{ id: 2, firstName: "Kate", lastName: "Johnson", bookIds: [2001, 2002, 2003] },
		{ id: 3, firstName: "Josh", lastName: "Sutherland", bookIds: [3001, 3002, 3003] },
		{ id: 4, firstName: "John", lastName: "Ronald", bookIds: [4001, 4002, 4003] },
		{ id: 5, firstName: "Steve", lastName: "Pinkerton", bookIds: [1001, 1002, 1003] },
		{ id: 6, firstName: "Katie", lastName: "Zimmerman", bookIds: [2001, 2002, 2003] },
		{ id: 7, firstName: "Dirk", lastName: "Anderson", bookIds: [3001, 3002, 3003] },
		{ id: 8, firstName: "Chris", lastName: "Stevenson", bookIds: [4001, 4002, 4003] },
		{ id: 9, firstName: "Bernard", lastName: "Sutherland", bookIds: [1001, 2002, 3003] },
		{ id: 10, firstName: "Kate", lastName: "Pinkerton", bookIds: [4001, 3002, 2003] }
	];

	public static var success:Bool;

	public static function main():Void {
		#if js
		var buf = new StringBuf();
		haxe.unit.TestRunner.print = buf.add;
		#end

		var runner = new haxe.unit.TestRunner();
		runner.add(new Test());
		success = runner.run();

		#if sys
		Sys.exit(success ? 0 : 1);
		#elseif js
		untyped __js__("console.log")(buf.toString());
		if (untyped __js__("process") != null) (untyped __js__("process")).exit(success ? 0 : 1);
		#end
	}
}
