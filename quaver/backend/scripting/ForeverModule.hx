package backend.scripting;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.ds.StringMap;
import hscript.*;

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
		var modulePaths:IsolatedPaths = new IsolatedPaths(assetFolder);
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
