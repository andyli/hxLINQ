import hxLINQ.LINQ;

import hxLINQ.LINQ;
using hxLINQ.LINQ;
using Lambda;
using Math;

import hxLINQ.macro.Helper;
using hxLINQ.macro.Helper;

typedef A = Array<String>;

class Test {
	static function main():Void {
		trace(Helper.dumpExpr(-a.pop(), b));
		var a:A;
		trace(a.linq().where(function(i, n) return i.charAt(0) == "a").toArray());
		//trace(new LINQ([123]).where(function(i, n) return true).toArray());
	}
}
/*
typedef Person = { id:Int , firstName:String, lastName:String, bookIds:Array<Int> };

class Test extends haxe.unit.TestCase{
	public function testWhere():Void {
		var r;
		
		r = 	new LINQ(people)
				.where(function(p:Person, i:Int) return p.firstName == "Chris");
		this.assertEquals(2,r.count());

		r = 	new LINQ(people)
				.where(function(p:Person, i:Int) return p.firstName == "Chris" && i == 0);
		this.assertEquals(1,r.count());
	}

	public function testSelect():Void {
		var r;

		r = new LINQ(people)
				.select(function(p:Person) return p.firstName);
		this.assertEquals(10,r.count());
		this.assertTrue(Std.is(r.first(),String));
	}

	public function testSelectMany():Void {
		var r;

		r = new LINQ(people)
				.selectMany(function(p:Person) return p.bookIds);
		this.assertEquals(30,r.count());
		this.assertTrue(Std.is(r.first(),Int));
	}

	public function testOrderBy():Void {
		var r;

		r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0));
		this.assertEquals(10,r.count());
		this.assertEquals("Bernard",r.first().firstName);
		this.assertEquals("Steve",r.last().firstName);
	}

	public function testOrderByDescending():Void {
		var r;

		r = new LINQ(people)
				.orderByDescending(function(p:Person) return p.firstName.charCodeAt(0));
		this.assertEquals(10,r.count());
		this.assertEquals("Bernard",r.last().firstName);
		this.assertEquals("Steve",r.first().firstName);
	}
	
	public function testOrderByString():Void {
		var r;

		r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName);
		this.assertEquals(10, r.count());
		this.assertEquals("Bernard",r.first().firstName);
		this.assertEquals("Steve",r.last().firstName);
	}

	public function testOrderByStringDescending():Void {
		var r;

		r = new LINQ(people)
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

		r = new LINQ([235,3635,585,-1,-1.1,1000])
				.min();
		this.assertEquals(-1.1,r);
	}

	public function testMax():Void {
		var r = new LINQ(people)
					.max(function (p:Person) return p.id);
		this.assertEquals(10, cast r);

		r = new LINQ([235,3635,585,-1,-1.1,1000])
				.max();
		this.assertEquals(3635,cast r);
	}

	public function testSum():Void {
		var r = new LINQ(people)
					.sum(function (p:Person) return p.id);
		this.assertEquals(55.0, r);

		r = new LINQ([235,3635,585,-1,-1.1,1000])
				.sum();
		this.assertEquals(235+3635+585-1-1.1+1000,r);
	}

	public function testAverage():Void {
		var r = new LINQ(people)
					.average(function (p:Person) return p.id);
		this.assertEquals(5.5, r);

		r = new LINQ([235,3635,585,-1,-1.1,1000])
				.average();
		this.assertEquals((235+3635+585-1-1.1+1000)/6,r);
	}

	public function testCount():Void {
		this.assertEquals(10,new LINQ(people).count());

		var r = new LINQ(people)
					.count(function (p:Person, i:Int) return p.firstName == "Chris");
		this.assertEquals(2,r);

		r = new LINQ(people)
				.count(function (p:Person, i:Int) return p.firstName == "Chris" && i == 4);
		this.assertEquals(0,r);
	}

	public function testDistinct():Void {
		var r;

		r = new LINQ(people)
				.distinct(function(p:Person) return p.firstName);
		this.assertEquals(8,r.count());
	}

	public function testAny():Void {
		var r;

		r = new LINQ(people)
				.any(function(p:Person, i:Int) return p.firstName == "Chris");
		this.assertTrue(r);

		r = new LINQ(people)
				.any(function(p:Person, i:Int) return p.firstName == "Chris" && i == 4);
		this.assertFalse(r);
	}

	public function testAll():Void {
		var r;

		r = new LINQ(people)
				.all(function(p:Person, i:Int) return p.firstName == "Chris");
		this.assertFalse(r);

		r = new LINQ(people)
				.all(function(p:Person, i:Int) return p.firstName == "Chris" && i == 0);
		this.assertFalse(r);
	}

	public function testReverse():Void {
		var r;

		r = new LINQ(people)
				.reverse();
		this.assertEquals(10,r.count());
		this.assertEquals("Kate",r.first().firstName);
		this.assertEquals("Chris",r.last().firstName);
	}

	public function testFirst():Void {
		var r;

		r = new LINQ(people)
				.first(function(p:Person,i:Int) return p.firstName == "Chris");
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(1,r.id);

		r = new LINQ(people)
				.first(function(p:Person,i:Int) return p.firstName == "Chris" && i == 0);
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(1,r.id);
	}

	public function testLast():Void {
		var r;

		r = new LINQ(people)
				.last(function(p:Person,i:Int) return p.firstName == "Chris");
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(8,r.id);

		r = new LINQ(people)
				.last(function(p:Person,i:Int) return p.firstName == "Chris" && i == 0);
		this.assertEquals("Chris",r.firstName);
		this.assertEquals(1,r.id);
	}

	public function testElementAt():Void {
		var r;

		r = new LINQ(people)
				.elementAt(1);
		this.assertEquals("Kate",r.firstName);
		this.assertEquals(2,r.id);
	}

	public function testIntersect():Void {
		var nameList1 = ["Chris","Steve","John"];
        var nameList2 = ["Katie","Chris","John", "Aaron"];
        var sample = new LINQ(nameList1).intersect(nameList2);
        this.assertEquals(2,sample.count());

        sample = new LINQ(nameList1)
        				.intersect(new LINQ(nameList2));
        this.assertEquals(2,sample.count());

        var sample2 = new LINQ(people)
        				.intersect(nameList2, function(item:Person, index:Int, item2:String, index2:Int) return item.firstName == item2);
        	this.assertEquals(4,sample2.count());
	}

	public function testDefaultIfEmpty():Void {
		var r;

		r = new LINQ([])
				.defaultIfEmpty(new LINQ(people));
		this.assertEquals(10,r.count());

		r = new LINQ([])
				.defaultIfEmpty(people);
		this.assertEquals(10,r.count());
	}

	public function testElementAtOrDefault():Void {
		var r;
		var defualt = { id: 0, firstName: "", lastName: "", bookIds: [] };

		r = new LINQ(people)
				.elementAtOrDefault(150,defualt);
		this.assertEquals(defualt,r);
	}

	public function testFirstOrDefault():Void {
		var r;
		var defualt = { id: 999, firstName: "Johny", lastName: "Stone", bookIds:[999]};

		r = new LINQ(people)
				.firstOrDefault(defualt);
		this.assertEquals("Chris",r.firstName);
	}

	public function testLastOrDefault():Void {
		var r;
		var defualt = { id: 999, firstName: "Johny", lastName: "Stone", bookIds:[999]};

		r = new LINQ(people)
				.lastOrDefault(defualt);
		this.assertEquals("Kate",r.firstName);
	}

	public function testGroupBy():Void {
		var r;

		r = new LINQ(people)
				.groupBy(function(p:Person) return p.firstName.charAt(0));
		
		this.assertEquals(6,r.count());
	}

	public function testThenBy():Void {
		var r;

		r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0))
				.thenBy(function(p:Person) return p.lastName.charCodeAt(0))
				.select(function(p:Person) return p.id);
		this.assertEquals(10,r.count());
		this.assertEquals("9,1,8,7,4,3,2,10,6,5",r.array().join(","));
	}

	public function testThenByDescending():Void {
		var r;

		r = new LINQ(people)
				.orderBy(function(p:Person) return p.firstName.charCodeAt(0))
				.thenByDescending(function(p:Person) return p.lastName.charCodeAt(0))
				.select(function(p:Person) return p.id);
		this.assertEquals(10,r.count());
		this.assertEquals("9,8,1,7,3,4,6,10,2,5",r.array().join(","));
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

	public static function main():Void {
		var runner = new haxe.unit.TestRunner();
		runner.add(new Test());
		runner.run();
	}
}
*/