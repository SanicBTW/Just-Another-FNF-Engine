package database;

import haxe.ds.DynamicMap;

using tink.CoreApi;

interface IDatabase<T>
{
	private var params:DBInitParams;
	private var connected:Bool;

	public function connect():Promise<T>;
	public function set(table:DatabaseTable, key:String, value:Any):Promise<Bool>;
	public function remove(table:DatabaseTable, key:String):Promise<Bool>;
	public function get(table:DatabaseTable, key:String):Promise<Any>;
	public function entries(table:DatabaseTable):Promise<DynamicMap<String, Any>>;
	public function destroy():Void;

	private function log(v:String):Void;
	private function preprocessor(v:Any, isGet:Bool):Any;
}

typedef DBInitParams =
{
	var path:String;
	var tables:Array<DatabaseTable>;
	var ?version:Int;
}

enum abstract DatabaseTable(String) to String from String
{
	var DEFAULT = "KeyValue";
	var SETTINGS = "Settings";
	var BINDS = "Binds";
	var HIGHSCORES = "HighScores";
	var QUAVER_DB = "QuaverDB";
}
