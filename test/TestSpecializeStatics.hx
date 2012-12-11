#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class A {
	static public function a<T>(_a:T):T {
		return _a;
	}
}

#if !macro
@:build(hxLINQ.macro.SpecializeStatics.build(A, [cast(T,String)]))
#end
class A_String {

}

class B {
	static public function b<T1,T2>(b1:T1, b2:T2):T1 {
		return b1;
	}
}

#if !macro
@:build(hxLINQ.macro.SpecializeStatics.build(B, [cast(T1,String), cast(T2,Int)]))
#end
class B_StringInt {

}

#if !macro
@:build(hxLINQ.macro.SpecializeStatics.build(B, [cast(T2,String)]))
#end
class B_String {

}


class C<C1,C2> {
	public var c1:C1;
	public var c2:C2;
	
	public function new(c1:C1, c2:C2):Void {
		this.c1 = c1;
		this.c2 = c2;
	}
	
	static public function c<T, A:Iterable<T>>(_c:C<T,A>, clause:A->Array<T>):C<T,Array<T>> {
		return null;//new C(_c.c1, clause(_c.c2));
	}
}

#if !macro
@:build(hxLINQ.macro.SpecializeStatics.build(C, [cast(A, Array<T>)]))
#end
class C_Array {

}

class TestSpecializeStatics extends haxe.unit.TestCase {
	@:macro public static function typeOf(e:Expr):ExprOf<String> {
		var type = Std.string(Context.typeof(e));
		return Context.makeExpr(type, e.pos);
	}
	
	#if !macro
	public function testAClassFields():Void {
		var classFields = Type.getClassFields(A_String);
		this.assertEquals(1, classFields.length);
		this.assertEquals("a", classFields[0]);
		this.assertEquals("TFun([{ name => _a, t => TInst(String,[]), opt => false }],TInst(String,[]))", typeOf(A_String.a));
	}
	public function testAInstanceFields():Void {
		var classFields = Type.getInstanceFields(A_String);
		this.assertEquals(0, classFields.length);
	}
	
	public function testBClassFields():Void {
		var classFields = Type.getClassFields(B_StringInt);
		this.assertEquals(1, classFields.length);
		this.assertEquals("b", classFields[0]);
		this.assertEquals("TFun([{ name => b1, t => TInst(String,[]), opt => false },{ name => b2, t => TAbstract(Int,[]), opt => false }],TInst(String,[]))", typeOf(B_StringInt.b));

		var classFields = Type.getClassFields(B_String);
		this.assertEquals(1, classFields.length);
		this.assertEquals("b", classFields[0]);
		this.assertEquals(1, B_String.b(1, "2"));
	}
	public function testBInstanceFields():Void {
		var classFields = Type.getInstanceFields(B_StringInt);
		this.assertEquals(0, classFields.length);
	}
	
	public function testC() {
		C_Array.c(new C("a", []), function(l) return l);
		this.assertTrue(true);
	}
	
	public static function main():Void {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestSpecializeStatics());
		runner.run();
	}
	#end
}