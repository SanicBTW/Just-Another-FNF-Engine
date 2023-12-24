package backend.scripting;

import backend.Conductor;
import backend.input.*;
import backend.io.Path;
import base.sprites.*;
import base.sprites.SBar.SBarFillAxis;
import flixel.*;
import flixel.math.*;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.ui.FlxBar;
import flixel.util.*;
import funkin.*;
import funkin.notes.*;
import funkin.substates.GameOverSubstate;
import haxe.ds.StringMap;
import hscript.*;
import hscript.Expr.Error;
import openfl.utils.Assets;

using StringTools;

// Idea: scan for scripts on a dedicated folder and load them globally for extra functionality

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
	public static var exp:StringMap<Dynamic> = [
		// Haxe
		"toString" => Std.string,
		"toInt" => Std.parseInt,
		"toInt32" => Std.int,
		"toFloat" => Std.parseFloat,
		#if sys "Sys" => Sys, #end
		"Date" => Date,
		"Lambda" => Lambda,
		"Math" => Math,
		"Std" => Std,
		"StringTools" => StringTools,
		// Flixel
		"FlxG" => FlxG,
		"FlxSprite" => FlxSprite,
		"FlxMath" => FlxMath,
		"FlxPoint" => FlxPoint,
		"FlxRect" => FlxRect,
		"FlxTween" => FlxTween,
		"FlxTimer" => FlxTimer,
		"FlxEase" => FlxEase,
		"FlxColor" => {
			TRANSPARENT: flixel.util.FlxColor.TRANSPARENT,
			WHITE: flixel.util.FlxColor.WHITE,
			GRAY: flixel.util.FlxColor.GRAY,
			BLACK: flixel.util.FlxColor.BLACK,
			GREEN: flixel.util.FlxColor.GREEN,
			LIME: flixel.util.FlxColor.LIME,
			YELLOW: flixel.util.FlxColor.YELLOW,
			ORANGE: flixel.util.FlxColor.ORANGE,
			RED: flixel.util.FlxColor.RED,
			PURPLE: flixel.util.FlxColor.PURPLE,
			BLUE: flixel.util.FlxColor.BLUE,
			BROWN: flixel.util.FlxColor.BROWN,
			PINK: flixel.util.FlxColor.PINK,
			MAGENTA: flixel.util.FlxColor.MAGENTA,
			CYAN: flixel.util.FlxColor.CYAN
		},
		'FlxBar' => FlxBar,
		'FlxBarFillDirection' => FlxBarFillDirection,
		'FlxText' => FlxText,
		'FlxTextBorderStyle' => FlxTextBorderStyle,
		'FlxSound' => FlxSound,
		'FlxAxes' => FlxAxes,
		// Engine / Forever
		'Settings' => Settings,
		'VPaths' => Paths, // Vanilla Paths , basically access the whole engine Paths
		"Conductor" => Conductor,
		"Character" => Character,
		'Cache' => Cache,
		'Timings' => Timings,
		'Note' => Note,
		'StrumLine' => StrumLine,
		'GameOverSubstate' => GameOverSubstate,
		'parseCharType' => SongTools.parseCharType, // gotta make it a global script soon
		'AttachedSprite' => AttachedSprite,
		'OffsettedSprite' => OffsettedSprite,
		'DepthSprite' => DepthSprite,
		'SBar' => SBar, // Sanco Bar, my own FlxBar implementation
		'SBarFillAxis' => SBarFillAxis,
		"StateBG" => StateBG, // Used for fallbacks on Quaver
		"Controls" => Controls, // In case is needed to add some custom bind (Once I finish the code for rebinding and Funkergarten I will work on custom binds)
		"Controller" => Controller, // Access to the Controller schema and more
		"GamepadButton" => {
			A: lime.ui.GamepadButton.A,
			B: lime.ui.GamepadButton.B,
			X: lime.ui.GamepadButton.X,
			Y: lime.ui.GamepadButton.Y,
			BACK: lime.ui.GamepadButton.BACK,
			GUIDE: lime.ui.GamepadButton.GUIDE,
			START: lime.ui.GamepadButton.START,
			LEFT_STICK: lime.ui.GamepadButton.LEFT_STICK,
			RIGHT_STICK: lime.ui.GamepadButton.RIGHT_STICK,
			LEFT_SHOULDER: lime.ui.GamepadButton.LEFT_SHOULDER,
			RIGHT_SHOULDER: lime.ui.GamepadButton.RIGHT_SHOULDER,
			DPAD_UP: lime.ui.GamepadButton.DPAD_UP,
			DPAD_DOWN: lime.ui.GamepadButton.DPAD_DOWN,
			DPAD_LEFT: lime.ui.GamepadButton.DPAD_LEFT,
			DPAD_RIGHT: lime.ui.GamepadButton.DPAD_RIGHT,
		}, // Dependency
		"Keyboard" => Keyboard, // Access to the Keyboard stuff
	];

	private static var parser:Parser = new Parser();

	/**
	 * [Initializes the basis of the Scripting system]
	 */
	public static function Initialize()
	{
		#if macro
		parser.preprocesorValues = getDefines();
		#end
		parser.allowTypes = true;
		parser.allowJSON = true;
		parser.allowMetadata = true;
	}

	#if macro
	private static macro function getDefines():haxe.macro.Expr
	{
		return macro $v{haxe.macro.Context.getDefines()};
	}
	#end

	// there has to be a better way for sure

	/**
	 * [Loads a Forever Module]
	 * @param file The file name
	 * @param assetFolder The folder where the file is located (Loaded module will be isolated to that path)
	 * @param extraParams Extra variables you want to pass to the module (Optional)
	 * @param fallback The file name that will be used in case it fails to get the target (Optional)
	 * @return ForeverModule
	 */
	public static function loadModule(file:String, ?assetFolder:String, ?extraParams:StringMap<Dynamic>, ?fallback:String):ForeverModule
	{
		#if FS_ACCESS
		var folder:IO.AssetFolder = cast assetFolder.split("/")[0];
		#end

		// Remove the extension as we will manually add it (and to avoid errors)
		// HTML5 sucks tbh lol
		var rawFile:String = Path.withoutExtension(#if html5 Std.string(file) #else file #end);
		var rawFallback:Null<String> = null;
		if (fallback != null)
			rawFallback = Path.withoutExtension(#if html5 Std.string(fallback) #else fallback #end);

		// declare it beforehand for target conditionals
		var modulePath:String = "";

		// Better path parsing? and now prioritizes filesystem, now it shouldnt try to check for fallbacks on filesystem since the fallback will be always default or some shit
		// fuck now the defaults are being overriden too, fuck it
		#if FS_ACCESS
		modulePath = Path.join(IO.getFolderPath(folder), '${assetFolder.replace(folder, "")}/$rawFile.hxs');
		if (IO.exists(modulePath))
			return parse(modulePath, folder, extraParams);
		#end

		modulePath = Paths.file('$assetFolder/$rawFile.hxs');
		if (Assets.exists(modulePath, TEXT))
			return parse(modulePath, assetFolder, extraParams);

		if (fallback == null)
			throw('Failed to load module $rawFile');

		// Ez replace - wont check on filesystem
		assetFolder = assetFolder.replace(rawFile, rawFallback);
		modulePath = Paths.file('$assetFolder/$rawFallback.hxs');

		if (Assets.exists(modulePath, TEXT))
			return parse(modulePath, assetFolder, extraParams);

		// what does run before, the throw or the return, we will never know
		throw('Failed to load module $rawFile and its fallback $rawFallback');
	}

	/**
	 * [Undocumented]
	 */
	private static function parse(modulePath:String, ?assetFolder:String, ?extraParams:StringMap<Dynamic>):ForeverModule
	{
		var expr:Expr = null;
		var module:ForeverModule = null;

		try
		{
			var parseEnd:String = #if FS_ACCESS Cache.fromFS(modulePath) ? IO.getContent(modulePath) : Paths.text(modulePath) #else Paths.text(modulePath) #end;
			var parseFolder:String = Cache.fromFS(modulePath) ? Path.join(IO.getFolderPath(cast assetFolder),
				modulePath.substring(modulePath.lastIndexOf("/"), modulePath.lastIndexOf("."))) : assetFolder;

			expr = parser.parseString(parseEnd, modulePath);
			module = new ForeverModule(expr, parseFolder, extraParams);

			@:privateAccess
			flixel.FlxG.state.modules.push(module);
		}
		catch (ex:Error)
		{
			trace('HScript parsing exception, caused at line ${ex.line} on ${ex.origin} (${ex.e})');
		}

		return module;
	}
}
