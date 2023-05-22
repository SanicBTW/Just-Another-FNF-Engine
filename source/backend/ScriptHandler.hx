package backend;

import base.Conductor;
import flixel.*;
import flixel.math.*;
import flixel.tweens.*;
import flixel.util.*;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;

/***
 *  Mix between my [FE:R HTML5 Port](https://github.com/SanicBTW/FNF-Forever-Engine/blob/master/source/base/ScriptHandler.hx),
 *  [HXS Branch on my PE 0.3.2h repo](https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/tree/hxs-forever/source) and
 *  some cancelled Lullaby code
 */
class Colors
{
	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
		return FlxColor.fromRGB(Red, Green, Blue, Alpha);
}

/**
 * Handles the Backend and Script interfaces of the engine, as well as exceptions and crashes.
 * @author Yoshubs
 */
class ScriptHandler
{
	/**
	 * Shorthand for exposure, specifically public exposure. 
	 * All scripts will be able to access these variables globally.
	 */
	public static var exp:StringMap<Dynamic>;

	public static var parser:Parser = new Parser();

	/**
	 * [Initializes the basis of the Scripting system]
	 */
	public static function Initialize()
	{
		exp = new StringMap<Dynamic>();

		// Classes (Haxe)
		#if sys exp.set("Sys", Sys); #end
		exp.set("Std", Std);
		exp.set("Math", Math);
		exp.set("StringTools", StringTools);

		// Classes (Flixel)
		exp.set("FlxG", FlxG);
		exp.set("FlxSprite", FlxSprite);
		exp.set("FlxMath", FlxMath);
		exp.set("FlxPoint", FlxPoint);
		exp.set("FlxRect", FlxRect);
		exp.set("FlxTween", FlxTween);
		exp.set("FlxTimer", FlxTimer);
		exp.set("FlxEase", FlxEase);
		exp.set("FlxColor", Colors);

		// Classes (Vanilla)
		exp.set('Paths', Paths);
		exp.set("Conductor", Conductor);

		// Classes (Engine)
		exp.set('Cache', Cache);

		/*
			exp.set("Events", Events);
			exp.set("Character", Character);
			exp.set("Boyfriend", Boyfriend);
			exp.set("HealthIcon", HealthIcon);
			exp.set("PlayState", PlayState);
			exp.set("SaveData", SaveData); */

		// Classes (Forever)
		parser.allowTypes = true;
		parser.allowJSON = true;
	}

	public static function loadModule(path:String, ?extraParams:StringMap<Dynamic>):ForeverModule
	{
		trace('Loading module $path');
		var modulePath:String = Paths.module(path);
		return new ForeverModule(parser.parseString(Paths.text(modulePath), modulePath), extraParams);
	}
}

/**
 * The basic module class, for handling externalized scripts individually
 */
class ForeverModule
{
	public var interp:Interp;

	// Lifetime
	public var active:Bool = true;

	public function new(contents:Expr, ?extraParams:StringMap<Dynamic>)
	{
		interp = new Interp();

		// Variable functionality
		for (i in ScriptHandler.exp.keys())
			interp.variables.set(i, ScriptHandler.exp.get(i));

		// Local Variable functionality
		if (extraParams != null)
		{
			for (i in extraParams.keys())
				interp.variables.set(i, extraParams.get(i));
		}

		interp.execute(contents);
	}

	/**
	 * [Sets the module as inactive, and disposing the interp]
	 */
	public function dispose()
	{
		active = false;
		interp = null;
	}

	/**
	 * [Returns a field from the module]
	 * @param field The field name you want to get
	 * @return Dynamic
	 */
	public function get(field:String):Dynamic
		return interp.variables.get(field);

	/**
	 * [Sets a field within the module to a new value]
	 * @param field The field name you want to modify
	 * @param value The new value
	 */
	public function set(field:String, value:Dynamic)
		interp.variables.set(field, value);

	/**
	 * [Checks the existence of a value or exposure within the module]
	 * @param field 
	 * @return Bool
	 */
	public function exists(field:String):Bool
		return interp.variables.exists(field);
}
