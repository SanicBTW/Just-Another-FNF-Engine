package states.online.schema;

import io.colyseus.serializer.schema.Schema;
import io.colyseus.serializer.schema.types.*;

// I don't believe I will be using this
class VersusRoom extends Schema
{
	@:type("string")
	public var songName:String = "";

	@:type("string")
	public var opponentName:String = "";

	@:type("string")
	public var playerName:String = "";
}
