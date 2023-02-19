package funkin;

import flixel.util.FlxColor;
import funkin.ui.JudgementCounter;

using StringTools;

// File rewritten to fit newest Forever Engine Rewrite schema

typedef Judgement =
{
	var name:String;
	var timing:Float;
	var score:Int;
	var accuracy:Float;
	var health:Float;
	var comboStatus:Null<String>;
}

class Timings {}
