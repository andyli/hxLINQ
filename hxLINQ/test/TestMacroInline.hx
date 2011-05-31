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
		
		assertEquals(123, a);
		
		assertEquals(null, Inline.eFunctionToEBlock(function() return));
	}
	
	public function testComplexReturn():Void {
		var a = 123, b = 456;
		assertEquals(123, Inline.eFunctionToEBlock(function() return true ? a : b));
		assertEquals(456, Inline.eFunctionToEBlock(function() return false ? a : b));
		
		assertEquals(123, Inline.eFunctionToEBlock(function() if (true) return a; else return b));
		
		assertEquals(null, Inline.eFunctionToEBlock(function() if (true) return; else return));
	}
}