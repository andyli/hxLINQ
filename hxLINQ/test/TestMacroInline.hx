package hxLINQ.test;

import haxe.unit.TestCase;
import hxLINQ.macro.Inline;

class TestMacroInline extends TestCase
{
	public function new() { super(); }
	
	public function testSimpleCases():Void {
		var a = 123;
		
		assertEquals(123, Inline.eFunctionToEBlock(function() return a));
		
		assertEquals(123, Inline.eFunctionToEBlock(function(_) return a));
		
		assertEquals(456, Inline.eFunctionToEBlock(function(a = 456) return a));
		
		assertEquals(123, a);
		
		assertEquals(456, Inline.eFunctionToEBlock(function(a) { a = 456; return a; } ));
		
		assertEquals(456, Inline.eFunctionToEBlock(function(a) { a = 456; return a; }, [123]));
		
		assertEquals(123, a);
		
		assertEquals(null, Inline.eFunctionToEBlock(function() return));
		
		
		assertEquals(456, Inline.eFunctionToEBlock(function() return switch(a) {
			case 123: 456;
		}));
	}
	
	public function testWithArgs():Void {
		assertEquals(123, Inline.eFunctionToEBlock(function(_) return _, [123]));
		
		assertEquals(246, Inline.eFunctionToEBlock(function(_) return _ * 2, [123]));
		
		assertEquals(123, Inline.eFunctionToEBlock(function(_ = 456) return _, [123]));
	}
	
	public function testComplexReturn():Void {
		var a = 123, b = 456;
		assertEquals(123, Inline.eFunctionToEBlock(function() return true ? a : b));
		assertEquals(456, Inline.eFunctionToEBlock(function() return false ? a : b));
		
		assertEquals(123, Inline.eFunctionToEBlock(function() if (true) return a; else return b));
		
		assertEquals(null, Inline.eFunctionToEBlock(function() if (true) return; else return));
	}
	
	public function testInlineWithLocalFunction():Void {
		var a = 123;
		
		assertEquals(123, Inline.eFunctionToEBlock(function() {
			var localFunction = function () { }
			return a;
		}));
	
		assertEquals(123, Inline.eFunctionToEBlock(function() {
			var localFunction = function () { return a; }
			return localFunction();
		}));
	
		assertEquals(456, Inline.eFunctionToEBlock(function() {
			return function (a = 456) { return a; }();
		}));
		
		assertEquals(456, Inline.eFunctionToEBlock(function() {
			function test0() { return 456; }
			return test0;
		})());
	}
}