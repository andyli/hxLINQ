package hxLINQ.test;
import haxe.unit.TestRunner;

class TestAll 
{		
	static public function main() 
	{
		var runner = new TestRunner();
		runner.add(new hxLINQ.test.TestMacroInline());
		runner.run();
	}
	
}