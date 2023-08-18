package backend;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.*;
import haxe.io.Bytes;

// Contains methods to parse allowed encryptions serialize/unserialize them with the haxe serializer
// Originally from SqliteKeyValue but having to copy the code 2 times for each platform is kind of dumb so I'm moving it to a file
// All of the values must be run through Serializer/Unserializer to work properly
class Crypto
{
	public static function encode(value:Any):String
	{
		var serialized:String = Serializer.run(value);

		switch (Settings.saveEncryption)
		{
			default:
				return serialized;

			case NONE:
				return serialized;

			case BASE64:
				{
					var valueBytes:Bytes = Bytes.ofString(serialized);
					return Base64.encode(valueBytes);
				}
		}
	}

	public static function decode(rawValue:Any):Any
	{
		var decrypted:String = switch (Settings.saveEncryption)
		{
			default:
				return rawValue;

			case NONE:
				return rawValue;

			case BASE64:
				{
					var rawBytes:Bytes = Base64.decode(rawValue);
					return rawBytes.toString();
				}
		}

		return Unserializer.run(decrypted);
	}
}
