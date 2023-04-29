package base.system;

import base.system.SaveFile;
import haxe.Exception;
import haxe.xml.Access;
import openfl.utils.Assets;

// basic stuff here lol
class Language
{
	private static var curLang(get, null):String;

	private static var xmlAccess(get, null):Access;
	private static var langAccess(get, null):Access;

	private static var store:Map<String, String> = [];

	// dunno how i fixed the thing that it wouldnt get the proper language but here it is (i have no idea what does this do)

	@:noCompletion
	private static function get_curLang():String
		return (SaveFile.get("language") != null) ? SaveFile.get("language") : SaveData.language;

	// leaves the xml open on memory to avoid having to load it every once in a while

	@:noCompletion
	private static function get_xmlAccess():Access
		return (xmlAccess == null) ? xmlAccess = new Access(Xml.parse(Assets.getText(Paths.getPath("data/languages.xml"))).firstElement()) : xmlAccess;

	// actual access to the language node

	@:noCompletion
	private static function get_langAccess():Access
	{
		if (langAccess == null || langAccess.att.id != curLang)
		{
			for (lang in xmlAccess.nodes.lang)
			{
				langAccess = (lang.att.id == curLang) ? lang : xmlAccess.node.lang;
			}
		}

		return langAccess;
	}

	// dumb but might be better tbh
	public static function refresh()
	{
		for (entry in langAccess.nodes.entry)
		{
			store.set(entry.att.id, entry.innerData);
		}
	}

	// Gets the string from the current selected language in the settings
	public static function get(id:String):String
	{
		if (store.exists(id))
			return store.get(id);

		throw new Exception('No $id found on $curLang language');
	}
}
