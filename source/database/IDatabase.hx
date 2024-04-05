package database;

import backend.SPromise;
import haxe.ds.DynamicMap;

/*
	This will change once:
		- HxWebView is fully working (I guess??)
		- More backends (Online?)
		- Etc
 */
typedef DBBackend = #if sys SqliteImpl #else IndexedDBImpl #end;

interface IDatabase<T>
{
	private var params:DBInitParams;
	public var shouldPreprocess:Bool; // This only affects HTML5 since it doesn't need to serialize values to save them properly (strings n shit yknow) I have to properly make a flag for it

	public function connect():SPromise<T>;
	public function set(table:DatabaseTable, key:String, value:Any):SPromise<Bool>;
	public function remove(table:DatabaseTable, key:String):SPromise<Bool>;
	public function get(table:DatabaseTable, key:String):SPromise<Any>;
	public function entries(table:DatabaseTable):SPromise<DynamicMap<String, Any>>;
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
	var VFS = "VirtualFilesystem";
}
