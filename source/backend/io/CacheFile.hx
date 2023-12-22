package backend.io;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.Base64;
import haxe.ds.DynamicMap;
import haxe.io.Bytes;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if html5
import js.Browser;
import js.html.Storage;
#end

// Based off https://github.com/SanicBTW/Sanco-Bot-Rewritten/blob/bcc2c638d4f0bb7fa912620113c749d9015e7b32/src/OptFHandler.ts
// This class is meant for persistent data across instances
// Saving for example essential data like paths and existing directories, its just like a settings file but really important
// The value from the entry is passed through Haxe Serializer
class CacheFile
{
	private static final commentReg:EReg = ~/^[;|#].*$/;
	private static final blankReg:EReg = ~/^[ \n\r\t]$/;
	private static final entryReg:EReg = ~/^([^:]+):(.*)$/;

	private static final fileName:String = #if html5 "cache:jafe" #else "cache.jafe" #end;
	private static final template:String = 'savePath:n\nfsAllowed:f\nnetAllowed:f\ndiscrpcAllowed:f\ndiscToken:n\ngavePerms:f\nq_beatmaps:n';

	public static var comments(default, null):Array<String> = [];
	public static var data(default, null):DynamicMap<String, Dynamic> = new DynamicMap<String, Dynamic>();

	#if html5
	private static var lStorage:Storage;
	#end

	// This function will try to create a file on the app directory
	public static function Initialize()
	{
		#if sys
		if (!FileSystem.exists(Sys.getCwd() + fileName))
			File.saveContent(Sys.getCwd() + fileName, encrypt(template));

		var content:String = decrypt(File.getContent(Sys.getCwd() + fileName));
		#end

		#if html5
		lStorage = Browser.getLocalStorage();
		if (lStorage == null)
			throw "Local Storage unsupported or disabled";

		if (lStorage.getItem(fileName) == null)
			lStorage.setItem(fileName, encrypt(template));

		var content:String = decrypt(lStorage.getItem(fileName));
		#end

		for (i in (~/\r\n|\r|\n/g).split(content))
		{
			var i:String = i.trim();

			for (e in i.split(''))
			{
				if (commentReg.match(e) && !blankReg.match(e))
				{
					var l = i.split(e);
					if (l != null && l.length > 1)
					{
						var l1:String = l[0];
						var l2:String = l[1];

						if (l1 != null && l2 != null)
						{
							i = l[0].trim();
							comments.push(formatString(l[1]));
							break;
						}
					}
				}
			}

			if (i.length < 1 || commentReg.match(i) || blankReg.match(i))
			{
				if (commentReg.match(i))
					comments.push(formatString(i));

				continue;
			}
			else if (entryReg.match(i))
			{
				var name:String = entryReg.matched(1).trim();
				var value:Dynamic = Unserializer.run(entryReg.matched(2).trim());

				data[name] = value;
			}
		}
	}

	public static function Save()
	{
		var flush:String = '';
		for (name => value in data)
		{
			flush += '${name}:${Serializer.run(value)}\n';
		}

		#if sys
		File.saveContent(Sys.getCwd() + fileName, encrypt(flush));
		#end

		#if html5
		lStorage.setItem(fileName, encrypt(flush));
		#end
	}

	private static function rot13(data:String):String
	{
		var result:String = '';

		for (i in 0...data.length)
		{
			var char:Int = data.charCodeAt(i);
			if ((char >= 65 && char <= 90) || (char >= 97 && char <= 122))
			{
				var isUpperCase:Bool = (char >= 65 && char <= 90);
				var base:Int = isUpperCase ? 65 : 97;
				result += String.fromCharCode((char - base + 13) % 26 + base);
			}
			else
			{
				result += data.charAt(i);
			}
		}

		return result;
	}

	private static function formatString(s:String):String
	{
		var s:String = new String(s);
		if (s != null && s.length > 1)
			if (blankReg.match(s.substring(0, 1)))
				s = s.substring(1, s.length);
		return s;
	}

	private static function encrypt(data:String):String
		return Base64.encode(Bytes.ofString(rot13(data)));

	private static function decrypt(encrypted:String):String
		return rot13(Base64.decode(encrypted).toString());
}
