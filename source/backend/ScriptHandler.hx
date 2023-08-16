package backend;

/**
 *  Mix between my [FE:R HTML5 Port](https://github.com/SanicBTW/FNF-Forever-Engine/blob/master/source/base/ScriptHandler.hx),
 *  [HXS Branch on my PE 0.3.2h repo](https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/tree/hxs-forever/source) and
 *  some cancelled Lullaby code
 */
import Paths.Libraries;
import base.Conductor;
import base.sprites.*;
import base.sprites.SBar.SBarFillAxis;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.*;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.ui.FlxBar;
import flixel.util.*;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.*;
import funkin.notes.*;
import funkin.substates.GameOverSubstate;
import haxe.ds.StringMap;
import haxe.io.Path;
import hscript.*;
import hscript.Expr.Error;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

// FlxColor but class
class Colors
{
	public static inline var TRANSPARENT:FlxColor = 0x00000000;
	public static inline var WHITE:FlxColor = 0xFFFFFFFF;
	public static inline var GRAY:FlxColor = 0xFF808080;
	public static inline var BLACK:FlxColor = 0xFF000000;

	public static inline var GREEN:FlxColor = 0xFF008000;
	public static inline var LIME:FlxColor = 0xFF00FF00;
	public static inline var YELLOW:FlxColor = 0xFFFFFF00;
	public static inline var ORANGE:FlxColor = 0xFFFFA500;
	public static inline var RED:FlxColor = 0xFFFF0000;
	public static inline var PURPLE:FlxColor = 0xFF800080;
	public static inline var BLUE:FlxColor = 0xFF0000FF;
	public static inline var BROWN:FlxColor = 0xFF8B4513;
	public static inline var PINK:FlxColor = 0xFFFFC0CB;
	public static inline var MAGENTA:FlxColor = 0xFFFF00FF;
	public static inline var CYAN:FlxColor = 0xFF00FFFF;

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
		return FlxColor.fromRGB(Red, Green, Blue, Alpha);
}

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
	public static var exp:StringMap<Dynamic>;

	private static var parser:Parser = new Parser();

	/**
	 * [Initializes the basis of the Scripting system]
	 */
	public static function Initialize()
	{
		exp = new StringMap<Dynamic>();

		// Classes (Haxe)
		#if sys exp.set("Sys", Sys); #end
		// I Love C# (OMG IT WORKS ON HTML NO WAY OMGGG)
		exp.set('toString', Std.string);
		exp.set('toInt', Std.parseInt);
		exp.set('toInt32', Std.int);
		exp.set('toFloat', Std.parseFloat);
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
		// will change it to my better bar ig
		exp.set('FlxBar', FlxBar);
		exp.set('FlxBarFillDirection', FlxBarFillDirection);
		exp.set('FlxText', FlxText);
		exp.set('FlxSound', FlxSound);

		// Classes (Engine / Forever)
		exp.set('Settings', Settings);
		exp.set('VPaths', Paths); // Vanilla Paths, basically access the whole engine Paths
		exp.set("Conductor", Conductor);
		exp.set("Character", Character);
		exp.set('Cache', Cache);
		exp.set('Timings', Timings);
		exp.set('Note', Note);
		exp.set('StrumLine', StrumLine);
		exp.set('GameOverSubstate', GameOverSubstate);
		exp.set('parseCharType', SongTools.parseCharType); // gotta make it a global script soon
		exp.set('AttachedSprite', AttachedSprite);
		exp.set('OffsettedSprite', OffsettedSprite);
		exp.set('DepthSprite', DepthSprite);
		exp.set('SBar', SBar); // Sanco Bar, my own FlxBar implementation
		exp.set('SBarFillAxis', SBarFillAxis);

		parser.allowTypes = true;
		parser.allowJSON = true;
	}

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
		var expr:Expr = null;
		var module:ForeverModule = null;

		// Prefer FS Content than Asset Content
		#if FS_ACCESS
		var parseContent:Null<String> = null;
		var folder:IO.AssetFolder = cast assetFolder.split("/")[0];
		#end

		// Remove the extension as we will manually add it (and to avoid errors)
		file = Path.withoutExtension(file);
		if (fallback != null)
			fallback = Path.withoutExtension(fallback);

		// Goofy path parsing lol
		var modulePath:String = Paths.file('$assetFolder/$file.hxs');

		function parse()
		{
			try
			{
				var parseEnd:String = #if FS_ACCESS parseContent != null ? parseContent : Paths.text(modulePath) #else Paths.text(modulePath) #end;
				var parseFolder:String = #if FS_ACCESS parseContent != null ? Path.join([IO.getFolderPath(folder), file]) : assetFolder #else assetFolder #end;

				expr = parser.parseString(parseEnd, modulePath);
				module = new ForeverModule(expr, parseFolder, extraParams);

				@:privateAccess
				flixel.FlxG.state.modules.push(module);
			}
			catch (ex:Error)
			{
				trace('HScript parsing exception, caused at line ${ex.line} on ${ex.origin} (${ex.e})');
			}
		}

		if (!Assets.exists(modulePath, TEXT))
		{
			#if FS_ACCESS
			modulePath = Path.join([IO.getFolderPath(folder), '${assetFolder.replace(folder, "")}/$file.hxs']);
			if (IO.exists(modulePath))
			{
				parseContent = sys.io.File.getContent(modulePath);
				parse();
				return module;
			}
			#end

			if (fallback == null)
				throw('Failed to load module $file');

			// Ez replace
			assetFolder = assetFolder.replace(file, fallback);
			modulePath = Paths.file('$assetFolder/$fallback.hxs');

			if (!Assets.exists(modulePath, TEXT))
			{
				#if FS_ACCESS
				modulePath = Path.join([IO.getFolderPath(folder), '${assetFolder.replace(folder, "")}/$fallback.hxs']);
				if (IO.exists(modulePath))
				{
					parseContent = sys.io.File.getContent(modulePath);
					parse();
					return module;
				}
				else
				#end
				throw('Failed to load module $file and its fallback $fallback');
			}
		}

		parse();

		return module;
	}
}

/**
 * The basic module class, for handling externalized scripts individually
 */
class ForeverModule implements IFlxDestroyable
{
	public var interp:Interp;

	// Lifetime
	public var active:Bool = true;

	public function new(contents:Expr, ?assetFolder:String, ?extraParams:StringMap<Dynamic>)
	{
		interp = new Interp();

		// Variable functionality
		for (i in ScriptHandler.exp.keys())
			set(i, ScriptHandler.exp.get(i));

		// Local Variable functionality
		if (extraParams != null)
		{
			for (i in extraParams.keys())
				set(i, extraParams.get(i));
		}

		// Define the current path (used within the script itself)
		var modulePaths:ModulePaths = new ModulePaths(assetFolder);
		set('Paths', modulePaths);

		interp.execute(contents);
	}

	/**
	 * [Sets the module as inactive and executes onDestroy function]
	 */
	public function destroy()
	{
		if (exists('onDestroy'))
			get('onDestroy')();

		active = false;
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

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/Paths.hx#L17
// Improved thanks to myself actually working on it outside of the classic Static Paths class
// See IsolatedPaths.hx from pending folder
class ModulePaths
{
	private var localPath:String;

	public function new(localPath:String)
	{
		this.localPath = localPath;
	}

	public function getPath(file:String):String
	{
		#if FS_ACCESS
		if (Cache.fromFS(localPath))
		{
			var path:String = Path.join([localPath, file]);
			if (!sys.FileSystem.exists(path))
				throw('Failed to get $file on $localPath');

			return path;
		}
		else
		#end
		{
			@:privateAccess
			var libPath:String = '${Paths._library}:assets/${Paths._library}/$localPath/$file';
			if (Assets.exists(libPath))
				return libPath;

			return '${Libraries.DEFAULT}:assets/${Libraries.DEFAULT}/$localPath/$file';
		}
	}

	public inline function sound(key:String):Sound
		return Cache.getSound(getPath('sounds/$key.ogg'));

	public inline function music(key:String):Sound
		return Cache.getSound(getPath('music/$key.ogg'));

	public inline function image(key:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png'));

	public inline function getSparrowAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$key.png')), Cache.getText(getPath('$key.xml')));
}
