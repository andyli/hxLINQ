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
	}
	
}